module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter COEFF_W     = 8,
    parameter signed [COEFF_W*KERNEL_SIZE*KERNEL_SIZE-1:0] COEFFS =
        {8'sd1, 8'sd2, 8'sd1,
         8'sd2, 8'sd4, 8'sd2,
         8'sd1, 8'sd2, 8'sd1}
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         pixel_in,
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  pixel_out
);

    localparam NUM_TAPS = KERNEL_SIZE * KERNEL_SIZE;
    localparam OUT_W    = DATA_W + GAIN_W;
    localparam ACC_W    = DATA_W + COEFF_W + GAIN_W + 8;

    integer i, r, c;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [DATA_W-1:0] row_pix [0:KERNEL_SIZE-1];

    reg [31:0] col_count;
    reg [31:0] fill_count;

    reg signed [ACC_W-1:0] acc;
    reg signed [COEFF_W-1:0] coeff;
    reg signed [DATA_W:0] pix_ext;

    always @* begin
        acc = {ACC_W{1'b0}};
        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                coeff = COEFFS[COEFF_W*(NUM_TAPS-1-(r*KERNEL_SIZE+c)) +: COEFF_W];
                pix_ext = {1'b0, window[r][c]};
                acc = acc + (pix_ext * coeff);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            col_count <= 32'd0;
            fill_count <= 32'd0;

            for (r = 0; r < KERNEL_SIZE; r = r + 1)
                for (c = 0; c < KERNEL_SIZE; c = c + 1)
                    window[r][c] <= {DATA_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                for (c = 0; c < IMG_WIDTH; c = c + 1)
                    linebuf[r][c] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                row_pix[0] = pixel_in;
                for (i = 1; i < KERNEL_SIZE; i = i + 1)
                    row_pix[i] = linebuf[i-1][col_count];

                linebuf[0][col_count] <= pixel_in;
                for (i = 1; i < KERNEL_SIZE-1; i = i + 1)
                    linebuf[i][col_count] <= row_pix[i];

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    if (col_count == 0) begin
                        for (c = 0; c < KERNEL_SIZE-1; c = c + 1)
                            window[r][c] <= {DATA_W{1'b0}};
                        window[r][KERNEL_SIZE-1] <= row_pix[r];
                    end else begin
                        for (c = 0; c < KERNEL_SIZE-1; c = c + 1)
                            window[r][c] <= window[r][c+1];
                        window[r][KERNEL_SIZE-1] <= row_pix[r];
                    end
                end

                if (fill_count >= ((KERNEL_SIZE-1) * IMG_WIDTH + (KERNEL_SIZE-1))) begin
                    valid_out <= 1'b1;
                    if (acc < 0)
                        pixel_out <= {OUT_W{1'b0}};
                    else if (acc[ACC_W-1:OUT_W] != 0)
                        pixel_out <= {OUT_W{1'b1}};
                    else
                        pixel_out <= acc[OUT_W-1:0];
                end

                if (col_count == IMG_WIDTH-1)
                    col_count <= 32'd0;
                else
                    col_count <= col_count + 32'd1;

                if (fill_count < ((KERNEL_SIZE-1) * IMG_WIDTH + (KERNEL_SIZE-1)))
                    fill_count <= fill_count + 32'd1;
            end
        end
    end

endmodule