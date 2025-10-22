
# MokuVoltagePkg
Claude,

I have experimentally determined that the moku DAC has the following outputs

``` vhdl
    signal out_a : signed(15 downto 0);
    OutputA <= out_a
```

| out_a  | observed voltage |
| ------ | ---------------- |
| 0x00   | 0x00             |
| 0x7FFF | +5v0             |
| 0x800  | -5v0             |
| 0x00FF | about 40mv       |
Can you:
1) describe / guess how the top-most (sign) bit works
2) create a few convenient 16-bit constants to try, e.g 3v3, 1v25, 
