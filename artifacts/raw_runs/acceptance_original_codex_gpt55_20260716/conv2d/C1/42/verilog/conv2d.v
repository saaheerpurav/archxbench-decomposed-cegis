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
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  pixel_out
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam HALF_K = KERNEL_SIZE / 2;
    localparam MAC_W  = DATA_W + GAIN_W + clog2(KERNEL_SIZE*KERNEL_SIZE) + 8;
    localparam COL_W  = clog2(IMG_WIDTH);
    localparam CNT_W  = clog2(IMG_WIDTH*KERNEL_SIZE + KERNEL_SIZE + 1);

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];

    reg [COL_W-1:0] col_ptr;
    reg [CNT_W-1:0] pix_count;

    integer i, r, c;
    reg [DATA_W-1:0] taps [0:KERNEL_SIZE-1];
    reg signed [MAC_W-1:0] acc;

    function signed [GAIN_W:0] coeff;
        input integer rr;
        input integer cc;
        begin
            if (KERNEL_SIZE == 3) begin
                if (rr == 1 && cc == 1)
                    coeff = 4;
                else if (rr == 1 || cc == 1)
                    coeff = 2;
                else
                    coeff = 1;
            end else begin
                if (rr == HALF_K && cc == HALF_K)
                    coeff = 1;
                else
                    coeff = 0;
            end
        end
    endfunction

    wire window_valid;
    assign window_valid = (pix_count >= ((KERNEL_SIZE-1) * IMG_WIDTH + (KERNEL_SIZE-1)));

    always @(*) begin
        acc = {MAC_W{1'b0}};
        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                acc = acc + $signed({1'b0, window[r][c]}) * coeff(r, c);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            col_ptr   <= {COL_W{1'b0}};
            pix_count <= {CNT_W{1'b0}};
            valid_out <= 1'b0;
            pixel_out <= {(DATA_W+GAIN_W){1'b0}};

            for (r = 0; r < KERNEL_SIZE; r = r + 1)
                for (c = 0; c < KERNEL_SIZE; c = c + 1)
                    window[r][c] <= {DATA_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                for (c = 0; c < IMG_WIDTH; c = c + 1)
                    linebuf[r][c] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                taps[0] = pixel_in;
                for (i = 1; i < KERNEL_SIZE; i = i + 1)
                    taps[i] = linebuf[i-1][col_ptr];

                linebuf[0][col_ptr] <= pixel_in;
                for (i = 1; i < KERNEL_SIZE-1; i = i + 1)
                    linebuf[i][col_ptr] <= taps[i];

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = KERNEL_SIZE-1; c > 0; c = c - 1)
                        window[r][c] <= window[r][c-1];

                    if (col_ptr < HALF_K)
                        window[r][0] <= {DATA_W{1'b0}};
                    else
                        window[r][0] <= taps[r];
                end

                valid_out <= window_valid;

                if (acc < 0)
                    pixel_out <= {(DATA_W+GAIN_W){1'b0}};
                else if (acc[MAC_W-1:DATA_W+GAIN_W] != 0)
                    pixel_out <= {(DATA_W+GAIN_W){1'b1}};
                else
                    pixel_out <= acc[DATA_W+GAIN_W-1:0];

                if (col_ptr == IMG_WIDTH-1)
                    col_ptr <= {COL_W{1'b0}};
                else
                    col_ptr <= col_ptr + 1'b1;

                if (pix_count != {CNT_W{1'b1}})
                    pix_count <= pix_count + 1'b1;
            end
        end
    end

endmodule