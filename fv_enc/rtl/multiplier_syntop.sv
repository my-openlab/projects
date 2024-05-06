`timescale 1ns / 1ps
module multiplier_syntop #(parameter int N = 16,    // Length of the input sequences
                             int QW = 64,   // Bit-width of each input sample
                             int UW = 1   // Bit-width of each input sample
                           ) (

  input   clk,
  input   locked // async reset, active low

);

  localparam logic [63:0] USeed = 64'hFEDCBA9876543210;
  localparam logic [63:0] PSeed = 64'hACE1ACE1ACE1ACE1;

  // AXI stream interface. 1 coefficient of p per cycle.
  axis_if #(QW) p();
//  logic  p_vld;
//  logic  p_rdy;
//  logic [QW-1:0] p;
//  logic  p_last;

// AXI stream interface. 1 coefficient of u per cycle.
  axis_if #(UW) u();
//  logic  u_vld;
//  logic  u_rdy;
//  logic [UW-1:0] u;
//  logic  u_last;

// AXI stream interface. 1 coefficient of the result z per cycle.
  axis_if #(QW) z(); 
//  logic  z_vld;
//  logic  z_rdy; // ignored, design expects recieving ip to be always ready
//  logic [QW-1:0] z;
//  logic  z_last;
  logic s_rst_n;


  synchronizer #(.N(2)) synchronizer_inst  (
    .clk,
    .reset(1),
    .async_in(locked),
    .s_rst_n
);


  // Instantiate multiplier_top
  multiplier_top #(.N(N), .QW(QW), .UW(UW)) multiplier_top_inst ( .clk, .s_rst_n, .p, .u, .z );

  // Instantiate axi_stream_generator module
  axis_gen #(.N(N),.DATAW(QW),.SEED(PSeed)) p_gen_inst (
    .clk(clk),
    .s_rst_n(s_rst_n), .lfsr_out(p)
  );

  // Instantiate axi_stream_generator module
  axis_gen #(.N(N),.DATAW(UW),.SEED(PSeed)) u_gen_inst (
    .clk,
    .s_rst_n, .lfsr_out(u)
  );

endmodule