`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH  = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W    = 8,
    parameter GRAD_W     = 16,
    parameter RESP_W     = 32,
    parameter K_W        = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [RESP_W-1:0] threshold,
    input [K_W-1:0] k_param,
    output reg is_corner,
    output valid_out
);

    localparam PROD_W = 2*GRAD_W;
    localparam ACC_W  = PROD_W + 6;

    reg [PIXEL_W-1:0] pix_line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] pix_line1 [0:IMG_WIDTH-1];

    reg signed [PROD_W-1:0] ix2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] p00, p01, p02;
    reg [PIXEL_W-1:0] p10, p11, p12;
    reg [PIXEL_W-1:0] p20, p21, p22;

    reg signed [PROD_W-1:0] x200, x201, x202;
    reg signed [PROD_W-1:0] x210, x211, x212;
    reg signed [PROD_W-1:0] x220, x221, x222;

    reg signed [PROD_W-1:0] y200, y201, y202;
    reg signed [PROD_W-1:0] y210, y211, y212;
    reg signed [PROD_W-1:0] y220, y221, y222;

    reg signed [PROD_W-1:0] xy00, xy01, xy02;
    reg signed [PROD_W-1:0] xy10, xy11, xy12;
    reg signed [PROD_W-1:0] xy20, xy21, xy22;

    reg signed [GRAD_W-1:0] ix_s1, iy_s1;
    reg signed [PROD_W-1:0] ix2_s2, iy2_s2, ixy_s2;

    reg signed [ACC_W-1:0] sxx_s3, syy_s3, sxy_s3;
    reg signed [ACC_W-1:0] sxx_s4, syy_s4, sxy_s4;

    reg signed [2*ACC_W-1:0] det_s5;
    reg signed [ACC_W:0] trace_s5;
    reg signed [2*ACC_W+K_W:0] ktrace_s6;
    reg signed [2*ACC_W+K_W:0] resp_s6;

    reg v1, v2, v3, v4, v5, v6;
    reg stencil1_valid, stencil2_valid;

    reg [31:0] x_cnt;
    reg [31:0] y_cnt;

    integer i;

    assign valid_out = valid_in;

    function signed [ACC_W-1:0] gauss3x3;
        input signed [PROD_W-1:0] a00, a01, a02;
        input signed [PROD_W-1:0] a10, a11, a12;
        input signed [PROD_W-1:0] a20, a21, a22;
        reg signed [ACC_W-1:0] sum;
        begin
            sum = {{(ACC_W-PROD_W){a00[PROD_W-1]}}, a00}
                + ({{(ACC_W-PROD_W){a01[PROD_W-1]}}, a01} <<< 1)
                + {{(ACC_W-PROD_W){a02[PROD_W-1]}}, a02}
                + ({{(ACC_W-PROD_W){a10[PROD_W-1]}}, a10} <<< 1)
                + ({{(ACC_W-PROD_W){a11[PROD_W-1]}}, a11} <<< 2)
                + ({{(ACC_W-PROD_W){a12[PROD_W-1]}}, a12} <<< 1)
                + {{(ACC_W-PROD_W){a20[PROD_W-1]}}, a20}
                + ({{(ACC_W-PROD_W){a21[PROD_W-1]}}, a21} <<< 1)
                + {{(ACC_W-PROD_W){a22[PROD_W-1]}}, a22};
            gauss3x3 = sum >>> 4;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            x_cnt <= 0;
            y_cnt <= 0;

            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            x200 <= 0; x201 <= 0; x202 <= 0;
            x210 <= 0; x211 <= 0; x212 <= 0;
            x220 <= 0; x221 <= 0; x222 <= 0;

            y200 <= 0; y201 <= 0; y202 <= 0;
            y210 <= 0; y211 <= 0; y212 <= 0;
            y220 <= 0; y221 <= 0; y222 <= 0;

            xy00 <= 0; xy01 <= 0; xy02 <= 0;
            xy10 <= 0; xy11 <= 0; xy12 <= 0;
            xy20 <= 0; xy21 <= 0; xy22 <= 0;

            ix_s1 <= 0;
            iy_s1 <= 0;
            ix2_s2 <= 0;
            iy2_s2 <= 0;
            ixy_s2 <= 0;
            sxx_s3 <= 0;
            syy_s3 <= 0;
            sxy_s3 <= 0;
            sxx_s4 <= 0;
            syy_s4 <= 0;
            sxy_s4 <= 0;
            det_s5 <= 0;
            trace_s5 <= 0;
            ktrace_s6 <= 0;
            resp_s6 <= 0;

            stencil1_valid <= 0;
            stencil2_valid <= 0;
            v1 <= 0; v2 <= 0; v3 <= 0; v4 <= 0; v5 <= 0; v6 <= 0;
            is_corner <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                pix_line0[i] <= 0;
                pix_line1[i] <= 0;
                ix2_line0[i] <= 0;
                ix2_line1[i] <= 0;
                iy2_line0[i] <= 0;
                iy2_line1[i] <= 0;
                ixy_line0[i] <= 0;
                ixy_line1[i] <= 0;
            end
        end else begin
            if (valid_in) begin
                p00 <= p01;
                p01 <= p02;
                p02 <= pix_line1[x_cnt];

                p10 <= p11;
                p11 <= p12;
                p12 <= pix_line0[x_cnt];

                p20 <= p21;
                p21 <= p22;
                p22 <= pixel_in;

                pix_line1[x_cnt] <= pix_line0[x_cnt];
                pix_line0[x_cnt] <= pixel_in;

                stencil1_valid <= (x_cnt >= 2 && y_cnt >= 2);

                ix_s1 <= -$signed({1'b0,p00}) + $signed({1'b0,p02})
                         -($signed({1'b0,p10}) <<< 1) + ($signed({1'b0,p12}) <<< 1)
                         -$signed({1'b0,p20}) + $signed({1'b0,p22});

                iy_s1 <= -$signed({1'b0,p00}) - ($signed({1'b0,p01}) <<< 1) - $signed({1'b0,p02})
                         + $signed({1'b0,p20}) + ($signed({1'b0,p21}) <<< 1) + $signed({1'b0,p22});

                v1 <= stencil1_valid;

                ix2_s2 <= ix_s1 * ix_s1;
                iy2_s2 <= iy_s1 * iy_s1;
                ixy_s2 <= ix_s1 * iy_s1;
                v2 <= v1;

                x200 <= x201; x201 <= x202; x202 <= ix2_line1[x_cnt];
                x210 <= x211; x211 <= x212; x212 <= ix2_line0[x_cnt];
                x220 <= x221; x221 <= x222; x222 <= ix2_s2;

                y200 <= y201; y201 <= y202; y202 <= iy2_line1[x_cnt];
                y210 <= y211; y211 <= y212; y212 <= iy2_line0[x_cnt];
                y220 <= y221; y221 <= y222; y222 <= iy2_s2;

                xy00 <= xy01; xy01 <= xy02; xy02 <= ixy_line1[x_cnt];
                xy10 <= xy11; xy11 <= xy12; xy12 <= ixy_line0[x_cnt];
                xy20 <= xy21; xy21 <= xy22; xy22 <= ixy_s2;

                ix2_line1[x_cnt] <= ix2_line0[x_cnt];
                ix2_line0[x_cnt] <= ix2_s2;
                iy2_line1[x_cnt] <= iy2_line0[x_cnt];
                iy2_line0[x_cnt] <= iy2_s2;
                ixy_line1[x_cnt] <= ixy_line0[x_cnt];
                ixy_line0[x_cnt] <= ixy_s2;

                stencil2_valid <= (x_cnt >= 4 && y_cnt >= 4);
                v3 <= v2 && stencil2_valid;

                sxx_s3 <= gauss3x3(x200,x201,x202,x210,x211,x212,x220,x221,x222);
                syy_s3 <= gauss3x3(y200,y201,y202,y210,y211,y212,y220,y221,y222);
                sxy_s3 <= gauss3x3(xy00,xy01,xy02,xy10,xy11,xy12,xy20,xy21,xy22);

                sxx_s4 <= sxx_s3;
                syy_s4 <= syy_s3;
                sxy_s4 <= sxy_s3;
                v4 <= v3;

                det_s5 <= (sxx_s4 * syy_s4) - (sxy_s4 * sxy_s4);
                trace_s5 <= sxx_s4 + syy_s4;
                v5 <= v4;

                ktrace_s6 <= ($signed({1'b0,k_param}) * (trace_s5 * trace_s5)) >>> K_W;
                resp_s6 <= {{(K_W+1){det_s5[2*ACC_W-1]}}, det_s5} - ktrace_s6;
                v6 <= v5;

                if (v6 && resp_s6 > $signed({1'b0,threshold}))
                    is_corner <= 1'b1;
                else
                    is_corner <= 1'b0;

                if (x_cnt == IMG_WIDTH-1) begin
                    x_cnt <= 0;
                    if (y_cnt == IMG_HEIGHT-1)
                        y_cnt <= 0;
                    else
                        y_cnt <= y_cnt + 1;
                end else begin
                    x_cnt <= x_cnt + 1;
                end
            end else begin
                is_corner <= 1'b0;
                v1 <= 0; v2 <= 0; v3 <= 0; v4 <= 0; v5 <= 0; v6 <= 0;
            end
        end
    end

endmodule