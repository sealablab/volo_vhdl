"""Debug test - trace every cycle"""
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock

@cocotb.test()
async def test_detailed_trace(dut):
    """Trace every single cycle"""
    dut._log.info("=== DETAILED TRACE ===")
    
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    
    # Reset
    dut.reset.value = 1
    dut.enable.value = 1
    dut.trigger_request.value = 0
    dut.delay_cycles.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 1)
    
    # Manual trigger with detailed logging
    dut._log.info("=== Starting manual trigger ===")
    
    # Align
    await RisingEdge(dut.clk)
    dut._log.info("Cycle 0 (after align):")
    dut._log.info(f"  trigger_request={int(dut.trigger_request.value)}, state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    # Set trigger_request
    dut.trigger_request.value = 1
    dut._log.info("Set trigger_request=1")
    
    # Wait for FSM to sample it
    await RisingEdge(dut.clk)
    dut._log.info("Cycle 1 (FSM should have sampled trigger_request=1):")
    dut._log.info(f"  trigger_request={int(dut.trigger_request.value)}, state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    dut.trigger_request.value = 0
    
    # Next cycle - check if in DELAY_COUNT
    await RisingEdge(dut.clk)
    dut._log.info("Cycle 2:")
    dut._log.info(f"  trigger_request={int(dut.trigger_request.value)}, state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    # Next cycle - should trigger?
    await RisingEdge(dut.clk)
    dut._log.info("Cycle 3:")
    dut._log.info(f"  trigger_request={int(dut.trigger_request.value)}, state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
