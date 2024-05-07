`timescale 1ns / 1ps
module multiplier_syntop_wrapper #(  N = 16,    // Length of the input sequences
                              QW = 64,   // Bit-width of each input sample
                              UW = 1   // Bit-width of each input sample
                           ) (

//  // Synchronous system
//    input   clk,
//    input  arstn,
//    input   locked // pll locked active high
);

reg  clk, locked,arstn;
  // Instantiate multiplier module
  multiplier_syntop #(N, QW, UW) multiplier_syntop_inst (
    .clk(clk),
    .arstn(arstn),
    .locked(locked)
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