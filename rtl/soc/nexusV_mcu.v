`timescale 1ns/1ps
module nexusV_mcu(
    input clk,
    input rst_n
);

// core and apb
wire [31:0] core_bus_addr, core_bus_wdata, core_bus_rdata;
wire core_bus_write, core_bus_valid, core_bus_ready;

// core and clint
wire mtip_wire, msip_wire;

// APB interconnect
wire [31:0] master_paddr, master_pwdata, master_prdata;
wire master_pwrite, master_psel, master_penable, master_pready;

// Slave 0: CLINT
wire psel_clint;
wire [31:0] prdata_clint;
wire pready_clint;

// Slave 1: GPIO 
wire psel_gpio;
wire [31:0] prdata_gpio;
wire pready_gpio;

// Slave 2: UART 
wire psel_uart;
wire [31:0] prdata_uart;
wire pready_uart;

// Slave 3: SPI 
wire psel_spi;
wire [31:0] prdata_spi;
wire pready_spi;

// Slave 4: PWM 
wire psel_pwm;
wire [31:0] prdata_pwm;
wire pready_pwm;

// apb base addr done in core
//wire is_apb = (master_paddr[31:16] == 16'h4000);

// peripehral sel decoder [15:12]
assign psel_clint = (master_psel && (master_paddr[15:12] == 4'h0));
assign psel_gpio  = (master_psel && (master_paddr[15:12] == 4'h1));
assign psel_uart  = (master_psel && (master_paddr[15:12] == 4'h2));
assign psel_spi   = (master_psel && (master_paddr[15:12] == 4'h3));
assign psel_pwm   = (master_psel && (master_paddr[15:12] == 4'h4));

reg [31:0] mux_prdata;
reg mux_pready;

always @(*) begin
    mux_prdata = 32'h0;
    mux_pready = 1'b1; 
    if (psel_clint) begin
        mux_prdata = prdata_clint;
        mux_pready = pready_clint;
    end else if (psel_gpio) begin
        mux_prdata = prdata_gpio;
        mux_pready = pready_gpio;
    end else if (psel_uart) begin
        mux_prdata = prdata_uart;
        mux_pready = pready_uart;
    end else if (psel_spi) begin
        mux_prdata = prdata_spi;
        mux_pready = pready_spi;
    end else if (psel_pwm) begin
        mux_prdata = prdata_pwm;
        mux_pready = pready_pwm;
    end
end

assign master_prdata = mux_prdata;
assign master_pready = mux_pready;

// Remove later after all the peripherals are connected to the top module
assign prdata_gpio = 32'h0; assign pready_gpio = 1'b1;
assign prdata_uart = 32'h0; assign pready_uart = 1'b1;
assign prdata_spi  = 32'h0; assign pready_spi  = 1'b1;
assign prdata_pwm  = 32'h0; assign pready_pwm  = 1'b1;

// The RISC-V CPU
nexusV_core u_core (
    .clk(clk),
    .rst_n(rst_n),
    .bus_addr(core_bus_addr),
    .bus_wdata(core_bus_wdata),
    .bus_write(core_bus_write),
    .bus_valid(core_bus_valid),
    .bus_rdata(core_bus_rdata),
    .bus_ready(core_bus_ready),
    .mtip(mtip_wire),
    .msip(msip_wire),
    .meip(1'b0) // External interrupt tied to 0 for now
);

wire is_apb = (core_bus_addr[31:16] == 16'h4000);

wire apb_valid = core_bus_valid && is_apb;
wire        apb_cpu_ready;
wire [31:0] apb_cpu_rdata;
assign core_bus_ready = (core_bus_valid && is_apb) ? apb_cpu_ready : 1'b1;
assign core_bus_rdata = (core_bus_valid && is_apb) ? apb_cpu_rdata : 32'h0;

// The APB Bridge
apb_master u_apb_master (
    .pclk(clk),
    .presetn(rst_n),
    .cpu_addr(core_bus_addr),
    .cpu_wdata(core_bus_wdata),
    .cpu_write(core_bus_write),
    .cpu_valid(apb_valid),
    .cpu_rdata(apb_cpu_rdata),
    .cpu_ready(apb_cpu_ready),
    .paddr(master_paddr),
    .pwdata(master_pwdata),
    .pwrite(master_pwrite),
    .psel(master_psel),
    .penable(master_penable),
    .prdata(master_prdata),
    .pready(master_pready)
);

// Peripheral 0: The Timer
clint_apb u_clint (
    .pclk(clk),
    .presetn(rst_n),
    .paddr(master_paddr),
    .psel(psel_clint),
    .penable(master_penable),
    .pwrite(master_pwrite),
    .pwdata(master_pwdata),
    .prdata(prdata_clint),
    .pready(pready_clint),
    .mtip(mtip_wire),
    .msip(msip_wire)
);

endmodule