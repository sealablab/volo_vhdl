

Claude, 
I would like you to help me implement a 'new' EMFI-sequencer Instrument'. This is going to be our first "real" Instrument Instrument. We are also going to use this an an opportunity to test out a concept I am calling 'Application' level registers:


## Application registers
I want to write down on disk an authoritative .yml or .json file that contains 'Application' level registers.  This file will be responsible for defining 'Application' level registers that will ultimately be mapped to the **Control Registers** (CR0-CR32) provided my the moku custom wrapper and that can 



--
  Based on your principle: "Top.vhd = Instrument (promote), No Top.vhd = Utility (flatten)"

  Current State Analysis

  Modules with Top.vhd (Instruments - should be promoted):
  - modules/instruments/ - EMFI-Seq, PulseStar, SimpleWaveGen (3 items)
  - modules/experimental/ - buffer_waveform_gen, inspectable_buffer_loader, bram_test_minimal (3 items)
  - modules/shared/volo_pinata_tx/ - Oddball (1 item)

  Utilities (no Top.vhd):
  - modules/shared/volo_common/ - 13 core modules, 5 packages, 1 observer (good flat pattern)
  - modules/shared/volo_* - 8 hierarchical directories (mostly 1 file each + empty tb/)
  - modules/untested/ - 5 modules without CocotB tests

  Old artifacts to delete:
  - All tb/ directories (deprecated GHDL testbenches)
  - modules/work/ (build artifacts)
  - Stray files in modules/ root (emfi_seq, volo_clk_divider binaries)

  ---
  Proposed New Structure

  volo_vhdl/
  ├── instruments/                    (PROMOTED from modules/instruments/)
  │   ├── EMFI-Seq/
  │   ├── PulseStar/
  │   └── SimpleWaveGen/
  │
  ├── experimental/                   (PROMOTED from modules/experimental/)
  │   ├── buffer_waveform_gen/
  │   ├── inspectable_buffer_loader/
  │   └── bram_test_minimal/
  │
  ├── modules/
  │   ├── shared/                     (FLATTENED utilities)
  │   │   ├── core/                   (Digital primitives)
  │   │   │   ├── volo_clk_divider.vhd
  │   │   │   ├── volo_synchronizer.vhd
  │   │   │   ├── volo_uart_tx_core.vhd
  │   │   │   ├── volo_barrel_shifter_core.vhd  ← from hierarchical dirs
  │   │   │   └── ... (all core modules consolidated)
  │   │   │
  │   │   ├── packages/               (Type definitions, utilities)
  │   │   │   ├── volo_voltage_pkg.vhd
  │   │   │   ├── volo_uart_pkg.vhd
  │   │   │   └── ...
  │   │   │
  │   │   └── observer/               (Monitoring/debug)
  │   │       └── fsm_observer.vhd
  │   │
  │   ├── examples/                   (Keep as-is - educational)
  │   │   └── fsm_example/
  │   │
  │   ├── untested/                   (Keep as-is - modules awaiting tests)
  │   │
  │   └── oddball/                    (NEW - special cases)
  │       └── volo_pinata_tx/
  │
  └── tests/                          (CocotB tests - already correct location)

  ---