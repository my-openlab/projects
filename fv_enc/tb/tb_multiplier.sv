`timescale 1ns/1ps

module tb_multiplier;

    parameter N = 4;
    parameter QWIDTH = 5;
    parameter UWIDTH = 1;
    
    // Inputs to the DUT
    logic clk;
    logic rstn;
    
    // Outputs from the DUT

    axis_if #(QWIDTH) p();
    axis_if #(UWIDTH) u();
    axis_if #(QWIDTH) z();

    // Instantiate the Device Under Test (DUT)
    multiplier_top #(
        .N(N),
        .QW(QWIDTH),
        .UW(UWIDTH)
    ) dut (
        .clk(clk),
        .s_rst_n(rstn),
        .p(p),
        .u(u),
        .z(z)
        );

    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock

    // Initial block for test vectors and reset
    initial begin
        clk = 0;
        rstn = 0;
        p.vld = 0; p.vld = 0;p.last = 0; p.data = 0;
        u.vld = 0; u.vld = 0;u.last = 0; u.data = 0;
        z.rdy = 0;
        #20;  // Wait 20ns for global reset
        rstn = 1;  // De-assert reset
        #10;

        // Provide test vectors
        // Let's use a simple example where h[n] = {1, 1, 1, 1} and x[n] = {30, 8, 31, 4}
        // Feed input values
        @(posedge clk)               p.data = 1; u.data = 1;u.vld = 1; p.vld = 1;
        @(posedge clk)               p.data = 2; u.data = 1;
        @(posedge clk)               p.data = 3; u.data = 1;
        @(posedge clk)               p.data = 4; u.data = 1; u.last = 1; p.last = 1;

        @(posedge clk)               u.last = 0; p.last = 0;  u.vld = 0; p.vld = 0; // End of valid input stream

        // staring new stream
        u.vld = 1; p.vld = 1;        p.data = 24; u.data = 1;
        @(posedge clk)               p.data = 25; u.data = 1;
        @(posedge clk)               p.data = 26; u.data = 1;
        @(posedge clk)               p.data = 27; u.data = 1;u.last = 1; p.last = 1;
        @(posedge clk)  u.vld = 0; p.vld = 0; u.last = 0; p.last = 0; // End of valid input stream
        
        // staring new stream
        u.vld = 1; p.vld = 1;        p.data = 5; u.data = 1;
        @(posedge clk)               p.data = 6; u.data = 1;
        @(posedge clk)               p.data = 7; u.data = 1;
        @(posedge clk)               p.data = 8; u.data = 1;u.last = 1; p.last = 1;
        @(posedge clk)  u.vld = 0; p.vld = 0; u.last = 0; p.last = 0; // End of valid input stream

        // staring new stream
        u.vld = 1; p.vld = 1;        p.data = 28; u.data = 1;
        @(posedge clk)               p.data = 29; u.data = 1;
        @(posedge clk)               p.data = 30; u.data = 1;
        @(posedge clk)               p.data = 31; u.data = 1;u.last = 1; p.last = 1;
        @(posedge clk)  u.vld = 0; p.vld = 0; u.last = 0; p.last = 0; // End of valid input stream
         
         
        // staring new stream
        u.vld = 1; p.vld = 1;        p.data = 9; u.data = 1;
        @(posedge clk)               p.data = 10; u.data = 1;
        @(posedge clk)               p.data = 11; u.data = 1;
        @(posedge clk)               p.data = 12; u.data = 1;u.last = 1; p.last = 1;
        @(posedge clk)  u.vld = 0; p.vld = 0; u.last = 0; p.last = 0; // End of valid input stream    
        // Wait and observe outputs
        #100;
        
        // Complete the simulation
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time: %t, Output valid: %b, z data: %d", $time, z.vld, z.data);
    end

endmodule
