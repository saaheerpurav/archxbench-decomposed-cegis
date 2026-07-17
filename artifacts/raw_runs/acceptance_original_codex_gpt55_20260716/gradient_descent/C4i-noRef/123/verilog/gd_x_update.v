module gd_x_update #(
    parameter N = 16
)(
    input  signed [N-1:0] x_current,
    input  signed [N-1:0] step,
    output signed [N-1:0] x_updated
);

    assign x_updated = x_current - step;

endmodule