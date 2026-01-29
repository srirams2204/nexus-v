# NEXUS-V SoC MEMORY MAP & ADDRESS ALLOCATION

Project: Nexus-V RISC-V Core
Date:    January 27, 2026
Arch:    RV32I (32-bit Address Space)

--------------------------------------------------------------------------------
1. GLOBAL SYSTEM MEMORY MAP
--------------------------------------------------------------------------------
The address space is divided into three main regions:
  - LOWER (0x0000_XXXX): Instruction Memory (ROM) & Data Memory (RAM)
  - UPPER (0x8000_XXXX): Memory-Mapped Peripherals (APB Bus)
  - OTHER: Reserved / Bus Fault

| Start Address | End Address   | Size   | Device / Region       | Access |
| :---          | :---          | :---   | :---                  | :---   |
| 0x0000_0000   | 0x0000_0FFF   | 4 KB   | Instruction ROM       | R/X    |
| 0x0000_1000   | 0x0000_1FFF   | 4 KB   | Data RAM              | R/W    |
| 0x0000_2000   | 0x7FFF_FFFF   | --     | RESERVED              | Fault  |
| 0x8000_0000   | 0x8000_00FF   | 256 B  | GPIO + Timer/PWM      | R/W    |
| 0x8000_0100   | 0x8000_01FF   | 256 B  | UART (Serial)         | R/W    |
| 0x8000_0200   | 0x8000_02FF   | 256 B  | SPI (Serial Peripheral)| R/W   |
| 0x8000_0300   | 0xFFFF_FFFF   | --     | RESERVED              | Fault  |

--------------------------------------------------------------------------------
2. PERIPHERAL REGISTER MAP (OFFSETS)
--------------------------------------------------------------------------------
All peripherals are accessed via the APB Bridge.
Offsets are relative to the Peripheral Base Address.
All registers are 32-bit wide.

[A] GPIO + TIMER/PWM (Base: 0x8000_0000)
-------------------------------------------------
| Offset | Register Name | R/W | Description                                    |
| :---   | :---          | :--- | :---                                          |
| +0x00  | GPIO_DATA     | R/W | Pin Data. Read = Input Level, Write = Output   |
| +0x04  | GPIO_DIR      | R/W | Direction. 0 = Input, 1 = Output               |
| +0x08  | PWM_CTRL      | R/W | Control. Bit 0=Enable, Bit 1=PWM Mode          |
| +0x0C  | PWM_PERIOD    | R/W | Max Counter Value (Frequency Control)          |
| +0x10  | PWM_DUTY      | R/W | Compare Value (Duty Cycle Control)             |

[B] UART (Base: 0x8000_0100)
-------------------------------------------------
| Offset | Register Name | R/W | Description                                    |
| :---   | :---          | :--- | :---                                          |
| +0x00  | UART_TXDATA   | W   | Transmit Holding Register (Write char here)    |
| +0x00  | UART_RXDATA   | R   | Receive Buffer Register (Read char here)       |
| +0x04  | UART_STATUS   | R   | Bit 0=TX_Busy, Bit 1=RX_Valid (Data Ready)     |
| +0x08  | UART_CTRL     | R/W | Bit 0=Enable, Bits [31:16]=Baud Divisor        |

[C] SPI (Base: 0x8000_0200)
-------------------------------------------------
| Offset | Register Name | R/W | Description                                    |
| :---   | :---          | :--- | :---                                          |
| +0x00  | SPI_TXDATA    | W   | Write Data to send                             |
| +0x00  | SPI_RXDATA    | R   | Read received Data                             |
| +0x04  | SPI_STATUS    | R   | Bit 0=Busy, Bit 1=RX_Done                      |
| +0x08  | SPI_CTRL      | R/W | Bit 0=Enable, Bit 1=CPOL, Bit 2=CPHA           |

--------------------------------------------------------------------------------
3. C FIRMWARE DEFINITIONS (Copy to main.c or soc.h)
--------------------------------------------------------------------------------
```c
#include <stdint.h>

// --- Base Addresses ---
#define GPIO_BASE  0x80000000
#define UART_BASE  0x80000100
#define SPI_BASE   0x80000200

// --- Register Structures ---

// GPIO & PWM
typedef struct {
    volatile uint32_t DATA;       // 0x00
    volatile uint32_t DIR;        // 0x04
    volatile uint32_t PWM_CTRL;   // 0x08
    volatile uint32_t PWM_PERIOD; // 0x0C
    volatile uint32_t PWM_DUTY;   // 0x10
} gpio_t;

// UART
typedef struct {
    volatile uint32_t DATA;       // 0x00 (Write=TX, Read=RX)
    volatile uint32_t STATUS;     // 0x04
    volatile uint32_t CTRL;       // 0x08
} uart_t;

// SPI
typedef struct {
    volatile uint32_t DATA;       // 0x00 (Write=TX, Read=RX)
    volatile uint32_t STATUS;     // 0x04
    volatile uint32_t CTRL;       // 0x08
} spi_t;

// --- Pointer Mapping ---
#define GPIO ((gpio_t *) GPIO_BASE)
#define UART ((uart_t *) UART_BASE)
#define SPI  ((spi_t  *) SPI_BASE)

// --- Example Usage ---
/*
void main() {
    // Setup GPIO Pin 0 as Output
    GPIO->DIR |= 0x01;
    
    // Toggle LED
    GPIO->DATA |= 0x01;  // ON
    GPIO->DATA &= ~0x01; // OFF
    
    // Send 'A' via UART
    while (UART->STATUS & 0x01); // Wait if Busy
    UART->DATA = 'A';
}
*/
```

# END OF FILE
