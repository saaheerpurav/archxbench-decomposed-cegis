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

    // Twiddle ROM base values k=0..8 (Q1.15)
    function signed [COEFF_W-1:0] cos_base;
        input [3:0] k;
        begin
            case(k)
                4'd0: cos_base = 16'sd32767;
                4'd1: cos_base = 16'sd30274;
                4'd2: cos_base = 16'sd23170;
                4'd3: cos_base = 16'sd12540;
                4'd4: cos_base = 16'sd0;
                4'd5: cos_base = -16'sd12540;
                4'd6: cos_base = -16'sd23170;
                4'd7: cos_base = -16'sd30274;
                4'd8: cos_base = -16'sd32768;
                default: cos_base = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] sin_base;
        input [3:0] k;
        begin
            case(k)
                4'd0: sin_base = 16'sd0;
                4'd1: sin_base = 16'sd12540;
                4'd2: sin_base = 16'sd23170;
                4'd3: sin_base = 16'sd30274;
                4'd4: sin_base = 16'sd32767;
                4'd5: sin_base = 16'sd30274;
                4'd6: sin_base = 16'sd23170;
                4'd7: sin_base = 16'sd12540;
                4'd8: sin_base = 16'sd0;
                default: sin_base = 16'sd0;
            endcase
        end
    endfunction

    // Full twiddle lookup for k=0..15 using symmetry
    function signed [COEFF_W-1:0] cos_q15;
        input [4:0] k_in;
        reg [3:0] k;
        begin
            k = k_in[3:0];
            if (k <= 8)
                cos_q15 = cos_base(k);
            else
                cos_q15 = cos_base(4'd16 - k);
        end
    endfunction

    function signed [COEFF_W-1:0] sin_q15;
        input [4:0] k_in;
        reg [3:0] k;
        begin
            k = k_in[3:0];
            if (k <= 8)
                sin_q15 = sin_base(k);
            else
                sin_q15 = -sin_base(4'd16 - k);
        end
    endfunction

    // Bit reversal for 4-bit index
    function [3:0] bit_rev;
        input [3:0] idx;
        begin
            bit_rev = {idx[0], idx[1], idx[2], idx[3]};
        end
    endfunction

    // Working memory - wide enough to accommodate growth
    reg signed [OUT_W-1:0] wr [0:N-1];
    reg signed [OUT_W-1:0] wi [0:N-1];

    // FSM states
    localparam S_IDLE  = 3'd0;
    localparam S_LOAD  = 3'd1;
    localparam S_BFLY  = 3'd2;
    localparam S_NEXT  = 3'd3;
    localparam S_NORM  = 3'd4;
    localparam S_DONE  = 3'd5;

    reg [2:0] state;
    reg [2:0] stage;      // 1..4
    reg [3:0] group_base; // start index of group
    reg [3:0] j;          // index within half-group
    reg [3:0] norm_idx;

    reg mode_r;

    integer half, span, tw_step;
    reg [4:0] tw_idx;
    reg [3:0] p_idx, q_idx;

    // Butterfly combinational computation
    reg signed [COEFF_W-1:0] c_val, s_val;
    reg signed [OUT_W-1:0] xr_p, xi_p, xr_q, xi_q;
    reg signed [OUT_W+COEFF_W-1:0] mul_r, mul_i;
    reg signed [OUT_W-1:0] tr_real, tr_imag;

    always @(*) begin
        half = 1 << (stage-1);
        span = 1 << stage;
        tw_step = N >> stage; // N/span
        tw_idx = j * tw_step;
        p_idx = group_base + j;
        q_idx = p_idx + half;

        xr_p = wr[p_idx];
        xi_p = wi[p_idx];
        xr_q = wr[q_idx];
        xi_q = wi[q_idx];

        c_val = cos_q15(tw_idx[4:0]);
        if (mode_r == 1'b0)
            s_val = sin_q15(tw_idx[4:0]);
        else
            s_val = -sin_q15(tw_idx[4:0]);

        // tr_real = (xr_q*cos + xi_q*sin + 2^14) >> 15
        mul_r = xr_q * c_val + xi_q * s_val + (1 <<< 14);
        tr_real = mul_r >>> 15;

        mul_i = xi_q * c_val - xr_q * s_val + (1 <<< 14);
        tr_imag = mul_i >>> 15;
    end

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            stage <= 1;
            group_base <= 0;
            j <= 0;
            norm_idx <= 0;
            mode_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                wr[i] <= 0;
                wi[i] <= 0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        mode_r <= mode;
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // bit-reversed load
                    for (i = 0; i < N; i = i + 1) begin
                        wr[i] <= {{GAIN_W{data_real_in[bit_rev(i[3:0])][DATA_W-1]}}, data_real_in[bit_rev(i[3:0])]};
                        wi[i] <= {{GAIN_W{data_imag_in[bit_rev(i[3:0])][DATA_W-1]}}, data_imag_in[bit_rev(i[3:0])]};
                    end
                    stage <= 1;
                    group_base <= 0;
                    j <= 0;
                    state <= S_BFLY;
                end

                S_BFLY: begin
                    // perform butterfly write
                    wr[p_idx] <= xr_p + tr_real;
                    wi[p_idx] <= xi_p + tr_imag;
                    wr[q_idx] <= xr_p - tr_real;
                    wi[q_idx] <= xi_p - tr_imag;
                    state <= S_NEXT;
                end

                S_NEXT: begin
                    if (j + 1 < half) begin
                        j <= j + 1;
                        state <= S_BFLY;
                    end else if (group_base + span < N) begin
                        group_base <= group_base + span;
                        j <= 0;
                        state <= S_BFLY;
                    end else begin
                        // stage done
                        if (stage < LOGN) begin
                            stage <= stage + 1;
                            group_base <= 0;
                            j <= 0;
                            state <= S_BFLY;
                        end else begin
                            // all stages done
                            if (mode_r == 1'b1) begin
                                norm_idx <= 0;
                                state <= S_NORM;
                            end else begin
                                state <= S_DONE;
                            end
                        end
                    end
                end

                S_NORM: begin
                    // divide by N=16 with rounding, in place
                    wr[norm_idx] <= (wr[norm_idx] + 16'sd8) >>> 4;
                    wi[norm_idx] <= (wi[norm_idx] + 16'sd8) >>> 4;
                    if (norm_idx == N-1) begin
                        state <= S_DONE;
                    end else begin
                        norm_idx <= norm_idx + 1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        // allow retrigger after done seen? go back to idle logic
                        state <= S_IDLE;
                        done <= 1'b0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin: OUT_ASSIGN
            assign data_real_out[gi] = wr[gi];
            assign data_imag_out[gi] = wi[gi];
        end
    endgenerate

endmodule