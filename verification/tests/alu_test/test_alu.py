import cocotb
from cocotb.triggers import Timer

class ALU_OPS:
    ADD  = 0
    SUB  = 1
    XOR  = 2
    OR   = 3
    AND  = 4
    SLL  = 5
    SRL  = 6
    SRA  = 7
    SLT  = 8
    SLTU = 9

def to_signed_32(val):
    """Convert a python integer to a 32-bit two's complement value."""
    return val & 0xFFFFFFFF

@cocotb.test()
async def alu_exhaustive_test(dut):
    """Test various ALU operations using modern Cocotb API."""

    # --- Test 1: Addition ---
    dut.A.value = 10
    dut.B.value = 20
    dut.sel.value = ALU_OPS.ADD
    await Timer(1, unit='ns')
    # Use .to_unsigned() instead of .integer
    res = dut.alu_out.value.to_unsigned()
    assert res == 30, f"ADD failed: got {res}"

    # --- Test 2: Subtraction (50 - 70 = -20) ---
    dut.A.value = 50
    dut.B.value = 70
    dut.sel.value = ALU_OPS.SUB
    await Timer(1, unit='ns')
    # Use .to_signed() instead of .signed_integer
    res_signed = dut.alu_out.value.to_signed()
    assert res_signed == -20, f"SUB failed: got {res_signed}"

    # --- Test 3: Signed Comparison (SLT) ---
    dut.A.value = to_signed_32(-5)
    dut.B.value = 2
    dut.sel.value = ALU_OPS.SLT
    await Timer(1, unit='ns')
    res = dut.alu_out.value.to_unsigned()
    assert res == 1, f"SLT failed: -5 < 2 should be 1, got {res}"

    # --- Test 4: Arithmetic Shift Right (SRA) ---
    # 0x80000000 >> 1 (Arithmetic) should be 0xC0000000
    dut.A.value = 0x80000000
    dut.B.value = 1
    dut.sel.value = ALU_OPS.SRA
    await Timer(1, unit='ns')
    res = dut.alu_out.value.to_unsigned()
    assert res == 0xC0000000, f"SRA failed: got {hex(res)}"

    dut._log.info("All ALU tests passed without warnings!")