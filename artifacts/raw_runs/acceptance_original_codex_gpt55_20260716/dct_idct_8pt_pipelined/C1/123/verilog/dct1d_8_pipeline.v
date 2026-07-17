module dct1d_8_pipeline #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter OUT_W   = 18
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
localparam ACC_W  = DATA_W + COEFF_W + 6;

reg signed [DATA_W-1:0] buf0 [0:7];
reg signed [DATA_W-1:0] buf1 [0:7];

reg wr_bank;
reg rd_bank;
reg ready0;
reg ready1;
reg mode0;
reg mode1;

reg active;
reg [2:0] calc_idx;

reg signed [OUT_W-1:0] coeff_out_r;
reg valid_out_r;
reg [2:0] index_out_r;

assign coeff_out = coeff_out_r;
assign valid_out = valid_out_r;
assign index_out = index_out_r;

function signed [COEFF_W-1:0] dct_c;
    input [2:0] k;
    input [2:0] n;
    begin
        case ({k,n})
            6'o00: dct_c = 16'sd5793;   6'o01: dct_c = 16'sd5793;
            6'o02: dct_c = 16'sd5793;   6'o03: dct_c = 16'sd5793;
            6'o04: dct_c = 16'sd5793;   6'o05: dct_c = 16'sd5793;
            6'o06: dct_c = 16'sd5793;   6'o07: dct_c = 16'sd5793;

            6'o10: dct_c = 16'sd8035;   6'o11: dct_c = 16'sd6811;
            6'o12: dct_c = 16'sd4551;   6'o13: dct_c = 16'sd1598;
            6'o14: dct_c = -16'sd1598;  6'o15: dct_c = -16'sd4551;
            6'o16: dct_c = -16'sd6811;  6'o17: dct_c = -16'sd8035;

            6'o20: dct_c = 16'sd7568;   6'o21: dct_c = 16'sd3135;
            6'o22: dct_c = -16'sd3135;  6'o23: dct_c = -16'sd7568;
            6'o24: dct_c = -16'sd7568;  6'o25: dct_c = -16'sd3135;
            6'o26: dct_c = 16'sd3135;   6'o27: dct_c = 16'sd7568;

            6'o30: dct_c = 16'sd6811;   6'o31: dct_c = -16'sd1598;
            6'o32: dct_c = -16'sd8035;  6'o33: dct_c = -16'sd4551;
            6'o34: dct_c = 16'sd4551;   6'o35: dct_c = 16'sd8035;
            6'o36: dct_c = 16'sd1598;   6'o37: dct_c = -16'sd6811;

            6'o40: dct_c = 16'sd5793;   6'o41: dct_c = -16'sd5793;
            6'o42: dct_c = -16'sd5793;  6'o43: dct_c = 16'sd5793;
            6'o44: dct_c = 16'sd5793;   6'o45: dct_c = -16'sd5793;
            6'o46: dct_c = -16'sd5793;  6'o47: dct_c = 16'sd5793;

            6'o50: dct_c = 16'sd4551;   6'o51: dct_c = -16'sd8035;
            6'o52: dct_c = 16'sd1598;   6'o53: dct_c = 16'sd6811;
            6'o54: dct_c = -16'sd6811;  6'o55: dct_c = -16'sd1598;
            6'o56: dct_c = 16'sd8035;   6'o57: dct_c = -16'sd4551;

            6'o60: dct_c = 16'sd3135;   6'o61: dct_c = -16'sd7568;
            6'o62: dct_c = 16'sd7568;   6'o63: dct_c = -16'sd3135;
            6'o64: dct_c = -16'sd3135;  6'o65: dct_c = 16'sd7568;
            6'o66: dct_c = -16'sd7568;  6'o67: dct_c = 16'sd3135;

            6'o70: dct_c = 16'sd1598;   6'o71: dct_c = -16'sd4551;
            6'o72: dct_c = 16'sd6811;   6'o73: dct_c = -16'sd8035;
            6'o74: dct_c = 16'sd8035;   6'o75: dct_c = -16'sd6811;
            6'o76: dct_c = 16'sd4551;   6'o77: dct_c = -16'sd1598;
            default: dct_c = {COEFF_W{1'b0}};
        endcase
    end
endfunction

function signed [COEFF_W-1:0] mat_c;
    input inv;
    input [2:0] row;
    input [2:0] col;
    begin
        mat_c = inv ? dct_c(col, row) : dct_c(row, col);
    end
endfunction

function signed [OUT_W-1:0] sat_out;
    input signed [ACC_W-1:0] val;
    reg signed [ACC_W-1:0] max_v;
    reg signed [ACC_W-1:0] min_v;
    begin
        max_v = ({{(ACC_W-OUT_W){1'b0}}, 1'b0, {(OUT_W-1){1'b1}}});
        min_v = ({{(ACC_W-OUT_W){1'b1}}, 1'b1, {(OUT_W-1){1'b0}}});
        if (val > max_v)
            sat_out = {1'b0, {(OUT_W-1){1'b1}}};
        else if (val < min_v)
            sat_out = {1'b1, {(OUT_W-1){1'b0}}};
        else
            sat_out = val[OUT_W-1:0];
    end
endfunction

function signed [OUT_W-1:0] calc_dot;
    input bank;
    input inv;
    input [2:0] row;
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] rounded;
    begin
        if (bank == 1'b0) begin
            acc =
                $signed(buf0[0]) * $signed(mat_c(inv,row,3'd0)) +
                $signed(buf0[1]) * $signed(mat_c(inv,row,3'd1)) +
                $signed(buf0[2]) * $signed(mat_c(inv,row,3'd2)) +
                $signed(buf0[3]) * $signed(mat_c(inv,row,3'd3)) +
                $signed(buf0[4]) * $signed(mat_c(inv,row,3'd4)) +
                $signed(buf0[5]) * $signed(mat_c(inv,row,3'd5)) +
                $signed(buf0[6]) * $signed(mat_c(inv,row,3'd6)) +
                $signed(buf0[7]) * $signed(mat_c(inv,row,3'd7));
        end else begin
            acc =
                $signed(buf1[0]) * $signed(mat_c(inv,row,3'd0)) +
                $signed(buf1[1]) * $signed(mat_c(inv,row,3'd1)) +
                $signed(buf1[2]) * $signed(mat_c(inv,row,3'd2)) +
                $signed(buf1[3]) * $signed(mat_c(inv,row,3'd3)) +
                $signed(buf1[4]) * $signed(mat_c(inv,row,3'd4)) +
                $signed(buf1[5]) * $signed(mat_c(inv,row,3'd5)) +
                $signed(buf1[6]) * $signed(mat_c(inv,row,3'd6)) +
                $signed(buf1[7]) * $signed(mat_c(inv,row,3'd7));
        end

        rounded = acc + (acc[ACC_W-1] ? -$signed({{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}})
                                      :  $signed({{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}}));
        calc_dot = sat_out(rounded >>> FRAC_W);
    end
endfunction

always @(posedge clk) begin
    if (rst) begin
        wr_bank <= 1'b0;
        rd_bank <= 1'b0;
        ready0 <= 1'b0;
        ready1 <= 1'b0;
        mode0 <= 1'b0;
        mode1 <= 1'b0;
        active <= 1'b0;
        calc_idx <= 3'd0;
        coeff_out_r <= {OUT_W{1'b0}};
        valid_out_r <= 1'b0;
        index_out_r <= 3'd0;
    end else begin
        valid_out_r <= 1'b0;

        if (valid_in) begin
            if (wr_bank == 1'b0) begin
                buf0[index] <= $signed(sample_in);
                if (index == 3'd0)
                    mode0 <= mode;
                if (index == 3'd7) begin
                    ready0 <= 1'b1;
                    wr_bank <= 1'b1;
                end
            end else begin
                buf1[index] <= $signed(sample_in);
                if (index == 3'd0)
                    mode1 <= mode;
                if (index == 3'd7) begin
                    ready1 <= 1'b1;
                    wr_bank <= 1'b0;
                end
            end
        end

        if (active) begin
            coeff_out_r <= calc_dot(rd_bank, (rd_bank == 1'b0) ? mode0 : mode1, calc_idx);
            index_out_r <= calc_idx;
            valid_out_r <= 1'b1;

            if (calc_idx == 3'd7) begin
                if (rd_bank == 1'b0)
                    ready0 <= 1'b0;
                else
                    ready1 <= 1'b0;

                if ((rd_bank == 1'b0 && ready1) || (rd_bank == 1'b1 && ready0)) begin
                    rd_bank <= ~rd_bank;
                    calc_idx <= 3'd0;
                    active <= 1'b1;
                end else begin
                    calc_idx <= 3'd0;
                    active <= 1'b0;
                end
            end else begin
                calc_idx <= calc_idx + 3'd1;
            end
        end else begin
            if (ready0) begin
                rd_bank <= 1'b0;
                calc_idx <= 3'd0;
                active <= 1'b1;
            end else if (ready1) begin
                rd_bank <= 1'b1;
                calc_idx <= 3'd0;
                active <= 1'b1;
            end
        end
    end
end

endmodule