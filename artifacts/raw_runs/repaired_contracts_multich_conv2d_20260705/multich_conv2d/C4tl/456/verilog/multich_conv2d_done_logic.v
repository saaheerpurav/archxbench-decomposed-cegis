`timescale 1ns/1ps

module multich_conv2d_done_logic #(
    parameter OUT_N = 30752
)(
    input  [31:0] out_count,
    input         emitting,
    output reg    done
);

    always @* begin
        done = (!emitting && (out_count >= OUT_N));
    end

endmodule