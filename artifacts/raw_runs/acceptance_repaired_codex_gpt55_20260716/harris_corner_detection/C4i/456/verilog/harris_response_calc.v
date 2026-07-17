`timescale 1ns/1ps

module harris_response_calc #(
    parameter IN_W = 36,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input  [IN_W-1:0] sx2,
    input  [IN_W-1:0] sy2,
    input  signed [IN_W-1:0] sxy,
    input  [K_W-1:0] k_param,
    output signed [RESP_W-1:0] response
);

    localparam INT_W = 96;

    wire signed [INT_W-1:0] sx2_ext = {{(INT_W-IN_W){sx2[IN_W-1]}}, sx2};
    wire signed [INT_W-1:0] sy2_ext = {{(INT_W-IN_W){sy2[IN_W-1]}}, sy2};
    wire signed [INT_W-1:0] sxy_ext = {{(INT_W-IN_W){sxy[IN_W-1]}}, sxy};
    wire signed [INT_W-1:0] k_ext   = {{(INT_W-K_W){1'b0}}, k_param};

    wire signed [INT_W-1:0] trace      = sx2_ext + sy2_ext;
    wire signed [INT_W-1:0] det_term   = (sx2_ext * sy2_ext) - (sxy_ext * sxy_ext);
    wire signed [INT_W-1:0] trace_term = trace * trace;

    wire signed [INT_W-1:0] k_term   = (k_ext * trace_term) >>> 7;
    wire signed [INT_W-1:0] r_full   = det_term - k_term;
    wire signed [INT_W-1:0] r_scaled = r_full >>> 12;

    wire signed [RESP_W-1:0] resp_max_narrow = {1'b0, {(RESP_W-1){1'b1}}};
    wire signed [RESP_W-1:0] resp_min_narrow = {1'b1, {(RESP_W-1){1'b0}}};

    wire signed [INT_W-1:0] resp_max =
        {{(INT_W-RESP_W){resp_max_narrow[RESP_W-1]}}, resp_max_narrow};
    wire signed [INT_W-1:0] resp_min =
        {{(INT_W-RESP_W){resp_min_narrow[RESP_W-1]}}, resp_min_narrow};

    assign response = (r_scaled > resp_max) ? resp_max_narrow :
                      (r_scaled < resp_min) ? resp_min_narrow :
                      r_scaled[RESP_W-1:0];

endmodule