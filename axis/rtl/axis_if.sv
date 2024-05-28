`timescale 1ns/10ps

interface axis_full_if #(parameter int DATA_W=8, ID_W=1, DST_W=1, USR_W=1);

  logic [DATA_W-1:0] tdata;
  logic [(DATA_W+7)/8 -1:0] tkeep;
  logic tlast;
  logic tvalid;
  logic tready;

  logic [ID_W-1:0] tid;
  logic [DST_W-1:0] tdest;
  logic [USR_W-1:0] tuser;

  modport in ( input tdata, tkeep, tvalid, tlast, tid, tdest, tuser,  output tready);
  modport out ( output tdata, tkeep, tvalid, tlast, tid, tdest, tuser, input tready);

endinterface : axis_full_if

interface axis_if #(parameter int DATA_W=8);

  logic [DATA_W-1:0] tdata;
  logic [(DATA_W+7)/8 -1:0] tkeep;
  logic tlast;
  logic tvalid;
  logic tready;

  modport in ( input tdata, tkeep, tvalid, tlast,  output tready);
  modport out ( output tdata, tkeep, tvalid, tlast, input tready);

endinterface : axis_if
