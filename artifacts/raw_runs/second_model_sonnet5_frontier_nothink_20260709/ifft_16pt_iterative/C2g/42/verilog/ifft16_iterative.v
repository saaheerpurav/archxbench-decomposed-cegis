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
    output done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOGN  = 4; // log2(16)

    // Internal storage, wide enough to avoid overflow through stages
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // Twiddle ROM (Q1.15), k = 0..8
    function signed [COEFF_W-1:0] cos_lut;
        input [3:0] k;
        begin
            case (k)
                4'd0: cos_lut =  16'sd32767;
                4'd1: cos_lut =  16'sd30274;
                4'd2: cos_lut =  16'sd23170;
                4'd3: cos_lut =  16'sd12540;
                4'd4: cos_lut =  16'sd0;
                4'd5: cos_lut = -16'sd12540;
                4'd6: cos_lut = -16'sd23170;
                4'd7: cos_lut = -16'sd30274;
                4'd8: cos_lut = -16'sd32768;
                default: cos_lut = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] sin_lut;
        input [3:0] k;
        begin
            case (k)
                4'd0: sin_lut =  16'sd0;
                4'd1: sin_lut =  16'sd12540;
                4'd2: sin_lut =  16'sd23170;
                4'd3: sin_lut =  16'sd30274;
                4'd4: sin_lut =  16'sd32767;
                4'd5: sin_lut =  16'sd30274;
                4'd6: sin_lut =  16'sd23170;
                4'd7: sin_lut =  16'sd12540;
                4'd8: sin_lut =  16'sd0;
                default: sin_lut = 16'sd0;
            endcase
        end
    endfunction

    // Bit reversal for 4 bits
    function [3:0] bitrev4;
        input [3:0] x;
        begin
            bitrev4 = {x[0], x[1], x[2], x[3]};
        end
    endfunction

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_STAGE  = 3'd2;
    localparam S_SCALE  = 3'd3;
    localparam S_DONE   = 3'd4;

    reg [2:0] state;
    reg [1:0] stage_cnt;   // 0..3
    reg [2:0] bfly_cnt;    // 0..7 (half=8 max at stage0? actually half doubles)
    reg [3:0] scale_idx;

    integer half, group_size, num_groups, twstep;
    integer p_idx, q_idx, tw_idx;
    integer base, j;

    reg signed [COEFF_W-1:0] c_val, s_val;
    reg signed [OUT_W-1:0]   xp_re, xp_im, xq_re, xq_im;
    reg signed [OUT_W+COEFF_W-1:0] mult_rr, mult_ii, mult_ri, mult_ir;
    reg signed [OUT_W+COEFF_W:0]   sum_tr, sum_ti;
    reg signed [OUT_W-1:0] tr_val, ti_val;

    assign done = (state == S_DONE);

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    // Compute indices combinationally based on stage_cnt and bfly_cnt
    always @(*) begin
        half = 1 << stage_cnt;             // 1,2,4,8
        group_size = half << 1;            // 2,4,8,16
        num_groups = N / group_size;
        twstep = (N/2) / half;             // step multiplier for twiddle index

        // decompose bfly_cnt (0..7) into group index and j index
        // total butterflies per stage = N/2 = 8
        base = (bfly_cnt / half) * group_size;
        j    = bfly_cnt % half;

        p_idx = base + j;
        q_idx = base + j + half;
        tw_idx = j * twstep;
    end

    always @(*) begin
        c_val = cos_lut(tw_idx[3:0]);
        s_val = sin_lut(tw_idx[3:0]);
    end

    always @(*) begin
        xp_re = mem_real[p_idx];
        xp_im = mem_imag[p_idx];
        xq_re = mem_real[q_idx];
        xq_im = mem_imag[q_idx];

        mult_rr = xq_re * c_val;
        mult_ii = xq_im * s_val;
        mult_ri = xq_re * s_val;
        mult_ir = xq_im * c_val;

        sum_tr = mult_rr - mult_ii + (1 <<< 14);
        sum_ti = mult_ri + mult_ir + (1 <<< 14);

        tr_val = sum_tr >>> 15;
        ti_val = sum_ti >>> 15;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage_cnt <= 0;
            bfly_cnt <= 0;
            scale_idx <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // bit-reversal load
                    // handled combinationally below via separate block, just transition
                    stage_cnt <= 0;
                    bfly_cnt  <= 0;
                    state <= S_STAGE;
                end

                S_STAGE: begin
                    // perform butterfly update for current p_idx,q_idx
                    mem_real[p_idx] <= xp_re + tr_val;
                    mem_imag[p_idx] <= xp_im + ti_val;
                    mem_real[q_idx] <= xp_re - tr_val;
                    mem_imag[q_idx] <= xp_im - ti_val;

                    if (bfly_cnt == (N/2 - 1)) begin
                        bfly_cnt <= 0;
                        if (stage_cnt == LOGN - 1) begin
                            stage_cnt <= 0;
                            scale_idx <= 0;
                            state <= S_SCALE;
                        end else begin
                            stage_cnt <= stage_cnt + 1;
                        end
                    end else begin
                        bfly_cnt <= bfly_cnt + 1;
                    end
                end

                S_SCALE: begin
                    mem_real[scale_idx] <= mem_real[scale_idx] >>> 4;
                    mem_imag[scale_idx] <= mem_imag[scale_idx] >>> 4;
                    if (scale_idx == N-1) begin
                        state <= S_DONE;
                    end else begin
                        scale_idx <= scale_idx + 1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // Separate load process: on entering S_LOAD from S_IDLE, load bit-reversed inputs
    integer li;
    reg prev_idle;
    always @(posedge clk) begin
        if (rst) begin
            prev_idle <= 1'b1;
        end else begin
            prev_idle <= (state == S_IDLE);
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (li = 0; li < N; li = li + 1) begin
                mem_real[li] <= {OUT_W{1'b0}};
                mem_imag[li] <= {OUT_W{1'b0}};
            end
        end else if (state == S_IDLE && start) begin
            for (li = 0; li < N; li = li + 1) begin
                mem_real[bitrev4(li[3:0])] <= { {GAIN_W{data_real_in[li][DATA_W-1]}}, data_real_in[li] };
                mem_imag[bitrev4(li[3:0])] <= { {GAIN_W{data_imag_in[li][DATA_W-1]}}, data_imag_in[li] };
            end
        end
    end

endmodule