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
    output done
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam N = CIN * H * W;
    localparam OUT_H = H - K + 1;
    localparam OUT_WID = W - K + 1;
    localparam OUT_N = COUT * OUT_H * OUT_WID;
    localparam IN_IDX_W = (N <= 1) ? 1 : clog2(N);
    localparam OUT_IDX_W = (OUT_N <= 1) ? 1 : clog2(OUT_N);
    localparam OC_W = (COUT <= 1) ? 1 : clog2(COUT);
    localparam ROW_W = (OUT_H <= 1) ? 1 : clog2(OUT_H);
    localparam COL_W = (OUT_WID <= 1) ? 1 : clog2(OUT_WID);
    localparam ACC_W = DATA_W + DATA_W + clog2(CIN*K*K) + BIAS_W + 2;

    reg [DATA_W-1:0] image_mem [0:N-1];
    reg [IN_IDX_W-1:0] in_count;
    reg [OUT_IDX_W-1:0] out_index;
    reg emitting;
    reg emitted_last;

    wire [N*DATA_W-1:0] image_flat;
    wire [OC_W-1:0] out_ch;
    wire [ROW_W-1:0] out_row;
    wire [COL_W-1:0] out_col;
    wire signed [ACC_W-1:0] conv_sum;
    wire [OUT_W-1:0] clamped_out;
    wire done_w;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : PACK_IMAGE
            assign image_flat[gi*DATA_W +: DATA_W] = image_mem[gi];
        end
    endgenerate

    conv2d_out_coord #(
        .COUT(COUT), .OUT_H(OUT_H), .OUT_WID(OUT_WID),
        .OUT_IDX_W(OUT_IDX_W), .OC_W(OC_W), .ROW_W(ROW_W), .COL_W(COL_W)
    ) u_coord (
        .out_index(out_index),
        .out_ch(out_ch),
        .out_row(out_row),
        .out_col(out_col)
    );

    conv2d_window_mac #(
        .CIN(CIN), .COUT(COUT), .K(K), .H(H), .W(W),
        .DATA_W(DATA_W), .BIAS_W(BIAS_W), .ACC_W(ACC_W),
        .OC_W(OC_W), .ROW_W(ROW_W), .COL_W(COL_W)
    ) u_mac (
        .image_flat(image_flat),
        .kernel(kernel),
        .bias(bias),
        .out_ch(out_ch),
        .out_row(out_row),
        .out_col(out_col),
        .sum(conv_sum)
    );

    conv2d_clamp #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_clamp (
        .value_in(conv_sum),
        .value_out(clamped_out)
    );

    conv2d_done_flag #(
        .OUT_N(OUT_N),
        .OUT_IDX_W(OUT_IDX_W)
    ) u_done (
        .emitted_last(emitted_last),
        .done(done_w)
    );

    assign done = done_w;

    integer ii;
    always @(posedge clk) begin
        if (rst) begin
            in_count <= {IN_IDX_W{1'b0}};
            out_index <= {OUT_IDX_W{1'b0}};
            emitting <= 1'b0;
            emitted_last <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            for (ii = 0; ii < N; ii = ii + 1)
                image_mem[ii] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (valid_in && !emitting && !emitted_last) begin
                image_mem[in_count] <= pixel_in;
                if (last_in || in_count == N-1) begin
                    emitting <= 1'b1;
                    out_index <= {OUT_IDX_W{1'b0}};
                end else begin
                    in_count <= in_count + {{(IN_IDX_W-1){1'b0}}, 1'b1};
                end
            end

            if (emitting) begin
                pixel_out <= clamped_out;
                valid_out <= 1'b1;
                if (out_index == OUT_N-1) begin
                    emitting <= 1'b0;
                    emitted_last <= 1'b1;
                end else begin
                    out_index <= out_index + {{(OUT_IDX_W-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule