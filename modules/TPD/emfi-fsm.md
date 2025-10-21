
# emfi-fsm
The **emfi-fsm* module implements a simple state machine (RESET->READY->DELAY->FIRING->COOLING->DONE).

##  emfi-fsm  states:
The emfi-fsm  module state machine consists of the following   states
- RESET
- READY
- DELAY
- FIRING
- COOLING
- DONE
- HARD_FAULT

## emfi-fsm control inputs
- clk
- rst
- trig_in 

## emfi-fsm input parameters 
- delay_cnt_in
- firing_cnt_in
- cooldown_cnt_in

On reset these inputs should be assigned to internal variables.

## emfi-fsm functional requirements

### emfi-fsm Reset handler 
On reset the `delay_cnt_in` `firing_cnt_in` and `cooldown_cnt_in` variables should all be copied to internal signals. This prevents the outside world from changing them on us.

Once  reset is complete the module will enter the READY state.

### State transitions

#### S1 READY->WAITING
While in the  READY state the module will transition to the DELAY state when the `trig_in` input goes high. 

#### S2 WAITING-> FIRING
While in firing the internal signal `delay_cnt` will be decremented. Once it hits zero we will transition to the FIRING state

#### S3 FIRING -> COOLING
While in the `FIRING` state the `firing_cnt` will be decremented. Once it hits zero we will transition to the `COOLING` state

#### S4: COOLING -> DONE
While in the `COOLING` state the `cooling_cnt` will be decremented. Once it hits zero we will transition to the `DONE` state

#### S5: DONE
The only way to transition out of `DONE` is to reset the module.

#### S6: HARD_FAULT
The `HARD_FAULT` state is used to indicate a failure state. 
Under the current implementation this state is unreachable - but will be used in later iterations.




# emfi-fsm testbench
Create a simple coco-tb based test bench that:

## emfi-fsm-test-002
Reset(delay_cnt_in=2, firing_cnt_in=2,cooldown_cnt_in=2)
After reset observe that the state_out hits all of the expected states. When the module reaches the 'DONE' state the test has passed




# See Also

## [[TPD-TOP]]
