module ifft16_iterative #(
    parameter N = 16,
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W = 4
) (
    input clk,
    input rst,
    input start,
    input mode, // 0: FFT, 1: IFFT
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output reg done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam WORK_W = OUT_W + 4; // extra guard bits for internal accumulation
    localparam LOG2N = 4;

    // Base twiddle table (k=0..8), Q1.15
    function signed [COEFF_W-1:0] base_cos;
        input [3:0] k;
        begin
            case (k)
                4'd0: base_cos =  16'sd32767;
                4'd1: base_cos =  16'sd30274;
                4'd2: base_cos =  16'sd23170;
                4'd3: base_cos =  16'sd12540;
                4'd4: base_cos =  16'sd0;
                4'd5: base_cos = -16'sd12540;
                4'd6: base_cos = -16'sd23170;
                4'd7: base_cos = -16'sd30274;
                4'd8: base_cos = -16'sd32768;
                default: base_cos = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] base_sin;
        input [3:0] k;
        begin
            case (k)
                4'd0: base_sin =  16'sd0;
                4'd1: base_sin =  16'sd12540;
                4'd2: base_sin =  16'sd23170;
                4'd3: base_sin =  16'sd30274;
                4'd4: base_sin =  16'sd32767;
                4'd5: base_sin =  16'sd30274;
                4'd6: base_sin =  16'sd23170;
                4'd7: base_sin =  16'sd12540;
                4'd8: base_sin =  16'sd0;
                default: base_sin = 16'sd0;
            endcase
        end
    endfunction

    // Full 16-entry table lookup (extends via symmetry: k+8 -> -cos,-sin)
    function signed [COEFF_W-1:0] full_cos;
        input [4:0] k_in; // 0..15
        reg [3:0] k;
        begin
            k = k_in[3:0];
            if (k <= 8)
                full_cos = base_cos(k);
            else
                full_cos = -base_cos(k - 8);
        end
    endfunction

    function signed [COEFF_W-1:0] full_sin;
        input [4:0] k_in;
        reg [3:0] k;
        begin
            k = k_in[3:0];
            if (k <= 8)
                full_sin = base_sin(k);
            else
                full_sin = -base_sin(k - 8);
        end
    endfunction

    // bit reversal for 4 bits
    function [3:0] bitrev4;
        input [3:0] x;
        begin
            bitrev4 = {x[0], x[1], x[2], x[3]};
        end
    endfunction

    // Internal working registers
    reg signed [WORK_W-1:0] xr [0:N-1];
    reg signed [WORK_W-1:0] xi [0:N-1];

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_STAGE  = 3'd2;
    localparam S_SCALE  = 3'd3;
    localparam S_DONE   = 3'd4;

    reg [2:0] state;
    reg [1:0] stage;      // 0..3
    reg [3:0] bfly;       // 0..7 butterfly index within a stage
    reg [4:0] out_idx;    // for scale loop

    integer i;

    // Butterfly computation wires
    reg [4:0] half_size;   // size of half-group = 2^stage
    reg [4:0] group_size;  // full group = 2^(stage+1)
    reg [4:0] group_start;
    reg [4:0] j_in_half;
    reg [4:0] p_idx, q_idx;
    reg [4:0] tw_idx;

    reg signed [COEFF_W-1:0] cos_v, sin_v;

    reg signed [WORK_W+COEFF_W-1:0] mul_rr, mul_ii, mul_ri, mul_ir;
    reg signed [WORK_W-1:0] tr, ti;
    reg signed [WORK_W-1:0] p_re, p_im, q_re, q_im;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done  <= 1'b0;
            stage <= 2'd0;
            bfly  <= 4'd0;
            out_idx <= 5'd0;
            for (i = 0; i < N; i = i + 1) begin
                xr[i] <= {WORK_W{1'b0}};
                xi[i] <= {WORK_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Load with bit-reversal permutation
                        for (i = 0; i < N; i = i + 1) begin
                            xr[bitrev4(i[3:0])] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            xi[bitrev4(i[3:0])] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        bfly  <= 4'd0;
                        state <= S_STAGE;
                    end
                end

                S_STAGE: begin
                    // Compute butterfly for current stage/bfly
                    // half_size = 2^stage, group_size = 2^(stage+1)
                    // number of groups = N / group_size
                    // bfly indexes 0..(N/2 -1) total butterflies per stage
                    // group index = bfly / half_size, j_in_half = bfly % half_size
                    half_size  = (5'd1 << stage);
                    group_size = (5'd1 << (stage + 1));
                    group_start = (bfly / half_size) * group_size;
                    j_in_half = bfly % half_size;
                    p_idx = group_start + j_in_half;
                    q_idx = p_idx + half_size;
                    // twiddle index = j_in_half * (N / group_size) mod N
                    tw_idx = (j_in_half * (N / group_size)) % N;

                    cos_v = full_cos(tw_idx[4:0]);
                    sin_v = full_sin(tw_idx[4:0]); // IFFT convention already (conjugated table matches spec's IFFT eq)

                    mul_rr = xr[q_idx] * cos_v;
                    mul_ii = xi[q_idx] * sin_v;
                    mul_ri = xr[q_idx] * sin_v;
                    mul_ir = xi[q_idx] * cos_v;

                    tr = (mul_rr - mul_ii + (1 <<< 14)) >>> 15;
                    ti = (mul_ri + mul_ir + (1 <<< 14)) >>> 15;

                    p_re = xr[p_idx];
                    p_im = xi[p_idx];
                    q_re = xr[q_idx];
                    q_im = xi[q_idx];

                    xr[p_idx] <= p_re + tr;
                    xi[p_idx] <= p_im + ti;
                    xr[q_idx] <= p_re - tr;
                    xi[q_idx] <= p_im - ti;

                    if (bfly == (N/2 - 1)) begin
                        bfly <= 4'd0;
                        if (stage == LOG2N - 1) begin
                            state <= S_SCALE;
                            out_idx <= 5'd0;
                        end else begin
                            stage <= stage + 1;
                        end
                    end else begin
                        bfly <= bfly + 1;
                    end
                end

                S_SCALE: begin
                    // divide by N (shift right by log2(N)=4), applied combinationally at output read
                    state <= S_DONE;
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        // allow restart
                        for (i = 0; i < N; i = i + 1) begin
                            xr[bitrev4(i[3:0])] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            xi[bitrev4(i[3:0])] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        bfly  <= 4'd0;
                        done  <= 1'b0;
                        state <= S_STAGE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_GEN
            wire signed [WORK_W-1:0] scaled_r;
            wire signed [WORK_W-1:0] scaled_i;
            assign scaled_r = xr[gi] >>> 4;
            assign scaled_i = xi[gi] >>> 4;
            assign data_real_out[gi] = scaled_r[OUT_W-1:0];
            assign data_imag_out[gi] = scaled_i[OUT_W-1:0];
        end
    endgenerate

endmodule