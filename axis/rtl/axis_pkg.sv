package axis_pkg;
    localparam int DataW=64;
    localparam int KeepW=DataW/8;
    localparam int IdW=8;
    localparam int DstW=8;
    localparam int UsrW=1;

    typedef struct packed{
        logic tready;
        logic tvalid;
        logic [DataW-1:0] tdata;
        logic [KeepW-1:0] tkeep;
        logic tlast;
        logic [IdW-1:0] tid;
        logic [DstW-1:0] tdest;
        logic [UsrW-1:0] tuser;
    } axis_t;

endpackage: axis_pkg