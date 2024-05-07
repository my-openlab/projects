`timescale 1ns/1ps

module axis2mem #(
    parameter int DW = 32,     // Width of the data bus
    parameter int ADDR_W = 10,  // Address width for the memory
    parameter int DEPTH = 16
)(
    input logic clk,
    input logic s_rst_n,

    // AXI Stream interface
    axis_if.in stream_in,

);

// Internal registers
logic [ADDR_W-1:0] waddr;

(*ram_style = "block" *) logic [DW-1:0] memory[DEPTH];

// Control logic for receiving data and writing to memory
always @(posedge clk) begin
    if (!s_rst_n) begin
        waddr <= 0;
        stream_in.rdy <= 1'b0;
        mem_write <= 1'b0;
        
    end else begin
        // Always ready to receive data
        stream_in.rdy <= 1'b1;
        mem_write <= 1'b0;  // Default to not writing

        // Write data to memory when valid data is available
        if (stream_in.vld && stream_in.rdy) begin
            memory[waddr]<= stream_in.data;

            // Increment memory address pointer
            if (!stream_in.last) begin
                waddr <= waddr + 1;
            end else begin
                waddr <= 0;  // Reset pointer at the end of a frame
            end
        end
    end
end

endmodule