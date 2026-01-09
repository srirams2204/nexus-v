import cocotb
from cocotb.triggers import Timer, FallingEdge, RisingEdge

@cocotb.test()
async def memory_exhaustive_test(dut):
    """Test Byte, Halfword, and Word access with Sign Extension"""
    
    # Initialize inputs
    dut.mem_addr.value = 0
    dut.mem_data.value = 0
    dut.wr_en.value = 0
    dut.funct3.value = 0
    
    # Start Clock
    cocotb.start_soon(clock_gen(dut))
    await Timer(1, unit='ns')

    # --- TEST 1: Store Word (SW) and Load Word (LW) ---
    dut._log.info("Testing SW and LW...")
    await write_mem(dut, addr=0x4, data=0xDEADBEEF, funct3=2) # SW
    res = await read_mem(dut, addr=0x4, funct3=2)            # LW
    res_val = res.to_unsigned()
    assert res_val == 0xDEADBEEF, f"LW failed: expected 0xDEADBEEF, got {hex(res_val)}"

    # --- TEST 2: Store Byte (SB) and Alignment ---
    dut._log.info("Testing SB at different offsets...")
    # Write 0xAA to Byte 1 of Word 8 (Address 33 is Word 8, Offset 1)
    await write_mem(dut, addr=33, data=0xAA, funct3=0) 
    # Read back full word to ensure only 1 byte changed
    res = await read_mem(dut, addr=32, funct3=2) 
    res_int = res.to_unsigned() 
    assert (res_int & 0x0000FF00) >> 8 == 0xAA, f"SB failed: expected 0xAA, got {hex((res_int & 0x0000FF00) >> 8)}"

    # --- TEST 3: Load Byte (LB) Sign Extension ---
    dut._log.info("Testing LB sign extension...")
    # Write 0x80 (which is -128 in 8-bit signed) to address 64
    await write_mem(dut, addr=64, data=0x80, funct3=0)
    # Read back as Signed Byte (LB)
    res = await read_mem(dut, addr=64, funct3=0) 
    res_signed = res.to_signed()
    assert res_signed == -128, f"LB Sign Ext failed: expected -128, got {res_signed} ({hex(res.to_unsigned())})"

    # --- TEST 4: Load Byte Unsigned (LBU) ---
    dut._log.info("Testing LBU zero extension...")
    res = await read_mem(dut, addr=64, funct3=4) # LBU
    res_unsigned = res.to_unsigned()
    assert res_unsigned == 0x80, f"LBU failed: expected 0x80, got {hex(res_unsigned)}"

    dut._log.info("All Data Memory tests passed!")

async def clock_gen(dut):
    """Simple clock generator"""
    while True:
        dut.clk.value = 0
        await Timer(5, unit='ns')
        dut.clk.value = 1
        await Timer(5, unit='ns')

async def write_mem(dut, addr, data, funct3):
    await RisingEdge(dut.clk)
    dut.mem_addr.value = addr
    dut.mem_data.value = data
    dut.wr_en.value = 1
    dut.funct3.value = funct3
    await FallingEdge(dut.clk) # Memory writes on negedge
    await Timer(1, unit='ns') 
    dut.wr_en.value = 0

async def read_mem(dut, addr, funct3):
    await RisingEdge(dut.clk)
    dut.mem_addr.value = addr
    dut.wr_en.value = 0
    dut.funct3.value = funct3
    # BRAM needs two falling edges to propagate address -> raw_word -> out
    await FallingEdge(dut.clk) 
    await FallingEdge(dut.clk)
    await Timer(1, unit='ns') # Combinational sign-extension settle
    return dut.data_out.value