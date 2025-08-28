# VHDL coding template

Provided is a blank template for creating HDL files using the Moku Cloud Compile.

## Entity Ports

| Port      | In/Out | Type             | Range       |
| --------- | ------ | ---------------- | ----------- |
| Clk       | in     | std_logic        | -           |
| Reset     | in     | std_logic        | -           |
|           |        |                  |             |
| InputA    | in     | signed           | 15 downto 0 |
| InputB    | in     | signed           | 15 downto 0 |
| InputC    | in     | signed           | 15 downto 0 |
| OutputA   | out    | signed           | 15 downto 0 |
| OutputB   | out    | signed           | 15 downto 0 |
| OutputC   | out    | signed           | 15 downto 0 |
| Control0  | in     | std_logic_vector | 31 downto 0 |
| Control1  | in     | std_logic_vector | 31 downto 0 |
| ...       | ...    | ...              | ...         |
| Control15 | in     | std_logic_vector | 31 downto 0 |
|           |        |                  |             |
