module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                              clk,
    input                              rst,
    input                              valid_in,
    input      [DATA_W-1:0]            pixel_in,
    output                             valid_out,
    output     [DATA_W+GAIN_W-1:0]     pixel_out
);

    localparam OUT_W      = DATA_W + GAIN_W;
    localparam PAD        = KERNEL_SIZE / 2;
    localparam ACC_W      = OUT_W + 8;
    localparam MAX_PIXELS = IMG_WIDTH * IMG_WIDTH;

    reg [DATA_W-1:0] frame [0:MAX_PIXELS-1];

    integer in_count;
    integer row;
    integer col;
    integer kr;
    integer kc;
    integer rr;
    integer cc;
    integer addr;
    reg [ACC_W-1:0] acc;

    function [7:0] coeff;
        input integer r;
        input integer c;
        begin
            if (KERNEL_SIZE == 3) begin
                if      (r == 0 && c == 0) coeff = 8'd1;
                else if (r == 0 && c == 1) coeff = 8'd2;
                else if (r == 0 && c == 2) coeff = 8'd1;
                else if (r == 1 && c == 0) coeff = 8'd2;
                else if (r == 1 && c == 1) coeff = 8'd4;
                else if (r == 1 && c == 2) coeff = 8'd2;
                else if (r == 2 && c == 0) coeff = 8'd1;
                else if (r == 2 && c == 1) coeff = 8'd2;
                else if (r == 2 && c == 2) coeff = 8'd1;
                else                       coeff = 8'd0;
            end else begin
                coeff = (r == PAD && c == PAD) ? 8'd1 : 8'd0;
            end
        end
    endfunction

    always @(*) begin
        row = in_count / IMG_WIDTH;
        col = in_count % IMG_WIDTH;
        acc = {ACC_W{1'b0}};

        for (kr = 0; kr < KERNEL_SIZE; kr = kr + 1) begin
            for (kc = 0; kc < KERNEL_SIZE; kc = kc + 1) begin
                rr = row + kr - PAD;
                cc = col + kc - PAD;

                if (rr >= 0 && rr < IMG_WIDTH && cc >= 0 && cc < IMG_WIDTH) begin
                    addr = rr * IMG_WIDTH + cc;

                    if (addr == in_count)
                        acc = acc + pixel_in * coeff(kr, kc);
                    else if (addr < in_count)
                        acc = acc + frame[addr] * coeff(kr, kc);
                end
            end
        end
    end

    assign valid_out = !rst;
    assign pixel_out = acc[OUT_W-1:0];

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
        end else if (valid_in) begin
            if (in_count < MAX_PIXELS)
                frame[in_count] <= pixel_in;
            in_count <= in_count + 1;
        end
    end

endmodule