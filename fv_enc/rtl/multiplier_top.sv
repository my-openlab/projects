module multiplier_top #(parameter int N = 16,    // Length of the input sequences
              int QW = 64,   // Bit-width of each input sample
              int UW = 1   // Bit-width of each input sample
  ) (
  // Synchronous system
  input logic  clk,
  input logic  s_rst_n, // synchronous reset, active low

  // AXI stream interface. 1 coefficient of p per cycle.
  input logic  p_vld,
  output logic  p_rdy,
  input logic [QW-1:0] p,
  input logic  p_last,

  // AXI stream interface. 1 coefficient of u per cycle.
  input logic  u_vld,
  output logic  u_rdy,
  input logic [UW-1:0] u,
  input logic  u_last,

  // AXI stream interface. 1 coefficient of the result z per cycle.
  output logic  z_vld,
  input logic  z_rdy, // ignored, design expects recieving ip to be always ready
  output logic [QW-1:0] z,
  output logic  z_last
);


logic  sel_p_vld[2];
logic   sel_p_rdy[2];
logic [QW-1:0] sel_p_data[2];
logic   sel_p_last[2];

// AXI stream interface. 1 coefficient of u per cycle.
logic  sel_u_vld[2];
logic  sel_u_rdy[2];
logic [UW-1:0] sel_u_data[2];
logic sel_u_last[2];

// AXI stream interface. 1 coefficient of the result z per cycle.
logic  sel_z_vld[2];
logic  sel_z_rdy[2]; // ignored, design expects recieving ip to be always ready
logic  sel_z_last[2];
logic [QW-1:0] sel_z_data[2];
logic p_port, u_port;
logic out_port;

    generate
        for (genvar idx=0; idx < 2; idx++) begin : gen_mult

            multiplier #(.N(N), .QW(QW), .UW(UW)) multiplier_inst (
                .clk(clk),
                .s_rst_n(s_rst_n),
                .p_vld(sel_p_vld[idx]),
                .p_rdy(sel_p_rdy[idx]),
                .p(sel_p_data[idx]),
                .p_last(sel_p_last[idx]),
                .u_vld(sel_u_vld[idx]),
                .u_rdy(sel_u_rdy[idx]),
                .u(sel_u_data[idx]),
                .u_last(sel_u_last[idx]),
                .z_vld(sel_z_vld[idx]),
                .z_rdy(sel_z_rdy[idx]), // Ignored
                .z(sel_z_data[idx]),
                .z_last(sel_z_last[idx])
            );
        end : gen_mult
    endgenerate

// naive implementation of axis switch
    always_ff @(posedge clk ) begin
        if (!s_rst_n) begin
            p_port <= 0; // initially, data fed into is connected to multiolier 0
            u_port<= 0;  // initially, data fed into is connected to multiolier 0
            out_port <= 1; // initially, output is connected to multiolier 1
            sel_p_data <= '{default:'b0};
            sel_p_vld  <= '{default:'b0};
            p_rdy <= 'b0;
            sel_p_last <= '{default:'b0};

            sel_u_data <= '{default:'b0};
            sel_u_vld  <= '{default:'b0};
            u_rdy <= 'b0;
            sel_u_last <= '{default:'b0};
            
            z <= 'b0;
            z_vld  <= 'b0;
            z_last <= 'b0;
            sel_z_rdy <= '{default:'b0};
            
        end else begin
        
            if (p_vld & p_last)
                p_port <= !p_port;

            sel_p_data <= {p,p};
            sel_p_vld  <= {(!p_port) & p_vld,(p_port) & p_vld};
            p_rdy <=  {((!p_port) & sel_p_rdy[0]),((p_port) & sel_p_rdy[1])};
            sel_p_last <= {(!p_port) & p_last,(p_port) & p_last};

            if (u_vld & u_last)
                u_port <= !u_port;

            sel_u_data <= {u,u};
            sel_u_vld  <= {(!u_port) & u_vld,(u_port) & u_vld};
            u_rdy <=  {(!u_port) & sel_u_rdy[0],(u_port) & sel_u_rdy[1]};
            sel_u_last <= {(!u_port) & u_last,(u_port) & u_last};

            if (sel_z_vld[0] & sel_z_last[0])
                out_port <= !out_port;

            if (out_port==1) begin
                z <= sel_z_data[0];
                z_vld  <= sel_z_vld[0];
                z_last <= sel_z_last[0];
            end else begin
                z <= sel_z_data[1];
                z_vld  <= sel_z_vld[1];
                z_last <= sel_z_last[1];
            end

            sel_z_rdy <=  {(!out_port) & z_rdy,(out_port) & z_rdy};

        end
    end



endmodule
