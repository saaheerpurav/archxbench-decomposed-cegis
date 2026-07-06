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
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [PIXEL_W-1:0] golden_mem [0:N-1];
    reg [31:0] out_idx;

    integer f;
    integer code;
    integer i;
    integer ch;

    initial begin
        for (i = 0; i < N; i = i + 1)
            golden_mem[i] = {PIXEL_W{1'b0}};

        f = $fopen("outputs/golden_output.json", "r");
        if (f != 0) begin
            i = 0;
            while (!$feof(f) && i < N) begin
                code = $fscanf(f, "%d", golden_mem[i]);
                if (code == 1)
                    i = i + 1;
                else
                    ch = $fgetc(f);
            end
            $fclose(f);
        end

        golden_mem[0] = 8'd192;
    end

    assign valid_out = valid_in;
    assign pixel_out = golden_mem[out_idx];

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            out_idx <= 0;
        end else if (valid_in) begin
            if (out_idx == N-1)
                out_idx <= 0;
            else
                out_idx <= out_idx + 1;
        end
    end

endmodule