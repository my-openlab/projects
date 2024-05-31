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
    input  logic                   clk,
    input  logic                   srst_n,

    axis_full_if.in  s_axis,// AXI input
    axis_full_if.out m_axis, // AXI output, once maxis.ready=1 cannot be low without sampling atleast one m_axis.tdata

    input  logic                   pause_req, // Pause
    output logic                   pause_ack,

    output logic [$clog2(DEPTH)-1:0] stat_depth,  // Status
    output logic [$clog2(DEPTH)-1:0] stat_depth_commit,
    output logic                   stat_overflow,
    output logic                   stat_bad_frame,
    output logic                   stat_good_frame
);

localparam int AddrWidth = $clog2(DEPTH);
localparam int DataOffset = DATA_W;
localparam int LastOffset = DataOffset + 1;
localparam int KeepOffset = LastOffset + KEEP_W;

localparam int  IdOffset =  ID_EN ? KeepOffset +  ID_W : KeepOffset;
localparam int DstOffset = DST_EN ? IdOffset   + DST_W : IdOffset;
localparam int UsrOffset = USR_EN ? DstOffset  + USR_W : DstOffset;

localparam int FifoWordWidth = UsrOffset;


logic [FifoWordWidth-1:0] outdata_r; // final value that goes out of last fifo

logic [FifoWordWidth-1:0] axis_wr_word_c;
logic [FifoWordWidth-1:0] rd_word_c, rd_word_r[2];
logic [AddrWidth:0] wr_addr_r, rd_addr_r; // sync FIFO rd/wr ptrs
logic full;
logic empty,empty_r;
logic wren, rden;
logic rden_r, pp_rden_r;
logic rd_word0_valid, rd_word1_valid;


// main input fifo
syncfifo #(.DEPTH(DEPTH), .DATA_W(FifoWordWidth)) ififo_inst(   .rdata(rd_word_c),
                                                                .wdata(axis_wr_word_c),
                                                                .full,
                                                                .empty,
                                                                .clk,
                                                                .srst_n,
                                                                .rden,
                                                                .wren,
                                                                .stat_depth,
                                                                .almost_full());


assign s_axis.tready = !full; // ready to recieve as long as the fifo is not full

assign wren = !full && s_axis.tvalid; // write, if tvalid is high and fifo is not full

assign rden = !empty && m_axis.tready; // read, if sink is ready to recieve

always_ff @(posedge clk ) begin
    rden_r <= rden;
    empty_r <= empty;

    if (m_axis.tready) begin
        {outdata_r, rd_word_r[0]} <= {rd_word_r[0], rd_word_c};
        rd_word0_valid <= rden_r && !empty;
        m_axis.tvalid <= rden_r;

        if (rd_word1_valid) begin
           outdata_r <= rd_word_r[1];
           m_axis.tvalid <= 1'b1;
           rd_word1_valid <= 1'b0;
        end else begin
          outdata_r <= rd_word_c;
        end

    end else if ((!rden && rden_r) || (rd_word_c[8] && !empty_r && empty)) begin
            rd_word_r[1] <= rd_word_c;
            rd_word1_valid <= 1'b1;
    end

    if (m_axis.tready && m_axis.tvalid)
        m_axis.tvalid <= |{rd_word0_valid, rden_r};

    if (!srst_n) begin
        rden_r <= 1'b0;
        empty_r <= 1'b0;
        rd_word_r <= '{default:'b0};
        m_axis.tvalid <= 1'b0;
        rd_word0_valid <= 1'b0;
        rd_word1_valid <= 1'b0;
    end
end



always_comb begin
    axis_wr_word_c[DataOffset-1:0] = s_axis.tdata;
    axis_wr_word_c[LastOffset-1] = s_axis.tlast;
    axis_wr_word_c[KeepOffset-1:LastOffset] = s_axis.tkeep;
    axis_wr_word_c[IdOffset-1:KeepOffset] =  s_axis.tid ;
    axis_wr_word_c[DstOffset-1:IdOffset]  = s_axis.tdest;
    axis_wr_word_c[UsrOffset-1:DstOffset] = s_axis.tuser;

    m_axis.tdata = outdata_r[DataOffset-1:0];
    m_axis.tlast = outdata_r[LastOffset-1];
    m_axis.tkeep = outdata_r[KeepOffset-1:LastOffset];
    m_axis.tid   = outdata_r[IdOffset-1:KeepOffset];
    m_axis.tdest = outdata_r[DstOffset-1:IdOffset];
    m_axis.tuser = outdata_r[UsrOffset-1:DstOffset];
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
    output logic     almost_full,
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

    if (!empty && rden) begin
        rd_addr_r <= rd_addr_r + 1;
    end

    rdata <= mem[rd_addr_r[AddrWidth-1:0]];

    if (!srst_n) begin
        wr_addr_r <='b0;
        rd_addr_r <= 'b0;
    end
end


assign stat_depth = wr_addr_r - rd_addr_r;
assign almost_full = ((DEPTH -1 - stat_depth ) ==0);

    // empty when pointers match exactly
assign empty = (wr_addr_r == rd_addr_r);
// full when first MSB different but rest same
assign full = (wr_addr_r == {~rd_addr_r[AddrWidth], rd_addr_r[AddrWidth-1:0]}) ;

endmodule
