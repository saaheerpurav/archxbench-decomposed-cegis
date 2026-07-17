`timescale 1ns/1ps

module gradient_update #(
    parameter N = 16,
    parameter WIDE_W = 2*N
)(
    input  signed [N-1:0]        x,
    input  signed [WIDE_W-1:0]   step,
    output signed [WIDE_W-1:0]   x_updated
);

    wire signed [WIDE_W-1:0] x_ext;

    assign x_ext = {{(WIDE_W-N){x[N-1]}}, x};

    assign x_updated = x_ext - step;

endmodule