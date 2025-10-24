"""Debug test to understand timing"""
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock

async def send_trigger_v2(dut):
    """Send trigger with proper timing"""
    await RisingEdge(dut.clk)
    dut.trigger_request.value = 1
    await RisingEdge(dut.clk)
    dut.trigger_request.value = 0

@cocotb.test()
async def test_timing_v2(dut):
    """Debug: Test new send_trigger timing"""
    dut._log.info("=== TIMING V2 TEST ===")
    
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    
    # Reset
    dut.reset.value = 1
    dut.enable.value = 1
    dut.trigger_request.value = 0
    dut.delay_cycles.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 1)
    
    dut._log.info("Calling send_trigger_v2()...")
    await send_trigger_v2(dut)
    dut._log.info("send_trigger_v2() returned")
    dut._log.info(f"  state={int(dut.current_state.value)}, trigger_out={int(dut.trigger_out.value)}")
    
    await RisingEdge(dut.clk)
    dut._log.info("After 1 more clock:")
    dut._log.info(f"  state={int(dut.current_state.value)}, trigger_out={int(dut.trigger_out.value)}")
