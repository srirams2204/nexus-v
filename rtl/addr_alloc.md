# NEXUS-V SoC MEMORY MAP & ADDRESS ALLOCATION

Project: Nexus-V RISC-V Core
Arch:    RV32I (32-bit Address Space)

--------------------------------------------------------------------------------
1. GLOBAL SYSTEM MEMORY MAP
--------------------------------------------------------------------------------
The address space uses a "Guard Band" architecture to separate Code and Data.

| Start Address | End Address   | Size   | Device / Region       | Access (Data Bus) |
| :---          | :---          | :---   | :---                  | :---              |
| 0x0000_0000   | 0x0000_0FFF   | 4 KB   | Instruction ROM       | Fetch Only (Read=0) |
| 0x0000_1000   | 0x0000_1FFF   | 4 KB   | **RESERVED (Guard Band)** | Silent Ignore     |
| 0x0000_2000   | 0x0000_2FFF   | 4 KB   | **Data RAM** | R/W               |
| 0x0000_3000   | 0x7FFF_FFFF   | --     | RESERVED (Gap)        | Silent Ignore     |
| 0x8000_0000   | 0xFFFF_FFFF   | 2 GB   | External APB Bus      | R/W               |

*Note: The Reserved regions return 0 on Read and ignore Writes, protecting the CPU from crashes due to pointer overflows.*

--------------------------------------------------------------------------------
2. HARDWARE IMPLEMENTATION NOTES (Verilog Logic)
--------------------------------------------------------------------------------
The address decoding logic in `nexusV_core.v` enforces these regions using bit-masking:

* **RAM Region (0x2000 - 0x2FFF):**
  * **Verilog:** `wire is_ram_addr = (ALUOut[31:12] == 20'h00002);`
  * **Logic:** Checks if the top 20 bits exactly match `0x00002`. This isolates the 4KB block starting at `0x2000`.

* **APB Region (0x8000_0000 - 0xFFFF_FFFF):**
  * **Verilog:** `wire is_apb_addr = ALUOut[31];`
  * **Logic:** Checks if the Most Significant Bit (MSB) is `1`. Any address in the upper 2GB triggers an external bus request.

* **Safety / Gaps:**
  * **Verilog:** `wire [31:0] final_load_data = ... ? ... : 32'b0;`
  * **Logic:** Addresses like `0x1000` (Gap) fail both checks above. The Read Mux returns `0` and Write Enable is gated to `0`.
