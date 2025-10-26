
# VOLO-DS1120-PD
This document describes a VOLO-APP. Please:
1) read @VOLO_APP_FRESH_CONTEXT
2) 

The DS1120A Probe features two analog inputs - 'digital_gitch' and 'pulse_amplitude' and one analog output 'probe_monitor'

## DS1120A inputs
## 'digital_glitch':
This is the 'trigger-in' for the probe itself. It has a fixed threshold value (`2v4`). 


## `pulse_amplitude` 
This controls the intensity of the output EMFI pulse. The probe is designed to respond linearly over a range of `0v5` to `3v3`

## DS1120A outputs
## `probe_monitor`
The probe features a built-in current monitor that we can use to observe how much power is flowinging throw the probe to the output tip. 

Curiously, the current monitor is wired such that the more power consumed the __more negative__ the monitor port results.  

## Implementation
This app **MUST** make use of the following shared vhdl modules
- volo_voltage_pkg.vhd
- volo_voltage_threshold_trigger_core.vhd
- fsm_observer.vhd
It should utilize fsm_example_core.vhd as an example of how to implement an **observable FSM** 

This is critically important because I think we can actually __use__ the @fsm_observer.vhd module to implement most of the functionality.
## Workflow
The volo_app should be designed to be a 'one-shot' module. 
That is to say that it should __only__ fire once per trigger. 

In the following document we will use the term 're-arm' because it is common parlance in the SCA/FI world. Conceptually 're-arming' is and should be equivalent to 're-setting' the FSM implementing the module.


## VOLO inputs:

the volo module will have two 16-bit unsigned inputs. 'TriggerInput' and 'MonitorInput'. 

### TriggerInput
Our module will receive an external input that tells it when it is time to go. The threshold of this input should be exposed in a volo-app register.

### MonitorInput
Our module should be configured to observe feedback from the probe. For now we should: 
- sample the MonitorInput __after__ we trigger the probe. Eventually we will perform some simple calculations on it to ascertain if the probe fired as well as its peak observed intensity - but the 'observation' and characterization of how and if the probe fired may be a future enhancement. 

  At present we do not want to get caught up in the details of the MonitorInput functionality. i.e.
  - No MonitorInput Testbenches (for now). 


## VOLO Outputs

### TriggerOut
**TriggerOut** is a 16-bit signed value. When the FSM enters the 'FIRING' state is shall be set to a DC value. This value will be fed in through a VOLO-register. 

**TriggerOut** Should be 0v0 at all times EXCEPT when firing the probe.

### IntensityOut
**IntensityOut** Should be 0v0 at all times EXCEPT when firing the probe. Intensity out should **NEVER** exceed`3v0` regardless of user input.


## VOLO-DS1120PD STATES
The general flow of the FSM shall be
READY->ARMED->FIRING->COOLING->DONE

| STATE    | DESCR                                            |
| -------- | ------------------------------------------------ |
| READY    | The FSM should start in the READY state          |
| ARMED    | the FSM is 'armed' and will respond to `trig_in` |
| FIRING   | TriggerOut and Intensity Out both go high        |
| COOLING  | Mandatory cooldown phase.                        |
| DONE     | Probe was fired as expected                      |
| TIMEDOUT | `delay_cnt` expires.                             |

In addition there are two 'error' states

| STATE     | DESCR                                                                                                              |
| --------- | ------------------------------------------------------------------------------------------------------------------ |
| TIMEDOUT  | more than `delay_cnt` clks passed ARMED state.                                                                     |
| HARDFAULT | canonical ERROR state. __cannot be entered__ (at present). This should still be implemented for future use however |


## Safety parameters
In order to prevent the hardware from being fired continuously the FSM shall enforce the following hard limits on each state.


| STATE   | TIMEOUT             |
| ------- | ------------------- |
| READY   | N/A                 |
| ARMED   | `delay_cnt`         |
| FIRING  | MAX(firing_cnt, 32) |
| COOLING | MIN(8, cooling_cnt) |
| DONE    | N/A                 |
|         |                     |

## VOLO Registers
I propose the following 'friendly' register names and uses


| name        | type         | descr                                               |
| ----------- | ------------ | --------------------------------------------------- |
| armed_bit   | BUTTON       | single bit                                          |
| force_fire  | BUTTON       | single bit                                          |
| delay_cnt   | counter_8bit | clk cycles to wait before entering the FIRING state |
| firing_cnt  | counter_8bit | clk cycles spent in firing state                    |
| cooling_cnt | counter_8bit | clk cycles spent in cooling state                   |

The following registers are used to set the  threshold levels. 

| name              | type          | descr                                                                                           |
| ----------------- | ------------- | ----------------------------------------------------------------------------------------------- |
| trig_in_thresh    | 16-bit signed | used as input to the `volo_voltage_threshold_trigger_core`                                      |
| monitor_in_thresh | 16-bit signed | if `MonitorInput` falls below this value we will treat it as if the probe was observed firing.  |

## Expected workflow:
## S1) bitstream is loaded 
The user will load the bitstream into a moku slot. At this point the bitstream will appear 'stuck' - this is expected. It has not received the `MCC_READY` signals etc.

## S2) VOLO-LOADER
The user will run a python script (`volo-loader`). This script
1) walks the bitstream through the process of filling up the 4K BRAM buffer
2) hands off control to 'volo_main'

> [!NOTE] the current implementation should **NOT** make use of this 4KB BRAM buffer. This will be reserved for future enhancements. We **will** need to walk through the state machine process of loading it however, as this is a mandatory part of a VOLO applications lifecycle.

## S3) Control Regs get set
At this point an **external python script** will be responsible for:
1) calling the mcc set_regs API as appropriate to  initialize our app registers (CR20-CR30). The volo_main app should latch these appropriately.


> [!NOTE]  It will be common / expected practice for the external python script to 'load' the current configuration registers but __not__ set the 'ARMED' bit until much later. 
## S4 User ARMS the module
2) the user 'ARMS' the module by setting the 'armed' bit
At this point the FSM should engage.

## `force_fire` 
For debugging and testing purposes the volo-ds1120-pd module will also expose a 'force-fire' button to the user.  When `force_fire` is set the module should proceed as if `trig_in_thresh` was observed.
## Nice to have features

## Spurious `trig_in` counter
- It would be handy to have a counter in the 'volo-top' that tracks if our module receives and 'spurious' InputTriggers while the state machine is already engaged. These signals are indicative of a mis-behaving DUT or target.

