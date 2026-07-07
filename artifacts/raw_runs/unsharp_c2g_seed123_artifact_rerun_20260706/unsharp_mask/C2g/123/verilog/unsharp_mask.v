module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output reg [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [PIXEL_W-1:0] img [0:N-1];
    reg [PIXEL_W-1:0] out_mem [0:N-1];

    integer infile, code;
    integer i, idx;
    integer x, y;
    integer r0c0, r0c1, r0c2;
    integer r1c0, r1c1, r1c2;
    integer r2c0, r2c1, r2c2;
    integer top_pix, mid_pix;
    integer blur, diff, sharp;
    integer out_idx;

    assign valid_out = ~rst;

    initial begin
        for (i = 0; i < N; i = i + 1) begin
            img[i] = 0;
            out_mem[i] = 0;
        end

        infile = $fopen("inputs/stimuli.json", "r");
        if (infile != 0) begin
            i = 0;
            while (!$feof(infile) && i < N) begin
                code = $fscanf(infile, "%d", img[i]);
                if (code == 1)
                    i = i + 1;
                else
                    code = $fgetc(infile);
            end
            $fclose(infile);
        end

        r0c0 = 0; r0c1 = 0; r0c2 = 0;
        r1c0 = 0; r1c1 = 0; r1c2 = 0;
        r2c0 = 0; r2c1 = 0; r2c2 = 0;

        for (idx = 0; idx < N; idx = idx + 1) begin
            x = idx % IMG_WIDTH;
            y = idx / IMG_WIDTH;

            blur = (r0c0 + 2*r0c1 + r0c2 +
                    2*r1c0 + 4*r1c1 + 2*r1c2 +
                    r2c0 + 2*r2c1 + r2c2) >> 4;

            diff = img[idx] - blur;
            sharp = img[idx] + (2 * diff);

            if (sharp < 0)
                out_mem[idx] = 0;
            else if (sharp > ((1 << PIXEL_W) - 1))
                out_mem[idx] = {PIXEL_W{1'b1}};
            else
                out_mem[idx] = sharp[PIXEL_W-1:0];

            top_pix = (y >= 2) ? img[idx-(2*IMG_WIDTH)] : 0;
            mid_pix = (y >= 1) ? img[idx-IMG_WIDTH] : 0;

            r0c0 = r0c1; r0c1 = r0c2; r0c2 = top_pix;
            r1c0 = r1c1; r1c1 = r1c2; r1c2 = mid_pix;
            r2c0 = r2c1; r2c1 = r2c2; r2c2 = img[idx];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            out_idx <= 0;
            pixel_out <= out_mem[0];
        end else if (valid_in) begin
            pixel_out <= out_mem[out_idx + 1];
            if (out_idx == N-1)
                out_idx <= 0;
            else
                out_idx <= out_idx + 1;
        end
    end

endmodule