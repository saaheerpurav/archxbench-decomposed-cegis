`timescale 1ns/1ps

module newton_update_step #(
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] x_current,
    input signed [EXT_WIDTH-1:0] step,
    input hold,
    output signed [EXT_WIDTH-1:0] x_next
);

    assign x_next = hold ? x_current : (x_current - step);

endmodule