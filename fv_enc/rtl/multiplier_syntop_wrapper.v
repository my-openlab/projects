module multiplier_syntop_wrapper #(parameter int N = 16,    // Length of the input sequences
                             int QW = 64,   // Bit-width of each input sample
                             int UW = 1   // Bit-width of each input sample
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

endmodule