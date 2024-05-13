module multiplier_top_wrapper #(parameter int N = 16,    // Length of the input sequences
                             int QW = 8,   // Bit-width of each input sample
                             int UW = 1   // Bit-width of each input sample
                           ) (
  // Synchronous system
  input   clk,
  input   s_rst_n, // synchronous reset, active low

  // AXI stream interface. 1 coefficient of p per cycle.
  input   p_tvalid,
  output  p_tready,
  input  [QW-1:0] p_tdata,
  input   p_tlast,

  // AXI stream interface. 1 coefficient of u per cycle.
  input   u_tvalid,
  output   u_tready,
  input  [8-1:0] u_tdata, // only lsb UW bits is used from the 8-bit bus
  input   u_tlast,

  // AXI stream interface. 1 coefficient of the result z per cycle.
  output   z_tvalid,
  input   z_tready, // ignored, design expects recieving ip to be always ready
  output  [QW-1:0] z_tdata,
  output   z_tlast
);


axis_if #(QW) port_p();
axis_if #(UW) port_u();
axis_if #(QW) port_z();

 assign port_p.vld  = p_tvalid;
 assign p_tready    = port_p.rdy;
 assign port_p.data = p_tdata;
 assign port_p.last = p_tlast;

 assign port_u.vld  = u_tvalid;
 assign u_tready    = port_u.rdy;
 assign port_u.data = u_tdata[UW-1:0];
 assign port_u.last = u_tlast;


 assign z_tvalid   = port_z.vld ;
 assign port_z.rdy = z_tready;
 assign z_tdata    = port_z.data;
 assign z_tlast    = port_z.last;



  // Instantiate multiplier module
  multiplier_top #(N, QW, UW) multiplier_top_inst (
    .clk(clk),
    .s_rst_n(s_rst_n),
    .p(port_p),
    .u(port_u),
    .z(port_z)

  );

endmodule