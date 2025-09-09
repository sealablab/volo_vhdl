# Reset and Enable Procedure

This document defines the expected behavior of **reset**, **clock enable (`clk_en`)**, and **functional enable (`enable`)** signals in our VHDL modules.  
Definitions are from the **DUT (inside module) perspective**.

---

## Signal Priorities

1. **Reset (`reset` or `reset_n`)**  
   - Highest priority.  
   - Forces DUT into a safe, known state regardless of other signals.  
   - Typically asynchronous, active-low (`reset_n`).

2. **Clock Enable (`clk_en`)**  
   - Second priority.  
   - When `clk_en='0'`, sequential logic holds state (no updates on clock edge).  
   - When `clk_en='1'`, logic can update if not in reset.

3. **Functional Enable (`enable`)**  
   - Lowest priority.  
   - When `enable='0'`, the DUT is idle/holding even though clock is active.  
   - When `enable='1'`, the DUT performs normal operation.

---

## Truth Table

| Reset | clk_en | enable | DUT Behavior                          |
|-------|--------|--------|----------------------------------------|
| 1     | X      | X      | **Reset dominates** → safe defaults    |
| 0     | 0      | X      | **Clock frozen** → hold state, no updates |
| 0     | 1      | 0      | **Idle/hold** → state stable, outputs parked |
| 0     | 1      | 1      | **Normal operation** → advance state, process data |

---

## Summary

- **Reset** always dominates.  
- **Clock Enable** freezes state when low.  
- **Enable** gates functional work but does not freeze sequential logic.  
- Students should follow this hierarchy in all modules for consistency.