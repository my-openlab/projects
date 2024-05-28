module axis_fifo_wrapper #
(
    // FIFO depth in words
    // KEEP_W words per cycle if KEEP_EN set
    // Rounded up to nearest power of 2 cycles
    parameter int DEPTH = 8,
    // Width of AXI stream interfaces in bits
    parameter int DATA_W = 8,
    // tkeep signal width (words per cycle)
    parameter int KEEP_W = ((DATA_W+7)/8),
    parameter int ID_EN = 0,// tid signal present
    parameter int ID_W = 8,// tid signal width
    parameter int DST_EN = 0,// tdest signal present
    parameter int DST_W = 8,// tdest signal width
    parameter int USR_EN = 0,// tuser signal present
    parameter int USR_W = 1,// tuser signal width
    parameter int RAM_PIPELINE = 1// number of RAM pipeline registers

)
(
    input  logic                   clk,
    input  logic                   srst_n,


    /*
     * AXI input
     */
     input  logic [DATA_W-1:0]  s_axis_tdata,
     input  logic [KEEP_W-1:0]  s_axis_tkeep,
     input  logic               s_axis_tlast,
     input  logic              s_axis_tvalid,
     output logic              s_axis_tready,
     input  logic [ID_W-1:0]    s_axis_tid,
     input  logic [DST_W-1:0]  s_axis_tdest,
     input  logic [USR_W-1:0]  s_axis_tuser,
     /*
      * AXI output
      */
     output logic [DATA_W-1:0]  m_axis_tdata,
     output logic [KEEP_W-1:0]  m_axis_tkeep,
     output logic                   m_axis_tlast,
     output logic                   m_axis_tvalid,
     input  logic                   m_axis_tready,
     output logic [ID_W-1:0]    m_axis_tid,
     output logic [DST_W-1:0]  m_axis_tdest,
     output logic [USR_W-1:0]  m_axis_tuser,

    /*
     * Pause
     */
    input  logic                   pause_req,
    output logic                   pause_ack,

    /*
     * Status
     */
    output logic [$clog2(DEPTH)-1:0] stat_depth,
    output logic [$clog2(DEPTH)-1:0] stat_depth_commit,
    output logic                   stat_overflow,
    output logic                   stat_bad_frame,
    output logic                   stat_good_frame
);



axis_full_if #(.DATA_W(DATA_W),.ID_W(ID_W),.DST_W(DST_W),.USR_W(USR_W)) s_axis_int();
axis_full_if #(.DATA_W(DATA_W),.ID_W(ID_W),.DST_W(DST_W),.USR_W(USR_W)) m_axis_int();

always_comb begin
/* AXI input */
  s_axis_int.tdata  = s_axis_tdata;
  s_axis_int.tkeep  = s_axis_tkeep;
  s_axis_int.tlast  = s_axis_tlast;
  s_axis_int.tvalid = s_axis_tvalid;

  s_axis_int.tid    = s_axis_tid;
  s_axis_int.tdest  = s_axis_tdest;
  s_axis_int.tuser  = s_axis_tuser;

  s_axis_tready    = s_axis_int.tready;

/* AXI output */
  m_axis_tdata  = m_axis_int.tdata ;
  m_axis_tkeep  = m_axis_int.tkeep ;
  m_axis_tlast  = m_axis_int.tlast ;
  m_axis_tvalid = m_axis_int.tvalid;
  m_axis_tid    = m_axis_int.tid;
  m_axis_tdest  = m_axis_int.tdest;
  m_axis_tuser  = m_axis_int.tuser;
  m_axis_int.tready = m_axis_tready;
end

axis_fifo #
(
    .DEPTH(DEPTH),
    .DATA_W(DATA_W),
    .KEEP_W(KEEP_W),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DST_EN(DST_EN),
    .DST_W(DST_W),
    .USR_EN(USR_EN),
    .USR_W(USR_W),
    .RAM_PIPELINE(RAM_PIPELINE)

) axis_fifo_inst( .s_axis(s_axis_int), .m_axis(m_axis_int),.* );

endmodule: axis_fifo_wrapper