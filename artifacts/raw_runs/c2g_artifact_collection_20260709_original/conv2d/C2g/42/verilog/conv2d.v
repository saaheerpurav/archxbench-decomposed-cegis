module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         pixel_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  pixel_out
);

    localparam OUT_W      = DATA_W + GAIN_W;
    localparam ACC_W      = OUT_W + 8;
    localparam LINE_COUNT = KERNEL_SIZE - 1;
    localparam LINE_DEPTH = (KERNEL_SIZE - 1) * IMG_WIDTH;

    integer i, r, c;
    integer col_count;

    reg [DATA_W-1:0] linebuf [0:LINE_DEPTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE*KERNEL_SIZE-1];

    reg [DATA_W-1:0] taps        [0:KERNEL_SIZE-1];
    reg [DATA_W-1:0] next_window [0:KERNEL_SIZE*KERNEL_SIZE-1];

    reg [ACC_W-1:0] acc_comb;
    reg [OUT_W-1:0] pixel_reg;

    assign valid_out = !rst;
    assign pixel_out = pixel_reg;

    function [GAIN_W-1:0] coeff;
        input integer idx;
        begin
            if (KERNEL_SIZE == 3) begin
                case (idx)
                    0: coeff = 1;
                    1: coeff = 2;
                    2: coeff = 1;
                    3: coeff = 2;
                    4: coeff = 4;
                    5: coeff = 2;
                    6: coeff = 1;
                    7: coeff = 2;
                    8: coeff = 1;
                    default: coeff = 0;
                endcase
            end else begin
                coeff = 1;
            end
        end
    endfunction

    always @(*) begin
        taps[0] = pixel_in;

        for (i = 1; i < KERNEL_SIZE; i = i + 1)
            taps[i] = linebuf[(i-1)*IMG_WIDTH + col_count];

        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE-1; c = c + 1)
                next_window[r*KERNEL_SIZE + c] = window[r*KERNEL_SIZE + c + 1];

            next_window[r*KERNEL_SIZE + KERNEL_SIZE-1] = taps[r];
        end

        acc_comb = {ACC_W{1'b0}};
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1)
            acc_comb = acc_comb + next_window[i] * coeff(i);
    end

    always @(negedge clk) begin
        if (rst) begin
            col_count <= 0;
            pixel_reg <= {OUT_W{1'b0}};

            for (i = 0; i < LINE_DEPTH; i = i + 1)
                linebuf[i] <= {DATA_W{1'b0}};

            for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1)
                window[i] <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            pixel_reg <= acc_comb[OUT_W-1:0];

            for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1)
                window[i] <= next_window[i];

            if (LINE_COUNT > 0) begin
                linebuf[col_count] <= pixel_in;
                for (i = 1; i < LINE_COUNT; i = i + 1)
                    linebuf[i*IMG_WIDTH + col_count] <= linebuf[(i-1)*IMG_WIDTH + col_count];
            end

            if (col_count == IMG_WIDTH-1)
                col_count <= 0;
            else
                col_count <= col_count + 1;
        end
    end

endmodule