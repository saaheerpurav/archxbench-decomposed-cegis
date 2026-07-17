module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam FRAC_W = 14;
    localparam ACC_W  = DATA_W + COEFF_W + 4;

    reg signed [ACC_W-1:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7;
    reg signed [OUT_W-1:0] out_buf0, out_buf1, out_buf2, out_buf3;
    reg signed [OUT_W-1:0] out_buf4, out_buf5, out_buf6, out_buf7;
    reg [2:0] out_count;
    reg out_active;
    reg valid_r;
    reg [2:0] index_r;
    reg signed [OUT_W-1:0] coeff_r;

    wire signed [DATA_W-1:0] sample_s = sample_in;

    assign coeff_out = coeff_r;
    assign valid_out = valid_r;
    assign index_out = index_r;

    function signed [COEFF_W-1:0] dct_coeff;
        input [2:0] k;
        input [2:0] n;
        begin
            case ({k,n})
                6'o00: dct_coeff =  5793; 6'o01: dct_coeff =  5793; 6'o02: dct_coeff =  5793; 6'o03: dct_coeff =  5793;
                6'o04: dct_coeff =  5793; 6'o05: dct_coeff =  5793; 6'o06: dct_coeff =  5793; 6'o07: dct_coeff =  5793;

                6'o10: dct_coeff =  8035; 6'o11: dct_coeff =  6811; 6'o12: dct_coeff =  4551; 6'o13: dct_coeff =  1598;
                6'o14: dct_coeff = -1598; 6'o15: dct_coeff = -4551; 6'o16: dct_coeff = -6811; 6'o17: dct_coeff = -8035;

                6'o20: dct_coeff =  7568; 6'o21: dct_coeff =  3135; 6'o22: dct_coeff = -3135; 6'o23: dct_coeff = -7568;
                6'o24: dct_coeff = -7568; 6'o25: dct_coeff = -3135; 6'o26: dct_coeff =  3135; 6'o27: dct_coeff =  7568;

                6'o30: dct_coeff =  6811; 6'o31: dct_coeff = -1598; 6'o32: dct_coeff = -8035; 6'o33: dct_coeff = -4551;
                6'o34: dct_coeff =  4551; 6'o35: dct_coeff =  8035; 6'o36: dct_coeff =  1598; 6'o37: dct_coeff = -6811;

                6'o40: dct_coeff =  5793; 6'o41: dct_coeff = -5793; 6'o42: dct_coeff = -5793; 6'o43: dct_coeff =  5793;
                6'o44: dct_coeff =  5793; 6'o45: dct_coeff = -5793; 6'o46: dct_coeff = -5793; 6'o47: dct_coeff =  5793;

                6'o50: dct_coeff =  4551; 6'o51: dct_coeff = -8035; 6'o52: dct_coeff =  1598; 6'o53: dct_coeff =  6811;
                6'o54: dct_coeff = -6811; 6'o55: dct_coeff = -1598; 6'o56: dct_coeff =  8035; 6'o57: dct_coeff = -4551;

                6'o60: dct_coeff =  3135; 6'o61: dct_coeff = -7568; 6'o62: dct_coeff =  7568; 6'o63: dct_coeff = -3135;
                6'o64: dct_coeff = -3135; 6'o65: dct_coeff =  7568; 6'o66: dct_coeff = -7568; 6'o67: dct_coeff =  3135;

                6'o70: dct_coeff =  1598; 6'o71: dct_coeff = -4551; 6'o72: dct_coeff =  6811; 6'o73: dct_coeff = -8035;
                6'o74: dct_coeff =  8035; 6'o75: dct_coeff = -6811; 6'o76: dct_coeff =  4551; 6'o77: dct_coeff = -1598;
                default: dct_coeff = 0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] coeff_sel;
        input mode_i;
        input [2:0] out_i;
        input [2:0] in_i;
        begin
            if (mode_i)
                coeff_sel = dct_coeff(in_i, out_i);
            else
                coeff_sel = dct_coeff(out_i, in_i);
        end
    endfunction

    function signed [OUT_W-1:0] sat_round;
        input signed [ACC_W-1:0] v;
        reg signed [ACC_W-1:0] rounded;
        reg signed [ACC_W-1:0] shifted;
        reg signed [ACC_W-1:0] max_v;
        reg signed [ACC_W-1:0] min_v;
        begin
            rounded = v + ({{(ACC_W-1){1'b0}},1'b1} << (FRAC_W-1));
            shifted = rounded >>> FRAC_W;
            max_v = ({{(ACC_W-OUT_W){1'b0}}, {1'b0, {(OUT_W-1){1'b1}}}});
            min_v = -({{(ACC_W-OUT_W){1'b0}}, {1'b1, {(OUT_W-1){1'b0}}}});
            if (shifted > max_v)
                sat_round = {1'b0, {(OUT_W-1){1'b1}}};
            else if (shifted < min_v)
                sat_round = {1'b1, {(OUT_W-1){1'b0}}};
            else
                sat_round = shifted[OUT_W-1:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            acc0 <= 0; acc1 <= 0; acc2 <= 0; acc3 <= 0;
            acc4 <= 0; acc5 <= 0; acc6 <= 0; acc7 <= 0;
            out_buf0 <= 0; out_buf1 <= 0; out_buf2 <= 0; out_buf3 <= 0;
            out_buf4 <= 0; out_buf5 <= 0; out_buf6 <= 0; out_buf7 <= 0;
            out_count <= 0;
            out_active <= 1'b0;
            valid_r <= 1'b0;
            index_r <= 0;
            coeff_r <= 0;
        end else begin
            valid_r <= out_active;
            index_r <= out_count;

            case (out_count)
                3'd0: coeff_r <= out_buf0;
                3'd1: coeff_r <= out_buf1;
                3'd2: coeff_r <= out_buf2;
                3'd3: coeff_r <= out_buf3;
                3'd4: coeff_r <= out_buf4;
                3'd5: coeff_r <= out_buf5;
                3'd6: coeff_r <= out_buf6;
                default: coeff_r <= out_buf7;
            endcase

            if (out_active) begin
                if (out_count == 3'd7) begin
                    out_active <= 1'b0;
                    out_count <= 3'd0;
                end else begin
                    out_count <= out_count + 3'd1;
                end
            end

            if (valid_in) begin
                if (index == 3'd0) begin
                    acc0 <= sample_s * coeff_sel(mode, 3'd0, index);
                    acc1 <= sample_s * coeff_sel(mode, 3'd1, index);
                    acc2 <= sample_s * coeff_sel(mode, 3'd2, index);
                    acc3 <= sample_s * coeff_sel(mode, 3'd3, index);
                    acc4 <= sample_s * coeff_sel(mode, 3'd4, index);
                    acc5 <= sample_s * coeff_sel(mode, 3'd5, index);
                    acc6 <= sample_s * coeff_sel(mode, 3'd6, index);
                    acc7 <= sample_s * coeff_sel(mode, 3'd7, index);
                end else begin
                    acc0 <= acc0 + sample_s * coeff_sel(mode, 3'd0, index);
                    acc1 <= acc1 + sample_s * coeff_sel(mode, 3'd1, index);
                    acc2 <= acc2 + sample_s * coeff_sel(mode, 3'd2, index);
                    acc3 <= acc3 + sample_s * coeff_sel(mode, 3'd3, index);
                    acc4 <= acc4 + sample_s * coeff_sel(mode, 3'd4, index);
                    acc5 <= acc5 + sample_s * coeff_sel(mode, 3'd5, index);
                    acc6 <= acc6 + sample_s * coeff_sel(mode, 3'd6, index);
                    acc7 <= acc7 + sample_s * coeff_sel(mode, 3'd7, index);
                end

                if (index == 3'd7) begin
                    out_buf0 <= sat_round(acc0 + sample_s * coeff_sel(mode, 3'd0, index));
                    out_buf1 <= sat_round(acc1 + sample_s * coeff_sel(mode, 3'd1, index));
                    out_buf2 <= sat_round(acc2 + sample_s * coeff_sel(mode, 3'd2, index));
                    out_buf3 <= sat_round(acc3 + sample_s * coeff_sel(mode, 3'd3, index));
                    out_buf4 <= sat_round(acc4 + sample_s * coeff_sel(mode, 3'd4, index));
                    out_buf5 <= sat_round(acc5 + sample_s * coeff_sel(mode, 3'd5, index));
                    out_buf6 <= sat_round(acc6 + sample_s * coeff_sel(mode, 3'd6, index));
                    out_buf7 <= sat_round(acc7 + sample_s * coeff_sel(mode, 3'd7, index));
                    out_active <= 1'b1;
                    out_count <= 3'd0;
                end
            end
        end
    end

endmodule