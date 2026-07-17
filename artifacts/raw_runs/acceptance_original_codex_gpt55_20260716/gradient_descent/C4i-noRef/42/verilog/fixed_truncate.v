`timescale 1ns/1ps

module fixed_truncate #(
    parameter N = 16,
    parameter WIDE_W = 2*N
)(
    input  signed [WIDE_W-1:0] wide_value,
    output signed [N-1:0] narrow_value
);

    assign narrow_value = wide_value[N-1:0];

endmodule