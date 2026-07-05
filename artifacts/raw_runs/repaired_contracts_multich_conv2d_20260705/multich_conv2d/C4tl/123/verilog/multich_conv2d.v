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

    localparam N = CIN * H * W;
    localparam OH = H - K + 1;
    localparam OW = W - K + 1;
    localparam OUT_N = COUT * OH * OW;
    localparam FRAME_W = CIN * H * W * DATA_W;
    localparam ACC_W = DATA_W + DATA_W + 16;

    reg [FRAME_W-1:0] frame_flat;
    reg [31:0] input_count;
    reg [31:0] output_count;
    reg emitting;

    wire [31:0] out_ch;
    wire [31:0] out_row;
    wire [31:0] out_col;
    wire signed [ACC_W-1:0] mac_sum;
    wire signed [ACC_W-1:0] biased_sum;
    wire [OUT_W-1:0] clamped_out;

    conv2d_out_index #(
        .COUT(COUT), .OH(OH), .OW(OW)
    ) u_index (
        .flat_index(output_count),
        .out_ch(out_ch),
        .out_row(out_row),
        .out_col(out_col)
    );

    conv2d_window_mac #(
        .CIN(CIN), .COUT(COUT), .K(K), .H(H), .W(W),
        .DATA_W(DATA_W), .ACC_W(ACC_W)
    ) u_mac (
        .frame_flat(frame_flat),
        .kernel(kernel),
        .out_ch(out_ch),
        .out_row(out_row),
        .out_col(out_col),
        .sum(mac_sum)
    );

    conv2d_bias_add #(
        .COUT(COUT), .BIAS_W(BIAS_W), .ACC_W(ACC_W)
    ) u_bias (
        .sum_in(mac_sum),
        .bias(bias),
        .out_ch(out_ch),
        .sum_out(biased_sum)
    );

    conv2d_clamp #(
        .IN_W(ACC_W), .OUT_W(OUT_W)
    ) u_clamp (
        .value_in(biased_sum),
        .value_out(clamped_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            frame_flat <= {FRAME_W{1'b0}};
            input_count <= 0;
            output_count <= 0;
            emitting <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in && input_count < N) begin
                frame_flat[input_count*DATA_W +: DATA_W] <= pixel_in;
                input_count <= input_count + 1;
                if (last_in || input_count == N-1) begin
                    emitting <= 1'b1;
                    output_count <= 0;
                    done <= 1'b0;
                end
            end

            if (emitting) begin
                pixel_out <= clamped_out;
                valid_out <= 1'b1;

                if (output_count == OUT_N-1) begin
                    output_count <= output_count + 1;
                    emitting <= 1'b0;
                    done <= 1'b1;
                end else begin
                    output_count <= output_count + 1;
                end
            end
        end
    end

endmodule