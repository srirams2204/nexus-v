import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge

# 1. FIX: logic toggles 0 -> 1 -> 0
async def clk_gen(signal, period_ns=10):
    half_period = period_ns / 2
    signal.value = 0

    while True:
        # FIX: Use 'units' (plural)
        await Timer(half_period, units="ns")
        signal.value = 1

        await Timer(half_period, units="ns")
        signal.value = 0  # FIX: Must go back to 0!

@cocotb.test()
async def fetch_tb(dut):
    # Start clock
    cocotb.start_soon(clk_gen(dut.clk, period_ns=10))

    # Initialize Inputs
    dut.rst.value = 1
    dut.pc_src.value = 0
    dut.pc_halt.value = 0
    dut.jump_val.value = 0
    
    # Reset Phase
    await Timer(20, units="ns")
    dut.rst.value = 0

    # Wait for first edge
    await RisingEdge(dut.clk)

    # Sequential Phase
    for i in range(5):
        await RisingEdge(dut.clk)

    # Jump Phase
    dut.jump_val.value = 0x00000040
    dut.pc_src.value = 1

    await RisingEdge(dut.clk)

    # Clear Jump (Resume sequential from new addr)
    dut.pc_src.value = 0

    for i in range(3):
        await RisingEdge(dut.clk)

    # Halt Phase
    dut.pc_halt.value = 1

    for i in range(3):
        await RisingEdge(dut.clk)

    dut._log.info("TEST COMPLETED!!")