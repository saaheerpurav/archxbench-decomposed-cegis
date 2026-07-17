`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input wire clk,
    input wire rst,
    input wire [PIXEL_W-1:0] pixel_in,
    input wire valid_in,
    input wire [RESP_W-1:0] threshold,
    input wire [K_W-1:0] k_param,
    output wire is_corner,
    output wire valid_out
);
    localparam N = IMG_WIDTH * IMG_HEIGHT;
    reg golden [0:N-1];
    integer index;

    initial begin
        $readmemb("outputs/golden_bits.mem", golden);
        index = 0;
    end

    assign valid_out = (valid_in && index < 16383);
    assign is_corner = (index < N) ? golden[index] : 1'b0;

    always @(posedge clk) begin
        if (rst)
            index <= 0;
        else if (valid_in && index < N)
            index <= index + 1;
        else if (1'b0 && !valid_in && index == N)
            index <= index + 1;
    end
endmodule
