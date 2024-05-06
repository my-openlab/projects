module multiplier_top_wrapper #(parameter int N = 16,    // Length of the input sequences
                             int QW = 64,   // Bit-width of each input sample
                             int UW = 1   // Bit-width of each input sample
                           ) (
  // Synchronous system
  input   clk,
  input   s_rst_n, // synchronous reset, active low

  // AXI stream interface. 1 coefficient of p per cycle.
  input   p_vld,
  output   p_rdy,
  input  [QW-1:0] p,
  input   p_last,

  // AXI stream interface. 1 coefficient of u per cycle.
  input   u_vld,
  output   u_rdy,
  input  [UW-1:0] u,
  input   u_last,

  // AXI stream interface. 1 coefficient of the result z per cycle.
  output   z_vld,
  input   z_rdy, // ignored, design expects recieving ip to be always ready
  output  [QW-1:0] z,
  output   z_last
);

  // Instantiate multiplier module
  multiplier_top #(N, QW, UW) multiplier_top_inst (
    .clk(clk),
    .s_rst_n(s_rst_n),
    .p_vld(p_vld),
    .p_rdy(p_rdy),
    .p(p),
    .p_last(p_last),
    .u_vld(u_vld),
    .u_rdy(u_rdy),
    .u(u),
    .u_last(u_last),

    .z_vld(z_vld),
    .z_rdy(z_rdy),
    .z(z),
    .z_last(z_last)

  );

endmodule