`timescale 1ns/1ps

module tb_multiplier;

    parameter N = 4;
    parameter QWIDTH = 5;
    parameter UWIDTH = 1;
    
    // Inputs to the DUT
    logic clk;
    logic rstn;
    logic valid_in;
    logic last_in;
    logic [QWIDTH-1:0] x_in;
    logic [UWIDTH-1:0] h_in;
    logic rdy_in;
    
    // Outputs from the DUT
    logic valid_out,last_out;
    logic [QWIDTH-1:0] y_out;

    // Instantiate the Device Under Test (DUT)
    multiplier_top #(
        .N(N),
        .QW(QWIDTH),
        .UW(UWIDTH)
    ) dut (
        .clk(clk),
        .s_rst_n(rstn),
        .p_last(last_in),
        .u_last(last_in),
        .p_vld(valid_in),
        .u_vld(valid_in),
        .p(x_in),
        .u(h_in),
        .z_vld(valid_out),
        .z_last(last_out),
        .z_rdy(rdy_in),
        .z(y_out)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock

    // Initial block for test vectors and reset
    initial begin
        clk = 0;
        rstn = 0;
        valid_in = 0;
        last_in = 0;
        x_in = 0;
        h_in = 0;
        rdy_in = 0;
        #20;  // Wait 20ns for global reset
        rstn = 1;  // De-assert reset
        #10;

        
        // Provide test vectors
        // Let's use a simple example where h[n] = {1, 1, 1, 1} and x[n] = {30, 8, 31, 4}
        // Feed input values
        @(posedge clk) valid_in = 1; x_in = 30; h_in = 1;
        @(posedge clk)               x_in = 8; h_in = 1;
        @(posedge clk)               x_in = 31; h_in = 1;
        @(posedge clk)               x_in = 4; h_in = 1;last_in = 1;
//        @(posedge clk) valid_in = 0;  // End of valid input stream
        @(posedge clk) valid_in = 1; x_in = 30; h_in = 1;last_in = 0;
        @(posedge clk)               x_in = 8; h_in = 1;
        @(posedge clk)               x_in = 31; h_in = 1;
        @(posedge clk)               x_in = 4; h_in = 1;last_in = 1;
        @(posedge clk) valid_in = 0;  // End of valid input stream
        last_in = 0;

        // Wait and observe outputs
        #100;
        
        // Complete the simulation
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time: %t, Output valid: %b, y_out: %d", $time, valid_out, y_out);
    end

endmodule
