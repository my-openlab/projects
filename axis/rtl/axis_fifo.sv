module axis_fifo #
(
    parameter int DEPTH = 8,// FIFO depth in words
    parameter int DATA_W = 8,// Width of AXI stream interfaces in bits
    parameter int KEEP_W = ((DATA_W+7)/8),// tkeep signal width (words per cycle)
    parameter int ID_EN = 0,// tid signal present
    parameter int ID_W = 8,// tid signal width
    parameter int DST_EN = 0,// tdest signal present
    parameter int DST_W = 8,// tdest signal width
    parameter int USR_EN = 0,// tuser signal present
    parameter int USR_W = 1,// tuser signal width
    parameter int RAM_PIPELINE = 1// number of RAM pipeline registers

)
(
    input  wire                   clk,
    input  wire                   srst_n,

    axis_full_if.in  s_axis,// AXI input
    axis_full_if.out m_axis, // AXI output

    input  wire                   pause_req, // Pause
    output wire                   pause_ack,

    output wire [$clog2(DEPTH)-1:0] stat_depth,  // Status
    output wire [$clog2(DEPTH)-1:0] stat_depth_commit,
    output wire                   stat_overflow,
    output wire                   stat_bad_frame,
    output wire                   stat_good_frame
);

localparam int AddrWidth = $clog2(DEPTH);
localparam int DataOffset = DATA_W;
localparam int LastOffset = DataOffset + 1;
localparam int KeepOffset = LastOffset + KEEP_W;

localparam int  IdOffset =  ID_EN ? KeepOffset +  ID_W : KeepOffset;
localparam int DstOffset = DST_EN ? IdOffset   + DST_W : IdOffset;
localparam int UsrOffset = USR_EN ? DstOffset  + USR_W : DstOffset;

localparam int FifoWordWidth = UsrOffset;


logic [FifoWordWidth-1:0] outdata_c; // final value that goes out of last fifo

logic [FifoWordWidth-1:0] axis_wr_word_c,  axis_rd_word_c;
logic [AddrWidth:0] wr_addr_r, rd_addr_r; // sync FIFO rd/wr ptrs
logic full;
logic empty;
logic wren, rden;

// main input fifo
syncfifo #(.DEPTH(DEPTH), .DATA_W(FifoWordWidth)) ififo_inst(.rdata(axis_rd_word_c),
                                                     .wdata(axis_wr_word_c),
                                                     .full,
                                                     .empty,
                                                     .clk,
                                                     .srst_n,
                                                     .rden,
                                                     .wren,
                                                     .stat_depth);

assign wren = !full && s_axis.tready && s_axis.tvalid;
assign rden = !empty && ((RAM_PIPELINE>1) ? !pp_full: m_axis.tready);
assign s_axis.tready = !full;

always_ff @(posedge clk ) begin
    m_axis.tvalid <= (RAM_PIPELINE>1) ? pp_rden : rden;
    pp_wren_r <= pp_wren;
    if (!srst_n) begin
        m_axis.tvalid <= 1'b0;
    end
end


logic pp_full;
logic pp_empty;
logic pp_wren, pp_rden;
logic pp_wren_r;

logic [FifoWordWidth-1:0] pp_rd_word_c, pp_wr_word_c;

// output pipeline fifo
// this instance is for easing routing by adding extra output pipeline regs
syncfifo #(.DEPTH(RAM_PIPELINE), .DATA_W(FifoWordWidth)) ofifo_inst(.rdata(pp_rd_word_c),
                                                      .wdata(pp_wr_word_c),
                                                      .full(pp_full),
                                                      .empty(pp_empty),
                                                      .rden(pp_rden),
                                                      .wren(pp_wren_r),
                                                      .clk,
                                                      .srst_n,
                                                      .stat_depth()
                                                     );

assign pp_wren = !pp_full && !empty;
assign pp_rden = !pp_empty && m_axis.tready;
assign pp_wr_word_c = axis_rd_word_c;

always_ff @(posedge clk ) begin
    pp_wren_r <= pp_wren;
    if (!srst_n) begin
        pp_wren_r <= 1'b0;
    end
end


always_comb begin
    axis_wr_word_c[DataOffset-1:0] = s_axis.tdata;
    axis_wr_word_c[LastOffset-1] = s_axis.tlast;
    axis_wr_word_c[KeepOffset-1:LastOffset] = s_axis.tkeep;
    axis_wr_word_c[IdOffset-1:KeepOffset] =  s_axis.tid ;
    axis_wr_word_c[DstOffset-1:IdOffset]  = s_axis.tdest;
    axis_wr_word_c[UsrOffset-1:DstOffset] = s_axis.tuser;

    outdata_c = (RAM_PIPELINE>1) ? pp_rd_word_c : axis_rd_word_c;
    m_axis.tdata = outdata_c[DataOffset-1:0];
    m_axis.tlast = outdata_c[LastOffset-1];
    m_axis.tkeep = outdata_c[KeepOffset-1:LastOffset];
    m_axis.tid   = outdata_c[IdOffset-1:KeepOffset];
    m_axis.tdest = outdata_c[DstOffset-1:IdOffset];
    m_axis.tuser = outdata_c[UsrOffset-1:DstOffset];
end

endmodule



module syncfifo #(parameter int DEPTH = 8, parameter int DATA_W = 8) (
    input  logic                   clk,
    input  logic                srst_n,
    input  logic                  rden,
    input  logic                  wren,
    input  logic [DATA_W-1:0]    wdata,
    output logic [DATA_W-1:0]    rdata,
    output logic     full,
    output logic     empty,
    output logic [$clog2(DEPTH)-1:0]    stat_depth

);
localparam int AddrWidth = $clog2(DEPTH);
logic [DATA_W-1:0] mem[DEPTH];

logic [AddrWidth+1-1:0] wr_addr_r, rd_addr_r; // sync FIFO rd/wr ptrs

always_ff @(posedge clk ) begin

    if (!full && wren) begin
        wr_addr_r <= wr_addr_r + 1;
        mem[wr_addr_r[AddrWidth-1:0]] <= wdata;
    end
    if (!srst_n) begin
        wr_addr_r <='b0;
    end
end

always_ff @(posedge clk ) begin

    rdata <= mem[rd_addr_r[AddrWidth-1:0]];

    if (!empty && rden) begin
        rd_addr_r <= rd_addr_r + 1;
    end
    if (!srst_n) begin
        rd_addr_r <= 'b0;
    end
end
always_ff @(posedge clk ) begin
    stat_depth <= wr_addr_r - rd_addr_r;
end
    // empty when pointers match exactly
assign empty = (wr_addr_r == rd_addr_r);
// full when first MSB different but rest same
assign full = (wr_addr_r == {~rd_addr_r[AddrWidth], rd_addr_r[AddrWidth-1:0]}) ;

endmodule