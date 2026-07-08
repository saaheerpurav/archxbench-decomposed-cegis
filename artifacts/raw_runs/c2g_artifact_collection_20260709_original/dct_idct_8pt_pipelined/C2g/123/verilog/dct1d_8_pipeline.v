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
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam N = 8;
    localparam FRAC_W = 14;
    localparam ACC_W = DATA_W + COEFF_W + 5;

    reg signed [DATA_W-1:0] sample_buf [0:N-1];

    reg [3:0] load_count;
    reg computing;
    reg compute_mode;
    reg [2:0] out_idx;

    reg signed [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    integer i;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    function signed [COEFF_W-1:0] dct_coeff;
        input [2:0] k;
        input [2:0] n;
        begin
            case ({k,n})
                6'o00: dct_coeff = 16'sd5793;
                6'o01: dct_coeff = 16'sd5793;
                6'o02: dct_coeff = 16'sd5793;
                6'o03: dct_coeff = 16'sd5793;
                6'o04: dct_coeff = 16'sd5793;
                6'o05: dct_coeff = 16'sd5793;
                6'o06: dct_coeff = 16'sd5793;
                6'o07: dct_coeff = 16'sd5793;

                6'o10: dct_coeff = 16'sd8035;
                6'o11: dct_coeff = 16'sd6811;
                6'o12: dct_coeff = 16'sd4551;
                6'o13: dct_coeff = 16'sd1598;
                6'o14: dct_coeff = -16'sd1598;
                6'o15: dct_coeff = -16'sd4551;
                6'o16: dct_coeff = -16'sd6811;
                6'o17: dct_coeff = -16'sd8035;

                6'o20: dct_coeff = 16'sd7568;
                6'o21: dct_coeff = 16'sd3135;
                6'o22: dct_coeff = -16'sd3135;
                6'o23: dct_coeff = -16'sd7568;
                6'o24: dct_coeff = -16'sd7568;
                6'o25: dct_coeff = -16'sd3135;
                6'o26: dct_coeff = 16'sd3135;
                6'o27: dct_coeff = 16'sd7568;

                6'o30: dct_coeff = 16'sd6811;
                6'o31: dct_coeff = -16'sd1598;
                6'o32: dct_coeff = -16'sd8035;
                6'o33: dct_coeff = -16'sd4551;
                6'o34: dct_coeff = 16'sd4551;
                6'o35: dct_coeff = 16'sd8035;
                6'o36: dct_coeff = 16'sd1598;
                6'o37: dct_coeff = -16'sd6811;

                6'o40: dct_coeff = 16'sd5793;
                6'o41: dct_coeff = -16'sd5793;
                6'o42: dct_coeff = -16'sd5793;
                6'o43: dct_coeff = 16'sd5793;
                6'o44: dct_coeff = 16'sd5793;
                6'o45: dct_coeff = -16'sd5793;
                6'o46: dct_coeff = -16'sd5793;
                6'o47: dct_coeff = 16'sd5793;

                6'o50: dct_coeff = 16'sd4551;
                6'o51: dct_coeff = -16'sd8035;
                6'o52: dct_coeff = 16'sd1598;
                6'o53: dct_coeff = 16'sd6811;
                6'o54: dct_coeff = -16'sd6811;
                6'o55: dct_coeff = -16'sd1598;
                6'o56: dct_coeff = 16'sd8035;
                6'o57: dct_coeff = -16'sd4551;

                6'o60: dct_coeff = 16'sd3135;
                6'o61: dct_coeff = -16'sd7568;
                6'o62: dct_coeff = 16'sd7568;
                6'o63: dct_coeff = -16'sd3135;
                6'o64: dct_coeff = -16'sd3135;
                6'o65: dct_coeff = 16'sd7568;
                6'o66: dct_coeff = -16'sd7568;
                6'o67: dct_coeff = 16'sd3135;

                6'o70: dct_coeff = 16'sd1598;
                6'o71: dct_coeff = -16'sd4551;
                6'o72: dct_coeff = 16'sd6811;
                6'o73: dct_coeff = -16'sd8035;
                6'o74: dct_coeff = 16'sd8035;
                6'o75: dct_coeff = -16'sd6811;
                6'o76: dct_coeff = 16'sd4551;
                6'o77: dct_coeff = -16'sd1598;

                default: dct_coeff = {COEFF_W{1'b0}};
            endcase
        end
    endfunction

    function signed [OUT_W-1:0] sat_out;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] max_val;
        reg signed [ACC_W-1:0] min_val;
        begin
            max_val = ({{(ACC_W-OUT_W){1'b0}}, {1'b0, {(OUT_W-1){1'b1}}}});
            min_val = -({{(ACC_W-OUT_W){1'b0}}, {1'b1, {(OUT_W-1){1'b0}}}});
            if (value > max_val)
                sat_out = {1'b0, {(OUT_W-1){1'b1}}};
            else if (value < min_val)
                sat_out = {1'b1, {(OUT_W-1){1'b0}}};
            else
                sat_out = value[OUT_W-1:0];
        end
    endfunction

    function signed [OUT_W-1:0] transform_value;
        input op_mode;
        input [2:0] out_index;
        reg signed [ACC_W-1:0] acc;
        reg signed [ACC_W-1:0] rounded;
        reg signed [ACC_W-1:0] shifted;
        integer j;
        begin
            acc = {ACC_W{1'b0}};
            for (j = 0; j < N; j = j + 1) begin
                if (op_mode == 1'b0)
                    acc = acc + sample_buf[j] * dct_coeff(out_index, j[2:0]);
                else
                    acc = acc + sample_buf[j] * dct_coeff(j[2:0], out_index);
            end

            rounded = acc + ({{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}});
            shifted = rounded >>> FRAC_W;
            transform_value = sat_out(shifted);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            load_count <= 4'd0;
            computing <= 1'b0;
            compute_mode <= 1'b0;
            out_idx <= 3'd0;
            coeff_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            index_out_r <= 3'd0;
            for (i = 0; i < N; i = i + 1)
                sample_buf[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in && !computing) begin
                sample_buf[index] <= sample_in;

                if (load_count == 4'd7) begin
                    load_count <= 4'd0;
                    computing <= 1'b1;
                    compute_mode <= mode;
                    out_idx <= 3'd0;
                end else begin
                    load_count <= load_count + 4'd1;
                end
            end

            if (computing) begin
                coeff_out_r <= transform_value(compute_mode, out_idx);
                valid_out_r <= 1'b1;
                index_out_r <= out_idx;

                if (out_idx == 3'd7) begin
                    computing <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule