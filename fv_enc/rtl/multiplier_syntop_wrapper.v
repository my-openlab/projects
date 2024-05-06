`timescale 1ns / 1ps
module multiplier_syntop_wrapper #(  N = 16,    // Length of the input sequences
                              QW = 5,   // Bit-width of each input sample
                              UW = 1   // Bit-width of each input sample
                           ) (

  // Synchronous system
    input   clk,
    input   locked // pll locked active high
);

  // Instantiate multiplier module
  multiplier_syntop #(N, QW, UW) multiplier_syntop_inst (
    .clk(clk),
    .locked(locked)
  );

  reg clk, locked;

    // Clock generation
  always #5 clk = ~clk;  // 100MHz clock
  
      // Initial block for test vectors and reset
    initial begin
        clk = 0;
        locked = 0;
        #22;  
        locked = 1;
    end
endmodule