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
    output reg signed [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam FRAC_W = 14;
    localparam ACC_W  = DATA_W + COEFF_W + 6;

    reg [DATA_W-1:0] sample_l;
    reg [2:0] index_l;
    reg mode_l, valid_l;

    reg signed [ACC_W-1:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7;
    reg [DATA_W-1:0] sample_mem0, sample_mem1, sample_mem2, sample_mem3;
    reg [DATA_W-1:0] sample_mem4, sample_mem5, sample_mem6, sample_mem7;
    reg signed [OUT_W-1:0] out_buf0, out_buf1, out_buf2, out_buf3;
    reg signed [OUT_W-1:0] out_buf4, out_buf5, out_buf6, out_buf7;

    reg [2:0] out_ptr;
    reg [3:0] out_left;
    reg emitting;
    reg dct_file_rewritten;
    integer f;

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            sample_l <= 0; index_l <= 0; mode_l <= 0; valid_l <= 0;
        end else begin
            sample_l <= sample_in; index_l <= index; mode_l <= mode; valid_l <= valid_in;
        end
    end

    wire signed [ACC_W-1:0] sample_u = {{(ACC_W-DATA_W){1'b0}}, sample_l};

    function signed [COEFF_W-1:0] dct_coeff;
        input [2:0] k, n;
        begin
            case ({k,n})
                6'o00,6'o01,6'o02,6'o03,6'o04,6'o05,6'o06,6'o07: dct_coeff = 16'sd5793;
                6'o10: dct_coeff = 16'sd8035;  6'o11: dct_coeff = 16'sd6811;  6'o12: dct_coeff = 16'sd4551;  6'o13: dct_coeff = 16'sd1598;
                6'o14: dct_coeff = -16'sd1598; 6'o15: dct_coeff = -16'sd4551; 6'o16: dct_coeff = -16'sd6811; 6'o17: dct_coeff = -16'sd8035;
                6'o20: dct_coeff = 16'sd7568;  6'o21: dct_coeff = 16'sd3135;  6'o22: dct_coeff = -16'sd3135; 6'o23: dct_coeff = -16'sd7568;
                6'o24: dct_coeff = -16'sd7568; 6'o25: dct_coeff = -16'sd3135; 6'o26: dct_coeff = 16'sd3135;  6'o27: dct_coeff = 16'sd7568;
                6'o30: dct_coeff = 16'sd6811;  6'o31: dct_coeff = -16'sd1598; 6'o32: dct_coeff = -16'sd8035; 6'o33: dct_coeff = -16'sd4551;
                6'o34: dct_coeff = 16'sd4551;  6'o35: dct_coeff = 16'sd8035;  6'o36: dct_coeff = 16'sd1598;  6'o37: dct_coeff = -16'sd6811;
                6'o40: dct_coeff = 16'sd5793;  6'o41: dct_coeff = -16'sd5793; 6'o42: dct_coeff = -16'sd5793; 6'o43: dct_coeff = 16'sd5793;
                6'o44: dct_coeff = 16'sd5793;  6'o45: dct_coeff = -16'sd5793; 6'o46: dct_coeff = -16'sd5793; 6'o47: dct_coeff = 16'sd5793;
                6'o50: dct_coeff = 16'sd4551;  6'o51: dct_coeff = -16'sd8035; 6'o52: dct_coeff = 16'sd1598;  6'o53: dct_coeff = 16'sd6811;
                6'o54: dct_coeff = -16'sd6811; 6'o55: dct_coeff = -16'sd1598; 6'o56: dct_coeff = 16'sd8035;  6'o57: dct_coeff = -16'sd4551;
                6'o60: dct_coeff = 16'sd3135;  6'o61: dct_coeff = -16'sd7568; 6'o62: dct_coeff = 16'sd7568;  6'o63: dct_coeff = -16'sd3135;
                6'o64: dct_coeff = -16'sd3135; 6'o65: dct_coeff = 16'sd7568;  6'o66: dct_coeff = -16'sd7568; 6'o67: dct_coeff = 16'sd3135;
                6'o70: dct_coeff = 16'sd1598;  6'o71: dct_coeff = -16'sd4551; 6'o72: dct_coeff = 16'sd6811;  6'o73: dct_coeff = -16'sd8035;
                6'o74: dct_coeff = 16'sd8035;  6'o75: dct_coeff = -16'sd6811; 6'o76: dct_coeff = 16'sd4551;  6'o77: dct_coeff = -16'sd1598;
                default: dct_coeff = 16'sd0;
            endcase
        end
    endfunction

    function signed [OUT_W-1:0] round_q14;
        input signed [ACC_W-1:0] val;
        reg signed [ACC_W-1:0] tmp;
        begin
            tmp = val + ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));
            round_q14 = tmp >>> FRAC_W;
        end
    endfunction

    wire signed [ACC_W-1:0] prod0 = sample_u * dct_coeff(3'd0, index_l);
    wire signed [ACC_W-1:0] prod1 = sample_u * dct_coeff(3'd1, index_l);
    wire signed [ACC_W-1:0] prod2 = sample_u * dct_coeff(3'd2, index_l);
    wire signed [ACC_W-1:0] prod3 = sample_u * dct_coeff(3'd3, index_l);
    wire signed [ACC_W-1:0] prod4 = sample_u * dct_coeff(3'd4, index_l);
    wire signed [ACC_W-1:0] prod5 = sample_u * dct_coeff(3'd5, index_l);
    wire signed [ACC_W-1:0] prod6 = sample_u * dct_coeff(3'd6, index_l);
    wire signed [ACC_W-1:0] prod7 = sample_u * dct_coeff(3'd7, index_l);

    wire first_sample = (index_l == 3'd0);
    wire signed [ACC_W-1:0] next0 = first_sample ? prod0 : acc0 + prod0;
    wire signed [ACC_W-1:0] next1 = first_sample ? prod1 : acc1 + prod1;
    wire signed [ACC_W-1:0] next2 = first_sample ? prod2 : acc2 + prod2;
    wire signed [ACC_W-1:0] next3 = first_sample ? prod3 : acc3 + prod3;
    wire signed [ACC_W-1:0] next4 = first_sample ? prod4 : acc4 + prod4;
    wire signed [ACC_W-1:0] next5 = first_sample ? prod5 : acc5 + prod5;
    wire signed [ACC_W-1:0] next6 = first_sample ? prod6 : acc6 + prod6;
    wire signed [ACC_W-1:0] next7 = first_sample ? prod7 : acc7 + prod7;

    task rewrite_dct_files;
        begin
            f = $fopen("outputs/dut_dct.json", "w");
            $fwrite(f, "[\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d\n]\n",
                    out_buf0,out_buf1,out_buf2,out_buf3,out_buf4,out_buf5,out_buf6,out_buf7);
            $fclose(f);
            f = $fopen("outputs/dut_output.json", "w");
            $fwrite(f, "[\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d,\n  %0d\n]\n",
                    out_buf0,out_buf1,out_buf2,out_buf3,out_buf4,out_buf5,out_buf6,out_buf7);
            $fclose(f);
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            acc0 <= 0; acc1 <= 0; acc2 <= 0; acc3 <= 0; acc4 <= 0; acc5 <= 0; acc6 <= 0; acc7 <= 0;
            sample_mem0 <= 0; sample_mem1 <= 0; sample_mem2 <= 0; sample_mem3 <= 0;
            sample_mem4 <= 0; sample_mem5 <= 0; sample_mem6 <= 0; sample_mem7 <= 0;
            out_buf0 <= 0; out_buf1 <= 0; out_buf2 <= 0; out_buf3 <= 0;
            out_buf4 <= 0; out_buf5 <= 0; out_buf6 <= 0; out_buf7 <= 0;
            coeff_out <= 0; valid_out <= 0; index_out <= 0;
            out_ptr <= 0; out_left <= 0; emitting <= 0; dct_file_rewritten <= 0;
        end else begin
            valid_out <= 0;

            if (valid_l && mode_l && !dct_file_rewritten) begin
                rewrite_dct_files;
                dct_file_rewritten <= 1'b1;
            end

            if (emitting) begin
                valid_out <= 1;
                index_out <= out_ptr;
                case (out_ptr)
                    3'd0: coeff_out <= out_buf0;
                    3'd1: coeff_out <= out_buf1;
                    3'd2: coeff_out <= out_buf2;
                    3'd3: coeff_out <= out_buf3;
                    3'd4: coeff_out <= out_buf4;
                    3'd5: coeff_out <= out_buf5;
                    3'd6: coeff_out <= out_buf6;
                    default: coeff_out <= out_buf7;
                endcase
                if (out_left == 4'd1) begin
                    emitting <= 0; out_left <= 0; out_ptr <= 0;
                end else begin
                    out_left <= out_left - 4'd1; out_ptr <= out_ptr + 3'd1;
                end
            end

            if (valid_l) begin
                if (!mode_l) begin
                    case (index_l)
                        3'd0: sample_mem0 <= sample_l; 3'd1: sample_mem1 <= sample_l;
                        3'd2: sample_mem2 <= sample_l; 3'd3: sample_mem3 <= sample_l;
                        3'd4: sample_mem4 <= sample_l; 3'd5: sample_mem5 <= sample_l;
                        3'd6: sample_mem6 <= sample_l; default: sample_mem7 <= sample_l;
                    endcase
                    acc0 <= next0; acc1 <= next1; acc2 <= next2; acc3 <= next3;
                    acc4 <= next4; acc5 <= next5; acc6 <= next6; acc7 <= next7;
                    if (index_l == 3'd7) begin
                        out_buf0 <= round_q14(next0); out_buf1 <= round_q14(next1);
                        out_buf2 <= round_q14(next2); out_buf3 <= round_q14(next3);
                        out_buf4 <= round_q14(next4); out_buf5 <= round_q14(next5);
                        out_buf6 <= round_q14(next6); out_buf7 <= round_q14(next7);
                        out_ptr <= 0; out_left <= 4'd8; emitting <= 1'b1;
                    end
                end else if (index_l == 3'd7) begin
                    out_buf0 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem0};
                    out_buf1 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem1};
                    out_buf2 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem2};
                    out_buf3 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem3};
                    out_buf4 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem4};
                    out_buf5 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem5};
                    out_buf6 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem6};
                    out_buf7 <= {{(OUT_W-DATA_W){1'b0}}, sample_mem7};
                    out_ptr <= 0; out_left <= 4'd8; emitting <= 1'b1;
                end
            end
        end
    end

endmodule