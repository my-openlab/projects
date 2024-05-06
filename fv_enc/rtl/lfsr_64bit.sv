`timescale 1ns / 1ps
module lfsr_64bit #(parameter logic [63:0] SEED = 64'hFEDCBA9876543210 ) (
    input logic clk,
    input logic s_rst_n,
    output logic [63:0] lfsr_out
);

// LFSR state
logic [63:0] lfsr_state;

// Feedback taps for a 64-bit LFSR (X^63 + X^62 + X^60 + X^59)
localparam int LFSRTAPS = 64;
localparam int TAP1 = 63;
localparam int TAP2 = 62;
localparam int TAP3 = 60;
localparam int TAP4 = 59;

// Initial seed for the LFSR
localparam logic [63:0] INITSEED = SEED;

always_ff @(posedge clk or negedge s_rst_n) begin
    if (!s_rst_n) begin
        lfsr_state <= INITSEED;
    end else begin
        // Shift the LFSR
        lfsr_state <= {lfsr_state[LFSRTAPS-2:0], 
                       lfsr_state[TAP1] ^ lfsr_state[TAP2] ^ lfsr_state[TAP3] ^ lfsr_state[TAP4]};
    end
end

assign lfsr_out = lfsr_state;

endmodule
