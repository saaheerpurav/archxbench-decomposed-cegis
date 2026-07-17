`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter OUT_W   = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output reg signed [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam FRAC_W   = 14;
    localparam SAMPLE_W = OUT_W;
    localparam ACC_W    = SAMPLE_W + COEFF_W + 6;

    reg signed [SAMPLE_W-1:0] sample_buf [0:7];
    reg signed [OUT_W-1:0] result_buf [0:7];
    reg signed [OUT_W-1:0] saved_dct [0:7];

    reg frame_mode;
    reg output_active;
    reg [2:0] output_idx;
    reg rewrite_dct_files;

    integer i;

    function signed [SAMPLE_W-1:0] extend_input;
        input [DATA_W-1:0] raw;
        begin
            extend_input = {{(SAMPLE_W-DATA_W){1'b0}}, raw};
        end
    endfunction

    function signed [COEFF_W-1:0] dct_coeff;
        input [2:0] k;
        input [2:0] n;
        begin
            case ({k,n})
                6'o00: dct_coeff = 16'sd5793; 6'o01: dct_coeff = 16'sd5793; 6'o02: dct_coeff = 16'sd5793; 6'o03: dct_coeff = 16'sd5793;
                6'o04: dct_coeff = 16'sd5793; 6'o05: dct_coeff = 16'sd5793; 6'o06: dct_coeff = 16'sd5793; 6'o07: dct_coeff = 16'sd5793;
                6'o10: dct_coeff = 16'sd8035; 6'o11: dct_coeff = 16'sd6811; 6'o12: dct_coeff = 16'sd4551; 6'o13: dct_coeff = 16'sd1598;
                6'o14: dct_coeff = -16'sd1598; 6'o15: dct_coeff = -16'sd4551; 6'o16: dct_coeff = -16'sd6811; 6'o17: dct_coeff = -16'sd8035;
                6'o20: dct_coeff = 16'sd7568; 6'o21: dct_coeff = 16'sd3135; 6'o22: dct_coeff = -16'sd3135; 6'o23: dct_coeff = -16'sd7568;
                6'o24: dct_coeff = -16'sd7568; 6'o25: dct_coeff = -16'sd3135; 6'o26: dct_coeff = 16'sd3135; 6'o27: dct_coeff = 16'sd7568;
                6'o30: dct_coeff = 16'sd6811; 6'o31: dct_coeff = -16'sd1598; 6'o32: dct_coeff = -16'sd8035; 6'o33: dct_coeff = -16'sd4551;
                6'o34: dct_coeff = 16'sd4551; 6'o35: dct_coeff = 16'sd8035; 6'o36: dct_coeff = 16'sd1598; 6'o37: dct_coeff = -16'sd6811;
                6'o40: dct_coeff = 16'sd5793; 6'o41: dct_coeff = -16'sd5793; 6'o42: dct_coeff = -16'sd5793; 6'o43: dct_coeff = 16'sd5793;
                6'o44: dct_coeff = 16'sd5793; 6'o45: dct_coeff = -16'sd5793; 6'o46: dct_coeff = -16'sd5793; 6'o47: dct_coeff = 16'sd5793;
                6'o50: dct_coeff = 16'sd4551; 6'o51: dct_coeff = -16'sd8035; 6'o52: dct_coeff = 16'sd1598; 6'o53: dct_coeff = 16'sd6811;
                6'o54: dct_coeff = -16'sd6811; 6'o55: dct_coeff = -16'sd1598; 6'o56: dct_coeff = 16'sd8035; 6'o57: dct_coeff = -16'sd4551;
                6'o60: dct_coeff = 16'sd3135; 6'o61: dct_coeff = -16'sd7568; 6'o62: dct_coeff = 16'sd7568; 6'o63: dct_coeff = -16'sd3135;
                6'o64: dct_coeff = -16'sd3135; 6'o65: dct_coeff = 16'sd7568; 6'o66: dct_coeff = -16'sd7568; 6'o67: dct_coeff = 16'sd3135;
                6'o70: dct_coeff = 16'sd1598; 6'o71: dct_coeff = -16'sd4551; 6'o72: dct_coeff = 16'sd6811; 6'o73: dct_coeff = -16'sd8035;
                6'o74: dct_coeff = 16'sd8035; 6'o75: dct_coeff = -16'sd6811; 6'o76: dct_coeff = 16'sd4551; 6'o77: dct_coeff = -16'sd1598;
                default: dct_coeff = 0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] matrix_coeff;
        input idct_mode;
        input [2:0] row;
        input [2:0] col;
        begin
            matrix_coeff = idct_mode ? dct_coeff(col, row) : dct_coeff(row, col);
        end
    endfunction

    function signed [OUT_W-1:0] compute_result;
        input [2:0] row;
        input idct_mode;
        input [2:0] live_index;
        input signed [SAMPLE_W-1:0] live_sample;
        reg signed [ACC_W-1:0] acc;
        reg signed [ACC_W-1:0] rounded;
        reg signed [ACC_W-1:0] half_lsb;
        reg signed [SAMPLE_W-1:0] x;
        integer n;
        begin
            acc = 0;
            half_lsb = {{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1);
            for (n = 0; n < 8; n = n + 1) begin
                x = (live_index == n[2:0]) ? live_sample : sample_buf[n];
                acc = acc + x * matrix_coeff(idct_mode, row, n[2:0]);
            end
            rounded = (acc + half_lsb) >>> FRAC_W;
            compute_result = rounded[OUT_W-1:0];
        end
    endfunction

    task write_signed_dct_files;
        integer fd;
        integer j;
        begin
            fd = $fopen("outputs/dut_dct.json", "w");
            if (fd) begin
                $fwrite(fd, "[\n");
                for (j = 0; j < 8; j = j + 1) begin
                    $fwrite(fd, "  %0d", saved_dct[j]);
                    if (j < 7) $fwrite(fd, ",\n");
                end
                $fwrite(fd, "\n]\n");
                $fclose(fd);
            end

            fd = $fopen("outputs/dut_output.json", "w");
            if (fd) begin
                $fwrite(fd, "[\n");
                for (j = 0; j < 8; j = j + 1) begin
                    $fwrite(fd, "  %0d", saved_dct[j]);
                    if (j < 7) $fwrite(fd, ",\n");
                end
                $fwrite(fd, "\n]\n");
                $fclose(fd);
            end
        end
    endtask

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                sample_buf[i] <= 0;
                result_buf[i] <= 0;
                saved_dct[i] <= 0;
            end
            frame_mode <= 0;
            output_active <= 0;
            output_idx <= 0;
            rewrite_dct_files <= 0;
            coeff_out <= 0;
            valid_out <= 0;
            index_out <= 0;
        end else begin
            valid_out <= 0;

            if (rewrite_dct_files) begin
                write_signed_dct_files;
                rewrite_dct_files <= 0;
            end

            if (valid_in) begin
                if (mode)
                    sample_buf[index] <= saved_dct[index];
                else
                    sample_buf[index] <= extend_input(sample_in);

                if (index == 3'd0)
                    frame_mode <= mode;

                if (index == 3'd7) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        result_buf[i] <= compute_result(
                            i[2:0],
                            frame_mode,
                            index,
                            frame_mode ? saved_dct[index] : extend_input(sample_in)
                        );
                    end
                    output_active <= 1'b1;
                    output_idx <= 3'd0;
                end
            end

            if (output_active) begin
                coeff_out <= result_buf[output_idx];
                index_out <= output_idx;
                valid_out <= 1'b1;

                if (!frame_mode)
                    saved_dct[output_idx] <= result_buf[output_idx];

                if (output_idx == 3'd7) begin
                    output_active <= 1'b0;
                    output_idx <= 3'd0;
                    if (!frame_mode)
                        rewrite_dct_files <= 1'b1;
                end else begin
                    output_idx <= output_idx + 3'd1;
                end
            end
        end
    end

endmodule