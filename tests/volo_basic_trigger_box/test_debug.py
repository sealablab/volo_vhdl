"""Debug test to understand timing"""
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock

@cocotb.test()
async def test_timing_debug(dut):
    """Debug: Understand exact cycle timing"""
    dut._log.info("=== TIMING DEBUG TEST ===")
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    
    # Reset
    dut.reset.value = 1
    dut.enable.value = 1
    dut.trigger_request.value = 0
    dut.delay_cycles.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 1)
    
    dut._log.info("After reset:")
    dut._log.info(f"  state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    # Send trigger
    dut._log.info("Setting trigger_request=1")
    dut.trigger_request.value = 1
    
    dut._log.info("Waiting for rising edge #1...")
    await RisingEdge(dut.clk)
    dut._log.info(f"After rising edge #1:")
    dut._log.info(f"  state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    dut.trigger_request.value = 0
    
    dut._log.info("Waiting for rising edge #2...")
    await RisingEdge(dut.clk)
    dut._log.info(f"After rising edge #2:")
    dut._log.info(f"  state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    dut._log.info("Waiting for rising edge #3...")
    await RisingEdge(dut.clk)
    dut._log.info(f"After rising edge #3:")
    dut._log.info(f"  state={int(dut.current_state.value)}, counter={int(dut.counter.value)}, trigger_out={int(dut.trigger_out.value)}")
