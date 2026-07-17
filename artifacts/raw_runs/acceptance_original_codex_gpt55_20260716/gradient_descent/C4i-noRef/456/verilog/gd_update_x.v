`timescale 1ns/1ps

module gd_update_x #(
    parameter N = 16,
    parameter STEP_W = N
)(
    input  signed [N-1:0]      x_current,
    input  signed [STEP_W-1:0] step,
    output signed [N-1:0]      x_updated
);

    wire signed [N-1:0] step_n;

    generate
        if (STEP_W >= N) begin : gen_truncate_step
            assign step_n = step[N-1:0];
        end else begin : gen_extend_step
            assign step_n = {{(N-STEP_W){step[STEP_W-1]}}, step};
        end
    endgenerate

    assign x_updated = x_current - step_n;

endmodule