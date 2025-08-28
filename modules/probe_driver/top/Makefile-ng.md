# Makefile-ng

I want to enhance the current makefile, and I have two conflicting design goals I need your help addressing.

Rather than describe them in details I would rahter just give examples.

## Example 1: Each sub module can be built independently
``` shell
volo_codes/volo_vhdl/modules/probe_driver/tb
johnycsh@DRP-e1 ~/v/v/m/p/tb (main)> make
```


## Example 2:

``` shell
volo_codes/volo_vhdl/modules
johnycsh@DRP-e1 ~/v/v/modules (main)> ls   
clk_divider/  probe_driver/ README.md
make
```

The ability to type 'make' at each level of the project and compile the files underneath is very attractive to me as a software developer.


What I am concerned about is:
* __dont__ duplicate code or logic in individual makefiles
Ideally this would lead to a makefile located at 
`volo_vhdl/modules' that contains the logic in a single spot

