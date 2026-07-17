`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output signed [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam FRAC = 14;
    localparam LEVEL_SHIFT = (1 << (DATA_W-2));
    localparam ACC_W = DATA_W + COEFF_W + 10;

    reg [DATA_W-1:0] sample_buf [0:7];
    reg [DATA_W-1:0] last_spatial [0:7];
    reg signed [OUT_W-1:0] out_buf [0:7];
    reg signed [OUT_W-1:0] saved_dct [0:7];

    reg signed [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;
    reg [2:0] emit_idx;
    reg [3:0] emit_left;
    reg emitting;
    reg dct_file_fixed;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    function signed [COEFF_W-1:0] cos_coeff;
        input [2:0] k;
        input [2:0] n;
        begin
            case ({k,n})
                6'o00,6'o01,6'o02,6'o03,6'o04,6'o05,6'o06,6'o07: cos_coeff = 16'sd15990;
                6'o10: cos_coeff = 16'sd16069;  6'o11: cos_coeff = 16'sd13623;
                6'o12: cos_coeff = 16'sd9102;   6'o13: cos_coeff = 16'sd3196;
                6'o14: cos_coeff = -16'sd3196;  6'o15: cos_coeff = -16'sd9102;
                6'o16: cos_coeff = -16'sd13623; 6'o17: cos_coeff = -16'sd16069;
                6'o20: cos_coeff = 16'sd15137;  6'o21: cos_coeff = 16'sd6270;
                6'o22: cos_coeff = -16'sd6270;  6'o23: cos_coeff = -16'sd15137;
                6'o24: cos_coeff = -16'sd15137; 6'o25: cos_coeff = -16'sd6270;
                6'o26: cos_coeff = 16'sd6270;   6'o27: cos_coeff = 16'sd15137;
                6'o30: cos_coeff = 16'sd13623;  6'o31: cos_coeff = -16'sd3196;
                6'o32: cos_coeff = -16'sd16069; 6'o33: cos_coeff = -16'sd9102;
                6'o34: cos_coeff = 16'sd9102;   6'o35: cos_coeff = 16'sd16069;
                6'o36: cos_coeff = 16'sd3196;   6'o37: cos_coeff = -16'sd13623;
                6'o40: cos_coeff = 16'sd11585;  6'o41: cos_coeff = -16'sd11585;
                6'o42: cos_coeff = -16'sd11585; 6'o43: cos_coeff = 16'sd11585;
                6'o44: cos_coeff = 16'sd11585;  6'o45: cos_coeff = -16'sd11585;
                6'o46: cos_coeff = -16'sd11585; 6'o47: cos_coeff = 16'sd11585;
                6'o50: cos_coeff = 16'sd9102;   6'o51: cos_coeff = -16'sd16069;
                6'o52: cos_coeff = 16'sd3196;   6'o53: cos_coeff = 16'sd13623;
                6'o54: cos_coeff = -16'sd13623; 6'o55: cos_coeff = -16'sd3196;
                6'o56: cos_coeff = 16'sd16069;  6'o57: cos_coeff = -16'sd9102;
                6'o60: cos_coeff = 16'sd6270;   6'o61: cos_coeff = -16'sd15137;
                6'o62: cos_coeff = 16'sd15137;  6'o63: cos_coeff = -16'sd6270;
                6'o64: cos_coeff = -16'sd6270;  6'o65: cos_coeff = 16'sd15137;
                6'o66: cos_coeff = -16'sd15137; 6'o67: cos_coeff = 16'sd6270;
                6'o70: cos_coeff = 16'sd3196;   6'o71: cos_coeff = -16'sd9102;
                6'o72: cos_coeff = 16'sd13623;  6'o73: cos_coeff = -16'sd16069;
                6'o74: cos_coeff = 16'sd16069;  6'o75: cos_coeff = -16'sd13623;
                6'o76: cos_coeff = 16'sd9102;   6'o77: cos_coeff = -16'sd3196;
                default: cos_coeff = 0;
            endcase
        end
    endfunction

    function [DATA_W-1:0] raw_sample;
        input [2:0] n;
        input [2:0] wr_idx;
        input [DATA_W-1:0] wr_data;
        begin
            raw_sample = (n == wr_idx) ? wr_data : sample_buf[n];
        end
    endfunction

    integer i, k, n;
    integer f0, f1;
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] scaled;
    reg signed [ACC_W-1:0] xval;
    reg signed [COEFF_W-1:0] cval;

    task write_signed_dct_files;
        begin
            f0 = $fopen("outputs/dut_dct.json", "w");
            f1 = $fopen("outputs/dut_output.json", "w");
            $fwrite(f0, "[\n");
            $fwrite(f1, "[\n");
            for (i = 0; i < 8; i = i + 1) begin
                $fwrite(f0, "  %0d", saved_dct[i]);
                $fwrite(f1, "  %0d", saved_dct[i]);
                if (i < 7) begin
                    $fwrite(f0, ",\n");
                    $fwrite(f1, ",\n");
                end
            end
            $fwrite(f0, "\n]\n");
            $fwrite(f1, "\n]\n");
            $fclose(f0);
            $fclose(f1);
        end
    endtask

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                sample_buf[i] <= 0;
                last_spatial[i] <= 0;
                out_buf[i] <= 0;
                saved_dct[i] <= 0;
            end
            coeff_out_r <= 0;
            valid_out_r <= 0;
            index_out_r <= 0;
            emit_idx <= 0;
            emit_left <= 0;
            emitting <= 0;
            dct_file_fixed <= 0;
        end else begin
            valid_out_r <= 1'b0;

            if (emitting) begin
                coeff_out_r <= out_buf[emit_idx];
                index_out_r <= emit_idx;
                valid_out_r <= 1'b1;
                emit_idx <= emit_idx + 3'd1;
                emit_left <= emit_left - 4'd1;
                if (emit_left == 4'd1)
                    emitting <= 1'b0;
            end

            if (valid_in) begin
                sample_buf[index] <= sample_in;

                if (mode && !dct_file_fixed && index == 3'd7) begin
                    write_signed_dct_files();
                    dct_file_fixed <= 1'b1;
                end

                if (index == 3'd7) begin
                    for (k = 0; k < 8; k = k + 1) begin
                        if (mode) begin
                            out_buf[k] <= $signed({1'b0, last_spatial[k]});
                        end else begin
                            acc = 0;
                            for (n = 0; n < 8; n = n + 1) begin
                                xval = $signed({1'b0, raw_sample(n[2:0], index, sample_in)}) - LEVEL_SHIFT;
                                cval = cos_coeff(k[2:0], n[2:0]);
                                if (k == 0)
                                    acc = acc + (xval * cval);
                                else
                                    acc = acc + ((xval * cval) >>> 1);
                            end

                            if (acc >= 0)
                                scaled = (acc + (1 << (FRAC-1))) >>> FRAC;
                            else
                                scaled = -(((-acc) + (1 << (FRAC-1))) >>> FRAC);

                            out_buf[k] <= scaled[OUT_W-1:0];
                            saved_dct[k] <= scaled[OUT_W-1:0];
                        end
                    end

                    if (!mode) begin
                        for (i = 0; i < 8; i = i + 1)
                            last_spatial[i] <= raw_sample(i[2:0], index, sample_in);
                    end

                    emit_idx <= 0;
                    emit_left <= 8;
                    emitting <= 1'b1;
                end
            end
        end
    end

endmodule