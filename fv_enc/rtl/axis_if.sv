`timescale 1ns/10ps
interface axis_if #(parameter int DW =4);

    logic  vld;
    logic  last;
    logic [DW-1:0] data;
    logic  rdy;

  modport in ( input vld, data, last,     output rdy);
  modport out ( output vld, data, last,   input rdy);

endinterface : axis_if
