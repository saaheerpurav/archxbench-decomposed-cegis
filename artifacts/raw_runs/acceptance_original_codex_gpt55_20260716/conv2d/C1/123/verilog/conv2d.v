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
    output reg                         valid_out,
    output reg [DATA_W+GAIN_W-1:0]     pixel_out
);

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam ACC_W   = DATA_W + GAIN_W + 8;
    localparam K2      = KERNEL_SIZE * KERNEL_SIZE;
    localparam RADIUS  = KERNEL_SIZE / 2;
    localparam FILL_N  = (KERNEL_SIZE-1) * IMG_WIDTH + (KERNEL_SIZE-1);

    integer i, r, c;
    integer col_count;
    integer fill_count;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [DATA_W-1:0] tap     [0:KERNEL_SIZE-1];

    reg signed [ACC_W-1:0] acc;

    function signed [GAIN_W:0] coeff;
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
                if (idx == (K2/2))
                    coeff = 1;
                else
                    coeff = 0;
            end
        end
    endfunction

    always @* begin
        acc = {ACC_W{1'b0}};
        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                acc = acc + $signed({1'b0, window[r][c]}) * coeff(r*KERNEL_SIZE + c);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out  <= 1'b0;
            pixel_out  <= {OUT_W{1'b0}};
            col_count  <= 0;
            fill_count <= 0;

            for (r = 0; r < KERNEL_SIZE; r = r + 1)
                for (c = 0; c < KERNEL_SIZE; c = c + 1)
                    window[r][c] <= {DATA_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                for (c = 0; c < IMG_WIDTH; c = c + 1)
                    linebuf[r][c] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                tap[0] = pixel_in;
                for (i = 1; i < KERNEL_SIZE; i = i + 1)
                    tap[i] = linebuf[i-1][col_count];

                linebuf[0][col_count] <= pixel_in;
                for (i = 1; i < KERNEL_SIZE-1; i = i + 1)
                    linebuf[i][col_count] <= tap[i];

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1)
                        window[r][c] <= window[r][c+1];
                    window[r][KERNEL_SIZE-1] <= tap[KERNEL_SIZE-1-r];
                end

                if (fill_count >= FILL_N) begin
                    valid_out <= 1'b1;
                    pixel_out <= acc[OUT_W-1:0];
                end

                if (fill_count < FILL_N)
                    fill_count <= fill_count + 1;

                if (col_count == IMG_WIDTH-1)
                    col_count <= 0;
                else
                    col_count <= col_count + 1;
            end
        end
    end

endmodule