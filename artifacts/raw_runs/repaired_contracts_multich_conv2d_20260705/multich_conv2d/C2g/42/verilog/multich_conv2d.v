`timescale 1ns/1ps

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
    localparam OH = H - K + 1;
    localparam OW = W - K + 1;
    localparam OUT_N = COUT * OH * OW;
    localparam ACC_W = DATA_W + DATA_W + BIAS_W + 16;

    reg [DATA_W-1:0] image [0:IN_N-1];

    reg state;
    localparam S_LOAD = 1'b0;
    localparam S_OUT  = 1'b1;

    integer in_count;
    integer out_count;

    integer oc;
    integer oy;
    integer ox;
    integer rem;
    integer ci;
    integer ky;
    integer kx;
    integer img_idx;
    integer ker_idx;
    reg [ACC_W-1:0] acc;
    reg [ACC_W-1:0] max_out;

    always @(*) begin
        oc = 0;
        oy = 0;
        ox = 0;
        rem = 0;
        img_idx = 0;
        ker_idx = 0;
        acc = {ACC_W{1'b0}};
        max_out = ({ACC_W{1'b0}} | ((1 << OUT_W) - 1));

        if (OUT_N > 0) begin
            oc = out_count / (OH * OW);
            rem = out_count % (OH * OW);
            oy = rem / OW;
            ox = rem % OW;

            acc = {{(ACC_W-BIAS_W){1'b0}}, bias[oc*BIAS_W +: BIAS_W]};

            for (ci = 0; ci < CIN; ci = ci + 1) begin
                for (ky = 0; ky < K; ky = ky + 1) begin
                    for (kx = 0; kx < K; kx = kx + 1) begin
                        img_idx = ci*H*W + (oy + ky)*W + (ox + kx);
                        ker_idx = (((oc*CIN + ci)*K + ky)*K + kx) * DATA_W;
                        acc = acc + image[img_idx] * kernel[ker_idx +: DATA_W];
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_LOAD;
            in_count <= 0;
            out_count <= 0;
            pixel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                S_LOAD: begin
                    done <= 1'b0;

                    if (valid_in) begin
                        if (in_count < IN_N) begin
                            image[in_count] <= pixel_in;
                        end

                        in_count <= in_count + 1;

                        if (last_in || in_count == IN_N-1) begin
                            state <= S_OUT;
                            out_count <= 0;
                        end
                    end
                end

                S_OUT: begin
                    if (out_count < OUT_N) begin
                        valid_out <= 1'b1;

                        if (acc > max_out) begin
                            pixel_out <= {OUT_W{1'b1}};
                        end else begin
                            pixel_out <= acc[OUT_W-1:0];
                        end

                        out_count <= out_count + 1;

                        if (out_count == OUT_N-1) begin
                            done <= 1'b1;
                        end
                    end else begin
                        valid_out <= 1'b0;
                        done <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule