`timescale 1ns/1ps

module harris_response_calc #(
    parameter IN_W = 36,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input  signed [IN_W-1:0] smooth_ix2,
    input  signed [IN_W-1:0] smooth_iy2,
    input  signed [IN_W-1:0] smooth_ixy,
    input         [K_W-1:0]  k_param,
    output signed [RESP_W-1:0] response
);
    localparam PROD_W  = 2 * IN_W;
    localparam DET_W   = PROD_W + 1;
    localparam TRACE_W = IN_W + 1;
    localparam TSQ_W   = 2 * TRACE_W;
    localparam KEXT_W  = K_W + 1;
    localparam FULL_W  = TSQ_W + KEXT_W;

    wire [IN_W-1:0] ix2_u = smooth_ix2;
    wire [IN_W-1:0] iy2_u = smooth_iy2;

    wire [PROD_W-1:0] ix2_iy2_prod = ix2_u * iy2_u;
    wire [PROD_W-1:0] ixy_ixy_prod = smooth_ixy * smooth_ixy;

    wire signed [DET_W-1:0] det_full =
        {1'b0, ix2_iy2_prod} - {1'b0, ixy_ixy_prod};

    wire [TRACE_W-1:0] trace =
        {1'b0, ix2_u} + {1'b0, iy2_u};

    wire [TSQ_W-1:0] trace_sq = trace * trace;

    wire [KEXT_W-1:0] k_unsigned = {1'b0, k_param};
    wire [FULL_W-1:0] k_term = trace_sq * k_unsigned;

    wire signed [FULL_W-1:0] det_ext =
        {{(FULL_W-DET_W){det_full[DET_W-1]}}, det_full};

    wire signed [FULL_W-1:0] resp_full =
        det_ext - $signed(k_term >> 6);

    wire signed [RESP_W-1:0] resp_max = {1'b0, {(RESP_W-1){1'b1}}};

    wire overflow_pos =
        (resp_full[FULL_W-1] == 1'b0) &&
        (|resp_full[FULL_W-2:RESP_W-1]);

    assign response = resp_full[FULL_W-1] ? {RESP_W{1'b0}} :
                      overflow_pos        ? resp_max :
                                            resp_full[RESP_W-1:0];

endmodule