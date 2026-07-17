`timescale 1ns/1ps

module nr_update_step #(
    parameter WORK_WIDTH = 96
)(
    input signed [WORK_WIDTH-1:0] x,
    input signed [WORK_WIDTH-1:0] step,
    input signed [WORK_WIDTH-1:0] derivative,
    output signed [WORK_WIDTH-1:0] x_next
);
    assign x_next = (derivative == 0) ? x : (x - step);
endmodule