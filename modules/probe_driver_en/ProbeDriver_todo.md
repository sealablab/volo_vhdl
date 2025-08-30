# ProbeDriver todo

## TODO: Review Division of Responsibilities (2025-01-28)

### Task: Clarify Interface Boundaries Between CustomWrapper and probe_driver_interface

**Priority**: High  
**Due**: Tomorrow (2025-01-28)  
**Status**: Pending  

#### Background
We need to review and clarify the division of responsibilities between:
- `CustomWrapper_example.vhd` - Example of vendor's CustomWrapper implementation
- `probe_driver_interface.vhd` - Our top-level interface module

#### Key Questions to Address
1. **Register Handling**: Who should handle register auto-clearing (e.g., soft trigger auto-clear)?
2. **Control Logic**: What control signals should be exposed vs. handled internally?
3. **Data Flow**: How should data flow between CustomWrapper and probe_driver_interface?
4. **Status Reporting**: What status information should be exposed to the platform?

#### Current Issues Identified
- Soft trigger auto-clear logic is commented out in probe_driver_interface
- Some control signals (ctrl_arm, ctrl_fire) are hardcoded to '0'
- Register layout could be optimized for better platform integration

#### Files to Review
- `modules/probe_driver/top/CustomWrapper_example.vhd`
- `modules/probe_driver/top/probe_driver_interface.vhd`
- `modules/probe_driver/reqs/ProbeDriver-requirements.md`

#### Expected Outcome
- Clear separation of responsibilities
- Optimized register layout
- Proper control signal handling
- Improved platform integration

---
*Created: 2025-01-27*  
*Last Updated: 2025-01-27*
