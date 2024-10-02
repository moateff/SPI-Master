`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2024 10:02:27 PM
// Design Name: 
// Module Name: SPI_Single_CS_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SPI_Single_SS_tb(
);

    // Parameters
    parameter FRAME_WIDTH       = 8;
    parameter CLKS_PER_HALF     = 2;
    parameter CLK_DELAY         = 5;  // 100 MHz
    parameter FRAMES_COUNT_BITS = 2;
    parameter CS_INACTIVE_CLKS  = 1;

    // Clock and Reset
    logic clk;
    logic reset;

    // Inputs
    logic [1:0] mode;
    logic [FRAMES_COUNT_BITS - 1:0] frame_count;
    logic [FRAME_WIDTH - 1:0] din;
    logic tx_start;

    // Outputs
    logic tx_ready;
    logic [FRAME_WIDTH - 1:0] dout;
    logic rx_done;

    // SPI Interface
    logic miso;
    logic mosi;
    logic sclk;
    logic ss_n;

    // Instantiate the SPI Master with Single Chip Select
    SPI_Master_With_Single_SS 
        #(.FRAME_WIDTH(FRAME_WIDTH),
        .CLKS_PER_HALF(CLKS_PER_HALF),
        .FRAMES_COUNT_BITS(FRAMES_COUNT_BITS),
        .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS))
    uut (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .frame_count(frame_count),
        .din(din),
        .tx_start(tx_start),
        .tx_ready(tx_ready),
        .dout(dout),
        .rx_done(rx_done),
        .miso(mosi),
        .mosi(mosi),
        .sclk(sclk),
        .ss_n(ss_n)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #CLK_DELAY clk = ~clk; // 100 MHz clock
    end
    
    // Sends a single byte from master.
    task send_single_frame(input [FRAME_WIDTH - 1:0] data);
        #20
        @(posedge clk);
        din = data;
        tx_start   = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;
        @(posedge tx_ready);
    endtask
    
    // Test Procedure
    initial begin
        // Initialize Inputs
        reset = 1'b1;
        mode = 2'b0;            // SPI Mode 0
        frame_count = 2'b11;  // Transfer 3 frames
        tx_start = 0;
        miso = 1'b0;         // Slave sends no data (for now)

        // Apply reset
        #10 reset = 1'b0;
        
        // Test single byte
        send_single_frame(8'hA5);
        @(negedge rx_done);
        // After the transmission completes, we can check results
        $display("Test 1: SPI Mode 0, Expected Output = 0x%h, Received Output = 0x%h", din, dout);

        // Test single byte
        send_single_frame(8'h3C);
        @(negedge rx_done);
        // After the transmission completes, we can check results again
        $display("Test 2: SPI Mode 0, Expected Output = 0x%h, Received Output = 0x%h", din, dout);
        
        send_single_frame(8'h5E);
        @(negedge rx_done);
        // After the transmission completes, we can check results again
        $display("Test 3: SPI Mode 0, Expected Output = 0x%h, Received Output = 0x%h", din, dout);
        
        #340;
        
        // End the simulation
        $stop;
  end

endmodule

