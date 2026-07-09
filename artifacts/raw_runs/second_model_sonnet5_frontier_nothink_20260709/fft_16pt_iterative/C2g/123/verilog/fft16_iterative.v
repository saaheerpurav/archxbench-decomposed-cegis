module fft16_iterative #(
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
    localparam LOGN = 4; // log2(16)

    // Twiddle ROM: k = 0..8
    function signed [COEFF_W-1:0] cos_lut;
        input [3:0] k;
        begin
            case (k)
                4'd0: cos_lut = 16'sd32767;
                4'd1: cos_lut = 16'sd30274;
                4'd2: cos_lut = 16'sd23170;
                4'd3: cos_lut = 16'sd12540;
                4'd4: cos_lut = 16'sd0;
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
                4'd0: sin_lut = 16'sd0;
                4'd1: sin_lut = 16'sd12540;
                4'd2: sin_lut = 16'sd23170;
                4'd3: sin_lut = 16'sd30274;
                4'd4: sin_lut = 16'sd32767;
                4'd5: sin_lut = 16'sd30274;
                4'd6: sin_lut = 16'sd23170;
                4'd7: sin_lut = 16'sd12540;
                4'd8: sin_lut = 16'sd0;
                default: sin_lut = 16'sd0;
            endcase
        end
    endfunction

    // Get cos/sin for full twiddle index 0..15 using symmetry
    // cos(2pi*k/16) period 16, symmetric: k in 9..15 -> use k' = 16-k, cos same, sin negated
    function signed [COEFF_W-1:0] get_cos;
        input [4:0] k; // 0..15
        reg [3:0] kk;
        begin
            if (k <= 8) get_cos = cos_lut(k[3:0]);
            else begin
                kk = 16 - k;
                get_cos = cos_lut(kk);
            end
        end
    endfunction

    function signed [COEFF_W-1:0] get_sin;
        input [4:0] k; // 0..15
        reg [3:0] kk;
        begin
            if (k <= 8) get_sin = sin_lut(k[3:0]);
            else begin
                kk = 16 - k;
                get_sin = -sin_lut(kk);
            end
        end
    endfunction

    // Bit reversal for 4 bits
    function [3:0] bitrev4;
        input [3:0] x;
        begin
            bitrev4 = {x[0], x[1], x[2], x[3]};
        end
    endfunction

    // Working memory
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // FSM states
    localparam S_IDLE = 3'd0;
    localparam S_LOAD = 3'd1;
    localparam S_RUN  = 3'd2;
    localparam S_DONE = 3'd3;
    localparam S_SCALE = 3'd4;

    reg [2:0] state;
    reg [1:0] stage;     // 0..3
    reg [3:0] bfly_cnt;  // butterfly index within stage, 0..7
    reg mode_r;

    integer half, groupsize, group, pos, p_idx, q_idx;
    reg [4:0] tw_idx;
    reg [4:0] tw_step;

    reg signed [COEFF_W-1:0] c_val, s_val;
    reg signed [OUT_W-1:0] xr_p, xi_p, xr_q, xi_q;
    reg signed [OUT_W+COEFF_W-1:0] mul1, mul2, mul3, mul4;
    reg signed [OUT_W+COEFF_W:0] sum_r, sum_i;
    reg signed [OUT_W-1:0] tr_real, tr_imag;

    integer i;

    always @(*) begin
        half = 1 << stage;          // half-size of sub-block
        groupsize = 1 << (stage+1); // full block size
        group = bfly_cnt / half;
        pos = bfly_cnt % half;
        p_idx = group*groupsize + pos;
        q_idx = p_idx + half;
        tw_step = (1<<LOGN) / groupsize; // N / groupsize
        tw_idx = pos * tw_step;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            stage <= 0;
            bfly_cnt <= 0;
            mode_r <= 1'b0;
            for (i=0;i<N;i=i+1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        mode_r <= mode;
                        for (i=0;i<N;i=i+1) begin
                            mem_real[bitrev4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 0;
                        bfly_cnt <= 0;
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // one cycle delay to let mem load settle
                    state <= S_RUN;
                end

                S_RUN: begin
                    // compute twiddle values
                    c_val = get_cos(tw_idx);
                    if (mode_r)
                        s_val = get_sin(tw_idx); // conjugate: +sin used in imag formula flips sign net effect
                    else
                        s_val = get_sin(tw_idx);

                    xr_p = mem_real[p_idx];
                    xi_p = mem_imag[p_idx];
                    xr_q = mem_real[q_idx];
                    xi_q = mem_imag[q_idx];

                    if (!mode_r) begin
                        // FFT: W = cos - j sin
                        // tr_real = (xr_q*cos + xi_q*sin + round) >> 15
                        // tr_imag = (xi_q*cos - xr_q*sin + round) >> 15
                        sum_r = ($signed(xr_q) * $signed(c_val)) + ($signed(xi_q) * $signed(s_val)) + (1<<14);
                        sum_i = ($signed(xi_q) * $signed(c_val)) - ($signed(xr_q) * $signed(s_val)) + (1<<14);
                    end else begin
                        // IFFT: W = cos + j sin  => equivalent to negating s_val in the same formula
                        sum_r = ($signed(xr_q) * $signed(c_val)) + ($signed(xi_q) * (-$signed(s_val))) + (1<<14);
                        sum_i = ($signed(xi_q) * $signed(c_val)) - ($signed(xr_q) * (-$signed(s_val))) + (1<<14);
                    end

                    tr_real = sum_r >>> 15;
                    tr_imag = sum_i >>> 15;

                    mem_real[p_idx] <= xr_p + tr_real;
                    mem_imag[p_idx] <= xi_p + tr_imag;
                    mem_real[q_idx] <= xr_p - tr_real;
                    mem_imag[q_idx] <= xi_p - tr_imag;

                    if (bfly_cnt == (N/2 - 1)) begin
                        bfly_cnt <= 0;
                        if (stage == LOGN-1) begin
                            state <= (mode_r) ? S_SCALE : S_DONE;
                        end else begin
                            stage <= stage + 1;
                        end
                    end else begin
                        bfly_cnt <= bfly_cnt + 1;
                    end
                end

                S_SCALE: begin
                    // divide by N=16 with rounding, only for IFFT
                    for (i=0;i<N;i=i+1) begin
                        mem_real[i] <= (mem_real[i] + 16'sd8) >>> 4;
                        mem_imag[i] <= (mem_imag[i] + 16'sd8) >>> 4;
                    end
                    state <= S_DONE;
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        // allow re-trigger, else stay
                        done <= 1'b0;
                        mode_r <= mode;
                        for (i=0;i<N;i=i+1) begin
                            mem_real[bitrev4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 0;
                        bfly_cnt <= 0;
                        state <= S_LOAD;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<N; gi=gi+1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

endmodule