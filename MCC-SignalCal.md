Claude,
I would like to create a new module that will be slightly more interesting/useful than the @simple_counter package.  lets create a new branch feature/SignalCal and work on it.

## SignalCal
**SignalCal** ishould,
- utilize the common MMC_READY convention we use in the reference simple counter
- make use of all currently existing shared modules, in a way that makes them easy to observe.

## 4 outputs: A,B,C,D
I think it should generate 4 unique signals that have some handy relationship between them. Maybe OutA and OutB are both sine wave but 90 phase out of sync? 

Maybe OutC would decode as ascii at a common baud rate? 😬

What do you think would be four handy signals that we could use to 'calibrate' (For lack of a better word) the other insturments and ours are communicating clearly.


## SignalCal TestBench
loads our SignalCal into Slot2
loads each other instrument into slot1

but I want to utilize our MCC_READY bits and the ability to call set_regs to verify that the output on our custom module can be toggled on and off remotely while the built in instrument can be observed __not__ seeing our signals. Does that make sense? 

Help me refine this idea and think of the wave forms, and a handful of knobs we can expose through MCC_Top control registers to make it interactive

