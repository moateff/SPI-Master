`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2024 06:55:30 PM
// Design Name: 
// Module Name: SPI_Master_tb
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


module SPI_Master_tb(
    );
    
    // Parameters
    parameter FRAME_WIDTH = 8;
    parameter CLKS_PER_HALF = 2;
    parameter CLK_DELAY = 5;  // 100 MHz
    
    // Signals for the SPI Master
    logic clk;
    logic reset;
    logic [1:0] mode;
    
    logic [FRAME_WIDTH-1:0] din;
    logic tx_start;
    logic tx_ready;
    
    logic [FRAME_WIDTH-1:0] dout;
    logic rx_done;
    
    logic miso;
    logic mosi;
    logic sclk;

    // Instantiate the SPI Master
    SPI_Master #(.FRAME_WIDTH(FRAME_WIDTH),
                 .CLKS_PER_HALF(CLKS_PER_HALF)) 
    uut (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .din(din),
        .tx_start(tx_start),
        .tx_ready(tx_ready),
        .dout(dout),
        .rx_done(rx_done),
        .miso(mosi),
        .mosi(mosi),
        .sclk(sclk)
    );

    // Clock generation (50MHz clock)
    initial 
    begin
        clk = 0;
        forever #CLK_DELAY clk = ~clk; // 10ns period (100MHz)
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
            
    // Test sequence
    initial 
    begin
        // Required for EDA Playground
         $dumpfile("dump.vcd"); 
         $dumpvars;
         
        // Initialize inputs
        reset = 1;
        mode = 2'b00;        // SPI Mode 0
        tx_start = 0;
        miso = 1'b0;

        // Apply reset
        #20 reset = 0;
          
        // Test single byte
        send_single_frame(8'hA5);
        @(negedge rx_done);
        if (dout == 8'hA5) 
            $display("SPI Master Transaction Successful: Received data = %h", dout);
        else 
            $display("SPI Master Transaction Failed: Received data = %h", dout);
        
        send_single_frame(8'h3C);
        @(negedge rx_done);
        if (dout == 8'h3C) 
            $display("SPI Master Transaction Successful: Received data = %h", dout);
        else 
            $display("SPI Master Transaction Failed: Received data = %h", dout);
        
        send_single_frame(8'hD5);
        @(negedge rx_done);
        if (dout == 8'hD5) 
            $display("SPI Master Transaction Successful: Received data = %h", dout);
        else 
            $display("SPI Master Transaction Failed: Received data = %h", dout);
        
        send_single_frame(8'h00);
        #340;
        // Finish the simulation
        $finish;
    end    
    /*
    // Simulate the SPI Slave behavior (MISO toggling)
    always @(negedge sclk)
    begin 
        miso <= ~miso;  // Just toggling to simulate some response
    end
    */
endmodule
