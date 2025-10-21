# TPD-MED

PREV: [[volo_vhdl/modules/TPD/TPD-TOP|TPD-TOP]]

NEXT: [[volo_vhdl/modules/TPD/emfi-fsm|emfi-fsm]]


Now, lets create a 'medium' level module that instantiates `emfi-fsm`

## TPD_MED input parameters 
the **tpd-med** module will receive a copy of the following parmeters to pass in to the [[volo_vhdl/modules/TPD/emfi-fsm|emfi-fsm]] module.
- delay_cnt_in
- firing_cnt_in
- cooldown_cnt_in

TPD_MED will also accept the following additional inputs
- trig_out_level signed(15 downto 0)
- intens_out_level signed (15 downto 0)
- state_reg_out std_logic_vector(7 downto 0)

## MED outputs
### trigger_out             : out signed(15 downto 0);
set to `trig_out_lvl` during FIRING, else 0x00
### intensity_out           : out signed(15 downto 0);
set to `intens_out_lvl` during FIRING, else 0x00
### state_reg_out               : out signed(7 downto 0);
The `state_reg_out` should map the following (internal) state bits to the outside. Note the stickyness setting.

| bit | name     | high-when | sticky? |
| --- | -------- | --------- | ------- |
| 0   | READY    |           | Y       |
| 1   | DELAY    |           | Y       |
| 2   | FIRING   |           | Y       |
| 3   | COOLING  |           | N       |
| 4   | DONE     |           | Y       |
| 5   | RESERVED |           |         |
| 6   | RESERVED |           |         |
| 7   | RESERVED |           |         |
|     |          |           |         |
	