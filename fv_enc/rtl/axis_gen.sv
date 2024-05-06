`timescale 1ns / 1ps
module axis_gen #(parameter int N = 16,
                  int DATAW = 64,
                  logic [DATAW-1:0] SEED = 64'hFEDCBA9876543210 )
(
    input logic clk,
    input logic s_rst_n,
    axis_if.out lfsr_out
    // input logic ready,
    // output logic valid,
    // output logic last,
    // output logic [DATAW-1:0] data_out
);

localparam int CntBitW = $clog2(N);
logic [63:0] data; 

// Instantiate the 64-bit LFSR module
lfsr_64bit #(.SEED(SEED)) lfsr_inst (
    .clk,
    .s_rst_n,
    .lfsr_out(data)
);

// use only the require number of bits for output
assign lfsr_out.data = data[DATAW-1:0];

// Counter to count clock cycles
logic [CntBitW-1:0] counter;

always_ff @(posedge clk) begin
    if (!s_rst_n) begin
        counter <= 'b0;
        lfsr_out.vld <= 'b0;
        lfsr_out.last <= 'b0;
    end else begin
        lfsr_out.last <= 'b0;
        lfsr_out.vld <= lfsr_out.rdy;
        if (lfsr_out.rdy) begin
            if (counter == N-1) begin // Reset counter every N cycles
                counter <= 'b0;
                lfsr_out.last <= 'b1;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
end


endmodule
