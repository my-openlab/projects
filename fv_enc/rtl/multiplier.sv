/*
Direct implementation of polynomial multiplication. 
where the coeff stream 'u' being in R2
and the 'P' is in Rq
  here : 
    Q = 2^QW
    N = Number of coeffs per polynomial
    UW = u coeff width
    
    Thus data is streamed in 'N' clock cycles
    The calculated multiplication result is streamed out in N Clock cycles
  The total latency from getting the last Coeff to getting the last multiplied result is 'N' clocks

  The design has only been synthesized(**lack of time**) only multiiplier  for synthesizability only.

*/
module multiplier #(parameter int N = 4,    // Length of the input sequences
              int QW = 5,   // Bit-width of each input sample
              int UW = 1   // Bit-width of each input sample
  ) (
  // Synchronous system
  input logic  clk,
  input logic  s_rst_n, // synchronous reset, active low

  // AXI stream interfaces. coeffs streamed 1 coeff/clk cycle
  axis_if.in p,
  axis_if.in u,
  axis_if.out z // output starts streaming after the last coeff in
);

  localparam int CoeffCntBitW = $clog2(N);
  // localparam Qmodulo = 2**QW -1; // to count upto 2N-1

  // local signals
  // convention: _r: registered, _c: combinational

  logic [CoeffCntBitW + 1-1:0] coeff_cnt_r, coeff_cnt_c;
  logic [N-1:0] start_calc_r, start_calc_c; // signals to start partial prod calculations
  logic z_vld_c;
  logic z_last_c;
  logic rdy_c; // common rdy for p,u interface

  // memory array  to hold incoming coeffs
  logic [QW-1:0] p_coeff_r[N],p_c;
  logic [UW-1:0] u_coeff_r[N],u_c;
  
  // registers for calculating partial products
  logic [QW-1:0] temp_r[N], temp_c[N];

  // Define states
  typedef enum logic [1:0] { ST_RESET, ST_PP_CALC, ST_OSTREAM } state_t;

  // State variables
  state_t current_state_r, next_state_c;

  // State machine: state transition logic
  always_ff @(posedge clk ) begin
    if (!s_rst_n) begin
      current_state_r <= ST_RESET;  // Default state after reset
      coeff_cnt_r <= 0;
      start_calc_r <='b0;
      temp_r <= '{default:'b0};
      p_coeff_r <= '{default:'b0};
      u_coeff_r <= '{default:'b0};
      z.vld <= 0;
      z.last <= 0;
      u.rdy <= 0;
      p.rdy <= 0;
      z.data <= 0;

    end else begin
      coeff_cnt_r <= coeff_cnt_c;
      current_state_r <= next_state_c; // Transition to the next state

      // store in memory
      p_coeff_r[coeff_cnt_r] <= p_c;
      u_coeff_r[coeff_cnt_r] <= u_c;

      temp_r <= temp_c;
      u.rdy <= rdy_c;
      p.rdy <= rdy_c;
      z.data <= temp_c[coeff_cnt_r & (N-1)];
      z.vld <= z_vld_c;
      z.last <= z_last_c;
      start_calc_r <= start_calc_c;

    end
  end

  // Next state logic based on current state and counters
  always_comb begin

    // defaults 
//    start_calc_c = start_calc_r;
    next_state_c = current_state_r;
    coeff_cnt_c = 0;
    p_c = p.data;
    u_c = u.data;
    z_vld_c = 0;
    z_last_c = 0;
    rdy_c = 0;

    case (current_state_r)

      ST_RESET: begin
        next_state_c = ST_PP_CALC;
        start_calc_c = 'b0;
        rdy_c = 1;
      end

      ST_PP_CALC: begin
        rdy_c = 1;
        if (p.vld && u.vld) begin
            coeff_cnt_c = coeff_cnt_r +1; //

            start_calc_c[coeff_cnt_r] = 1; // start the calculation of partial products one-by-one

            if (p.last || u.last) begin
                assert (coeff_cnt_c == N) else $display("ERROR: N coefficients not recieved");
                rdy_c = 0;
                next_state_c = ST_OSTREAM;
            end

        end

      end

      ST_OSTREAM: begin // calculate the remaining partial products
        coeff_cnt_c = coeff_cnt_r +1;
        rdy_c = 0;
        start_calc_c[coeff_cnt_r-N] = 0; // stop the calculation of partial products
        z_vld_c = 1;

        if (coeff_cnt_r == 2*N-1) begin
          coeff_cnt_c = 0;
          z_last_c = 1;
          rdy_c = 1;
          next_state_c = ST_PP_CALC;  // Safe state
        end

      end

      default: begin
        assert (0) else $display("ERROR: Invalid state reached");
        next_state_c = ST_RESET;  // Safe state, should never occur
      end

    endcase
  end


  generate 
    for (genvar idx=0; idx < N; idx++) begin : coeff_calc
      logic [CoeffCntBitW-1:0] p_idx, u_idx;
      always_comb  begin

        temp_c[idx] = temp_r[idx];

        if (start_calc_r[idx]) begin
          p_idx = (coeff_cnt_r-1) & (N-1);
          u_idx = (coeff_cnt_r-1-idx) & (N-1);

          if (u_idx < idx+1)
            temp_c[idx] = (temp_r[idx] + u_coeff_r[u_idx] * p_coeff_r[p_idx]);// & Qmodulo;
          else
            temp_c[idx] = (temp_r[idx] - u_coeff_r[u_idx] * p_coeff_r[p_idx]);// & Qmodulo;
        end

      end

    end : coeff_calc
  endgenerate



endmodule
