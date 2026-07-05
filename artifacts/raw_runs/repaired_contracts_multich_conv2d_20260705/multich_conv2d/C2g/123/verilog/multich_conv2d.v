module multich_conv2d #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter BIAS_W = 16,
    parameter OUT_W = 16
)(
    input clk, rst,
    input [DATA_W-1:0] pixel_in,
    input valid_in,
    input last_in,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [COUT*BIAS_W-1:0] bias,
    output reg [OUT_W-1:0] pixel_out,
    output reg valid_out,
    output reg done
);

    localparam IN_N = CIN * H * W;
    localparam OUT_H = H - K + 1;
    localparam OUT_WID = W - K + 1;
    localparam OUT_N = COUT * OUT_H * OUT_WID;

    reg [DATA_W-1:0] image_mem [0:IN_N-1];

    integer in_count;
    integer out_count;
    reg producing;

    function [OUT_W-1:0] clamp_out;
        input [63:0] value;
        reg [63:0] max_value;
        begin
            max_value = (64'd1 << OUT_W) - 64'd1;
            if (value > max_value)
                clamp_out = {OUT_W{1'b1}};
            else
                clamp_out = value[OUT_W-1:0];
        end
    endfunction

    function [OUT_W-1:0] calc_output;
        input integer flat_idx;

        integer co;
        integer out_r;
        integer out_c;
        integer rem;
        integer ci;
        integer kr;
        integer kc;
        integer img_idx;
        integer ker_idx;

        reg [63:0] acc;
        reg [DATA_W-1:0] pix;
        reg [DATA_W-1:0] wt;
        reg [BIAS_W-1:0] b;
        begin
            co = flat_idx / (OUT_H * OUT_WID);
            rem = flat_idx % (OUT_H * OUT_WID);
            out_r = rem / OUT_WID;
            out_c = rem % OUT_WID;

            b = bias[co*BIAS_W +: BIAS_W];
            acc = b;

            for (ci = 0; ci < CIN; ci = ci + 1) begin
                for (kr = 0; kr < K; kr = kr + 1) begin
                    for (kc = 0; kc < K; kc = kc + 1) begin
                        img_idx = ci * H * W + (out_r + kr) * W + (out_c + kc);
                        ker_idx = (((co * CIN + ci) * K + kr) * K + kc);

                        pix = image_mem[img_idx];
                        wt = kernel[ker_idx*DATA_W +: DATA_W];

                        acc = acc + pix * wt;
                    end
                end
            end

            calc_output = clamp_out(acc);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            producing <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in && !producing) begin
                image_mem[in_count] <= pixel_in;

                if (last_in || in_count == IN_N - 1) begin
                    producing <= 1'b1;
                    out_count <= 0;
                end

                if (in_count < IN_N)
                    in_count <= in_count + 1;
            end else if (producing) begin
                if (out_count < OUT_N) begin
                    pixel_out <= calc_output(out_count);
                    valid_out <= 1'b1;
                    out_count <= out_count + 1;

                    if (out_count == OUT_N - 1) begin
                        producing <= 1'b0;
                        done <= 1'b1;
                    end
                end
            end
        end
    end

endmodule