`timescale 1ns/1ps

module gs2x2_result_select #(
    parameter DATA_WIDTH = 32
)(
    input [DATA_WIDTH-1:0] direct_x1,
    input [DATA_WIDTH-1:0] direct_x2,
    input direct_valid,
    input override_valid,
    input [DATA_WIDTH-1:0] override_x1,
    input [DATA_WIDTH-1:0] override_x2,
    output [DATA_WIDTH-1:0] x1_out,
    output [DATA_WIDTH-1:0] x2_out
);

    assign x1_out = override_valid ? override_x1 :
                    direct_valid   ? direct_x1 :
                                     {DATA_WIDTH{1'b0}};

    assign x2_out = override_valid ? override_x2 :
                    direct_valid   ? direct_x2 :
                                     {DATA_WIDTH{1'b0}};

endmodule