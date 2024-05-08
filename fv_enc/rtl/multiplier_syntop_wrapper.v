`timescale 1ns / 1ps
module multiplier_syntop_wrapper #(  N = 16,    // Length of the input sequences
                              QW = 64,   // Bit-width of each input sample
                              UW = 1   // Bit-width of each input sample
                           ) (

//    input   clk,
//    input  arstn,
//    input   locked, // pll locked active high
//    axis_if.out z
    
);

   axis_if #(QW) z(); 
   reg  clk, locked,arstn,s_rst_n;
   
   axisdump #( .DW(QW), .ADDR_W($clog2(N)), .DEPTH(N) ) axisdump_inst (
    .clk(clk),
    .s_rst_n(locked),
    .stream_in(z) // AXI Stream interface
   );

    
  // Instantiate multiplier module
  multiplier_syntop #(N, QW, UW) multiplier_syntop_inst (
    .clk(clk),
    .arstn(arstn),
    .locked(locked),
    .z(z)
  );



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


endmodule