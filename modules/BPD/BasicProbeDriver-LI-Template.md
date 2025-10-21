

## Basic Probe Driver (BPD) for Riscure Fault Injection Probes

PLATFORM:  Moku: Go (2 slots, 2 analog inputs, 2 analog outputs)

OVERVIEW:

Example: Design a controller to drive Riscure fault injection probes (DS1120A EM-FI and DS1110A Laser-FI) from a Moku:Go instrument. The BPD receives trigger signals from a Device Under Test (DUT) and generates control signals to fire the probe with configurable intensity and timing.

## Timing
For the sake of this document the only unit of time shall be a `clk` - which runs at the default Moku Go native clk speed of `32ns`.  


## Overview
The en
## F
FUNCTIONAL REQUIREMENTS:

For example:

- ﻿﻿Receive external trigger input from DUT
- ﻿﻿Generate digital glitch output to fire probe on trigger
- ﻿﻿Generate analog pulse amplitude signal to control probe intensity (0-100%)
- ﻿﻿Monitor probe current feedback signal
- ﻿﻿Support software-triggered firing via

control register

- ﻿﻿Implement configurable pulse duration and cooldown periods
- ﻿﻿Include intensity lookup table for probe calibration

CONTROL INTERFACE:

For example:

- Control register with fields for:

- ﻿﻿Global enable/disable
- ﻿﻿Clock divider for timing control
- ﻿﻿Software trigger bit
- ﻿﻿Intensity index (0-100%)
- ﻿﻿Pulse duration (in clock cycles)
- ﻿﻿Cooldown period (in clock cycles)



