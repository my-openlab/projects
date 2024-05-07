`timescale 1ns / 1ps
module multiplier_syntop_wrapper #(  N = 16,    // Length of the input sequences
                              QW = 64,   // Bit-width of each input sample
                              UW = 1   // Bit-width of each input sample
                           ) (

  // Synchronous system
    input   clk,
    input  arstn,
    input   locked, // pll locked active high
    axis_if.out z
);

// AXI outstream interface. 1 coefficient of the result z per cycle.
   axis_if #(QW) z(); 

   axisdump #( .DW(QW), .ADDR_W(ADDRW), .DEPTH(N) ) axisdump_inst (
    .clk(clk),
    .s_rst_n(s_rst_n),
    .stream_in(z) // AXI Stream interface
   );

/*
reg  clk, locked,arstn;
//     Clock generation  
    initial begin
      clk = 0;      
      forever #5 clk = ~clk;  // 100MHz clock
    end
//       Initial block for  clkc init and lock assert
    initial begin
        locked = 0;
        arstn = 0;
        #3 ;
        arstn = 1;
        #22;  
        locked = 1;
    end
 */   
    
  // Instantiate multiplier module
  multiplier_syntop #(N, QW, UW) multiplier_syntop_inst (
    .clk(clk),
    .arstn(arstn),
    .locked(locked)
  );


endmodule