`timescale 1ns / 1ps
module multiplier_top #(parameter int N = 16,    // Length of the input sequences
              int QW = 64,   // Bit-width of each input sample
              int UW = 1   // Bit-width of each input sample
  ) (
  // Synchronous system
  input logic  clk,
  input logic  s_rst_n, // synchronous reset, active low

  
  axis_if.in p, // AXI stream interface. 1 coefficient of p per cycle.
  axis_if.in u, // AXI stream interface. 1 coefficient of u per cycle.
  axis_if.out z // AXI stream interface. 1 coefficient of the result z per cycle.
);

axis_if #(QW) port_p[2]();

// AXI stream interface. 1 coefficient of u per cycle.
axis_if #(UW) port_u[2]();

// AXI stream interface. 1 coefficient of the result z per cycle.
axis_if #(QW) port_z[2]();

logic sel_u, sel_p, sel_z;

// get two instances of multipler, mult0, mult1
generate
    for (genvar idx=0; idx < 2; idx++) begin : g_mult
        multiplier #(.N(N), .QW(QW), .UW(UW)) mult_inst (
            .clk(clk),
            .s_rst_n(s_rst_n),
            .p(port_p[idx]),
            .u(port_u[idx]),
            .z(port_z[idx])
        );
    end : g_mult

endgenerate


// naive implementation of axis switch
    always_ff @(posedge clk ) begin
        if (!s_rst_n) begin
            sel_p <= 0; // initially, data fed into is connected to multiplier 0
            sel_u <= 0;
            sel_z <= 0; // initially, output is connected to multiplier 1
            // this can be simplified with for loop, 
            // but when using interfaces the idx has to be constant
            // so for loop is not an option.
            port_p[0].data <= 'b0;
            port_p[0].vld  <= 'b0;
            port_p[0].last <= 'b0;
            port_p[1].data <= 'b0;
            port_p[1].vld  <= 'b0;
            port_p[1].last <= 'b0;

            port_u[0].data <= 'b0;
            port_u[0].vld  <= 'b0;
            port_u[0].last <= 'b0;
            port_u[1].data <= 'b0;
            port_u[1].vld  <= 'b0;
            port_u[1].last <= 'b0;

            port_z[0].data <= 'b0;
            port_z[0].vld  <= 'b0;
            port_z[0].last <= 'b0;
            port_z[1].data <= 'b0;
            port_z[1].vld  <= 'b0;
            port_z[1].last <= 'b0;


        end else begin


            // would have been best to pass it to a task 
            // call it repeatedly. but axis_if as a datatype is 
            // not supported in task unless axis_if is virtual


            port_p[0].data <= p.data;
            port_p[1].data <= p.data;
            if (!sel_p) begin
                port_p[1].vld  <= 0;
                port_p[1].last <= 0;
                port_p[0].vld  <= p.vld;
                port_p[0].last <= p.last;
                sel_p          <= p.vld & p.last;
                p.rdy          <= port_p[0].rdy;
            end else begin
                port_p[0].vld  <= 0;
                port_p[0].last <= 0;
                port_p[1].vld  <= p.vld;
                port_p[1].last <= p.last;
                sel_p          <= !(p.vld & p.last);
                p.rdy          <= port_p[1].rdy;
            end 
            
            port_u[0].data <= u.data;
            port_u[1].data <= u.data;
            
            if (!sel_u) begin
              port_u[1].vld  <= 0;
              port_u[1].last <= 0;
              port_u[0].vld  <= u.vld;
              port_u[0].last <= u.last;
              sel_u          <= (u.vld & u.last);
              u.rdy          <= port_u[0].rdy;
            end else begin
              port_u[0].vld  <= 0;
              port_u[0].last <= 0;
              port_u[1].vld  <=   u.vld;
              port_u[1].last <=   u.last;
              sel_u          <= !(u.vld & u.last);
              u.rdy          <=   port_u[1].rdy;
            end 
            

            if (!sel_z) begin
                z.data <= port_z[0].data;
                z.vld  <= port_z[0].vld;
                z.last <= port_z[0].last;
                port_z[0].rdy <=  z.rdy;
                sel_z <= port_z[0].vld & port_z[0].last;
            end else begin
                z.data <= port_z[1].data;
                z.vld  <= port_z[1].vld;
                z.last <= port_z[1].last;
                port_z[1].rdy <= z.rdy;
                sel_z <= !(port_z[1].vld & port_z[1].last);
            end
            
            
        end
    end



endmodule
