`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2025 12:58:31 PM
// Design Name: 
// Module Name: Light_Sensor_ALS
// Project Name: 
// Target Devices: Basys 3
// Tool Versions: 
// Description: Top-Level module for Ambient Light Sensor Project (ALS)
// SPI operates at 2.5MHz, CPHA = 1, CPOL = 1
// Interfaces to the Digilent Pmod ALS chip via SPI. Receives 2 bytes from the 
// PMOD board. Data comes spread across 2 bytes, for whatever reason.
//                 MSB                       LSB
// Index  7  6  5  4  3  2  1  0  | 7  6  5  4  3  2  1  0 
// Data   0  0  0  D7 D6 D5 D4 D3 | D2 D1 D0 0  0  0  0  Z
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Light_Sensor_ALS(
    // System clock, Reset (ButnC)
    input clk, reset,
    
    // 7-Segment Display
    output [6:0] seg,
    output [3:0] an,
    
    // PMOD SPI Interface
    inout [3:0] JB
    // output JB[0] pin 1 (~CS, Chip Select, Active Low)
    // output JB[1] pin 2 (MOSI), not connected (NC) for ALS, TODO: problematic?
    // input  JB[2] pin 3 (MISO)
    // output JB[3] pin 4 (SCLK)
    );
    
    // Clock phase (CPHA) and Clock polarity (CPOL) are both 1
    parameter SPI_MODE = 3;
    
    // Basys 3 operates at 100MHz, PmodALS requires the frequency of the SCLK to 
    // be between 1 MHz and 4 MHz. Divided by 100 to get 1MHz, then 2 to get the
    // clocks per half bit.
    parameter CLKS_PER_HALF_BIT = 50;
    
    // Number of clock cycles to leave CS high after transaction (dead time), this
    // PMOD chip specifies 10ns, which is one clock cycle for 100MHz.
    // TODO: What should I set this to?
    parameter CS_INACTIVE_CLKS = 100;
    
    wire w_Rst_L;
    
    // SPI Signals
    wire [1:0]  w_Master_RX_Count;
    wire        w_Master_RX_DV;
    wire [7:0]  w_Master_RX_Byte;
    wire        w_Master_TX_Ready;
    reg         r_Master_TX_DV;
    
    reg         r_LED_Enable;
    reg  [7:0]  r_LED_Count;
    wire [7:0]  w_Ambient_Val;
    reg  [15:0] r_ADC_Word;
    
    // TODO: better understand this logic
    assign w_Rst_L = ~reset;
    
    SPI_Master_With_Single_CS
      #(.SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
        .MAX_BYTES_PER_CS(2),
        .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
      )
    (
    .i_Rst_L(w_Rst_L),
    .i_Clk(clk),
    
    // TX (MOSI) Signals
    .i_TX_Count(2'b10),
    .i_TX_Byte(8'h00),               // ALS doesn't take input, can send whatever
    .i_TX_DV(r_Master_TX_DV),
    .o_TX_Ready(w_Master_TX_Ready),
    
    // RX (MISO) Signals
    .o_RX_Count(w_Master_RX_Count),
    .o_RX_Byte(w_Master_RX_Byte),
    .o_RX_DV(w_Master_RX_DV),
    
    // SPI Interfaces
    .o_SPI_Clk(JB[3]),
    .i_SPI_MISO(JB[2]),
    .o_SPI_MOSI(JB[1]), // TODO: Unsure an NC pin is the right assignment here
    .o_SPI_CS_n(JB[0])
    );
    
    // Handle read requests from ADC as often as possible, 'pulses' 
    // data valid (DV) to let PMOD know it can drive more data to master.
    always @ (posedge clk)
      r_Master_TX_DV <= w_Master_TX_Ready;
      
    // process data coming from SPI, extract appropriate bits for ambient
    // light reading
    always @ (posedge clk)
    begin
      if (w_Master_RX_DV)
      begin
        if (w_Master_RX_Count == 0)
          r_ADC_Word[15:8] <= w_Master_RX_Byte;
        else
          r_ADC_Word[7:0] <= w_Master_RX_Byte;
      end
    end
    
    // Capture the ambient value
    assign w_Ambient_Val = r_ADC_Word[12:5];
    
    // Use the value from the ALS to drive the LED brightness, by driving
    // duty cycle (fraction of 'on' time). When the ambient value is high,
    // r_LED_Count is mostly less then w_Ambient_Val, setting r_LED_Enable
    // to 1 (true or on), which then gets inverted low for illumination.
    always @ (posedge clk)
    begin
      r_LED_Count <= r_LED_Count + 1;
      r_LED_Enable <= (r_LED_Count < w_Ambient_Val);
    end
    
    // light up all four
    assign an[3:0] = {4{0}};
    assign seg[6:0] = {7{!r_LED_Enable}};
    
endmodule // Light_Sensor_ALS
