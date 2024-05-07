`timescale 1ns / 1ps
module synchronizer #(parameter  int N = 2) (
    input logic clk,
    input logic arstn,
    input logic async_in,
    output logic s_rst_n
);

// Flip-flops for synchronization
logic [N-1:0] sync_ff;

always_ff @(posedge clk or negedge arstn) begin
    if (~arstn) begin
        sync_ff <= 'b0;
    end else begin
        sync_ff <= {sync_ff[N-2:0],async_in};
    end
end

// Output synchronized signal
assign s_rst_n = sync_ff[N-1];

endmodule
