`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2024 07:59:54 PM
// Design Name: 
// Module Name: SPI_Master_With_Single_CS
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

module SPI_Master_With_Single_SS
#(  
    parameter FRAME_WIDTH       = 8,            // Width of each data frame in bits
              CLKS_PER_HALF     = 2,            // Number of system clocks per half period of SPI clock
              FRAMES_COUNT_BITS = 2,            // Number of bits needed to represent the frame count
              CS_INACTIVE_CLKS  = 1             // Number of clocks CS remains inactive between transfers
)(
    input  logic                           clk,          // System clock input
    input  logic                           reset,        // Reset signal to reset the SPI Master state
    input  logic [1:0]                     mode,         // SPI mode: 0, 1, 2, or 3 (clock polarity and phase)
    input  logic [FRAMES_COUNT_BITS - 1:0] frame_count,  // Number of frames per CS low
    
    // TX (MOSI) Signals
    input  logic [FRAME_WIDTH - 1:0] din,       // Data to be transmitted (Master to Slave)
    input  logic                     tx_start,  // Transmission start signal, triggers the data transfer
    output logic                     tx_ready,  // Indicates SPI is ready for a new data transmission
    
    // RX (MISO) Signals
    output logic [FRAME_WIDTH - 1:0] dout,       // Data received from the slave (Master In Slave Out)
    output logic                     rx_done,    // Indicates the reception of data is complete
    
    // SPI Interface
    input  logic                     miso,       // Slave-to-master data line (MISO: Master In Slave Out)
    output logic                     mosi,       // Master-to-slave data line (MOSI: Master Out Slave In)
    output logic                     sclk,       // SPI clock, generated by the Master
    output logic                     ss_n        // Single chip-select (SS: Slave Select)
);
    
    // Define the states for the FSM
    typedef enum {IDLE, TRANSFER, INACTIVE} state_type;
    state_type state_next, state_reg;
    
    // Registers to hold clock inactivity and frame count
    logic [$clog2(CS_INACTIVE_CLKS) - 1:0] c_next, c_reg; // Counter for inactive clock cycles
    logic [FRAMES_COUNT_BITS - 1:0]        n_next, n_reg; // Counter for number of frames left to transfer
    logic                                  master_ready;  // Indicates when SPI Master is ready
    logic                                  SS_n_next, SS_n_reg; // Chip select signal control
    logic                                  w_tx_start;    // Internal signal to control start of transmission
    
    // Instantiate the SPI Master module for actual data transfer
    SPI_Master #(.FRAME_WIDTH(FRAME_WIDTH),
                 .CLKS_PER_HALF(CLKS_PER_HALF)) 
    uut (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .din(din),
        .tx_start(w_tx_start),
        .tx_ready(master_ready),
        .dout(dout),
        .rx_done(rx_done),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk)
    );
    
    // Sequential logic to update the state machine and counters on clock edges or reset
    always_ff @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            state_reg    <= IDLE;      // Reset state machine to IDLE
            c_reg        <= 0;         // Reset inactive clock counter
            n_reg        <= frame_count; // Initialize frame count
            SS_n_reg     <= 1'b1;      // Deassert chip select (SS is inactive)
        end
        else
        begin
            state_reg    <= state_next;  // Update state machine
            c_reg        <= c_next;      // Update inactive clock counter
            n_reg        <= n_next;      // Update frame counter
            SS_n_reg     <= SS_n_next;   // Update chip select signal
        end
    end 
    
    // Combinational logic for state machine transitions and output control
    always_comb
    begin
        // Default values
        state_next = state_reg;
        c_next = c_reg;
        n_next = n_reg;
        SS_n_next = SS_n_reg;
        
        case(state_reg)
            // IDLE state: waiting for the start of transmission
            IDLE:
            begin
                if(n_reg && tx_start) // If frames are left and tx_start is asserted
                begin
                    SS_n_next = 1'b0;       // Drive chip select low
                    state_next = TRANSFER;  // Move to TRANSFER state to start communication
                end
            end

            // TRANSFER state: actively sending and receiving data
            TRANSFER:
            begin
                // Wait until SPI transfer is done (rx_done asserted)
                if(rx_done)
                begin
                    n_next = n_reg - 1;     // Decrease frame count
                    SS_n_next = 1'b1;       // Set chip select high (transfer complete)
                    state_next = INACTIVE;  // Move to INACTIVE state
                end
            end

            // INACTIVE state: CS is inactive for a defined period before restarting
            INACTIVE:
            begin
                if(c_reg == CS_INACTIVE_CLKS - 1) // Wait for the specified inactive clocks
                    state_next = IDLE;      // Return to IDLE state for next transfer
                else
                    c_next = c_reg + 1;     // Increment the inactivity clock counter
            end
        endcase
    end 
    
    // Output assignments
    assign SS_n = SS_n_reg;  // Assign current SS_n signal
    assign tx_ready  = ((state_reg == IDLE) | (state_reg == TRANSFER && master_ready)) && ~tx_start && (n_reg > 0); // Ready when in IDLE or TRANSFER and SPI is not busy
    assign w_tx_start = (n_reg > 0) ? tx_start : 1'b0; // Control signal to start transmission only when frames are left
    
endmodule