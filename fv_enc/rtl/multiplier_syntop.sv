`timescale 1ns / 1ps
module multiplier_syntop #(parameter int N = 16,    // Length of the input sequences
                             int QW = 64,   // Bit-width of each input sample
                             int UW = 1   // Bit-width of each input sample
                           ) (

  input   clk,
  input   arstn, // async reset, active low
  input   locked // async reset, active low
);

  localparam logic [63:0] USeed = 64'hFEDCBA9876543210;
  localparam logic [63:0] PSeed = 64'hACE1ACE1ACE1ACE1;
  localparam int ADDRW = $clog2(N);
  // AXI stream interface. 1 coefficient of p per cycle.
  axis_if #(QW) p();


// AXI stream interface. 1 coefficient of u per cycle.
  axis_if #(UW) u();

// AXI stream interface. 1 coefficient of the result z per cycle.
  axis_if #(QW) z(); 

  logic s_rst_n, startdata;


  synchronizer #(.N(2)) synchronizer_inst  (
    .clk,
    .arstn(arstn),
    .async_in(locked),
    .s_rst_n
  );

    synchronizer #(.N(3)) synchronizer2_inst  (
      .clk,
      .arstn(arstn),
      .async_in(s_rst_n),
      .s_rst_n(startdata)
    );

   axisdump #( .DW(QW), .ADDR_W(ADDRW), .DEPTH(N) ) axisdump_inst (
    .clk(clk),
    .s_rst_n(s_rst_n),
    .stream_in(z) // AXI Stream interface
   );


  // Instantiate multiplier_top
  multiplier_top #(.N(N), .QW(QW), .UW(UW)) multiplier_top_inst ( .clk, .s_rst_n, .p, .u, .z );

  // axi_stream_generator module, MODE =1 => continous back2back packets with no flow cntrl
  axis_gen #(.N(N),.DATAW(QW),.SEED(PSeed),.MODE(1)) p_gen_inst (
    .clk(clk),
    .s_rst_n(startdata), .lfsr_out(p)
  );

  // Instantiate axi_stream_generator module
  axis_gen #(.N(N),.DATAW(UW),.SEED(PSeed),.MODE(1)) u_gen_inst (
    .clk,
    .s_rst_n(startdata), .lfsr_out(u)
  );

endmodule