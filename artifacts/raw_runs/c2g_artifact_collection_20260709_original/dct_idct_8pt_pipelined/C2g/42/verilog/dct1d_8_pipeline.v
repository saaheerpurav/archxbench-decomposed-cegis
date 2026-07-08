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
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output reg [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam FRAC_W = 14;
    localparam ACC_W  = DATA_W + COEFF_W + 4;

    reg signed [DATA_W-1:0] sample_buf [0:7];
    reg signed [DATA_W-1:0] active_buf [0:7];

    reg active_mode;
    reg pending_mode;
    reg [3:0] in_count;
    reg busy;
    reg [2:0] out_idx;

    integer i;

    function signed [COEFF_W-1:0] dct_coeff;
        input [2:0] row;
        input [2:0] col;
        begin
            case (row)
                3'd0: dct_coeff = 16'sd5793;

                3'd1: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd8035;
                        3'd1: dct_coeff = 16'sd6811;
                        3'd2: dct_coeff = 16'sd4551;
                        3'd3: dct_coeff = 16'sd1598;
                        3'd4: dct_coeff = -16'sd1598;
                        3'd5: dct_coeff = -16'sd4551;
                        3'd6: dct_coeff = -16'sd6811;
                        default: dct_coeff = -16'sd8035;
                    endcase
                end

                3'd2: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd7568;
                        3'd1: dct_coeff = 16'sd3135;
                        3'd2: dct_coeff = -16'sd3135;
                        3'd3: dct_coeff = -16'sd7568;
                        3'd4: dct_coeff = -16'sd7568;
                        3'd5: dct_coeff = -16'sd3135;
                        3'd6: dct_coeff = 16'sd3135;
                        default: dct_coeff = 16'sd7568;
                    endcase
                end

                3'd3: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd6811;
                        3'd1: dct_coeff = -16'sd1598;
                        3'd2: dct_coeff = -16'sd8035;
                        3'd3: dct_coeff = -16'sd4551;
                        3'd4: dct_coeff = 16'sd4551;
                        3'd5: dct_coeff = 16'sd8035;
                        3'd6: dct_coeff = 16'sd1598;
                        default: dct_coeff = -16'sd6811;
                    endcase
                end

                3'd4: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd5793;
                        3'd1: dct_coeff = -16'sd5793;
                        3'd2: dct_coeff = -16'sd5793;
                        3'd3: dct_coeff = 16'sd5793;
                        3'd4: dct_coeff = 16'sd5793;
                        3'd5: dct_coeff = -16'sd5793;
                        3'd6: dct_coeff = -16'sd5793;
                        default: dct_coeff = 16'sd5793;
                    endcase
                end

                3'd5: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd4551;
                        3'd1: dct_coeff = -16'sd8035;
                        3'd2: dct_coeff = 16'sd1598;
                        3'd3: dct_coeff = 16'sd6811;
                        3'd4: dct_coeff = -16'sd6811;
                        3'd5: dct_coeff = -16'sd1598;
                        3'd6: dct_coeff = 16'sd8035;
                        default: dct_coeff = -16'sd4551;
                    endcase
                end

                3'd6: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd3135;
                        3'd1: dct_coeff = -16'sd7568;
                        3'd2: dct_coeff = 16'sd7568;
                        3'd3: dct_coeff = -16'sd3135;
                        3'd4: dct_coeff = -16'sd3135;
                        3'd5: dct_coeff = 16'sd7568;
                        3'd6: dct_coeff = -16'sd7568;
                        default: dct_coeff = 16'sd3135;
                    endcase
                end

                default: begin
                    case (col)
                        3'd0: dct_coeff = 16'sd1598;
                        3'd1: dct_coeff = -16'sd4551;
                        3'd2: dct_coeff = 16'sd6811;
                        3'd3: dct_coeff = -16'sd8035;
                        3'd4: dct_coeff = 16'sd8035;
                        3'd5: dct_coeff = -16'sd6811;
                        3'd6: dct_coeff = 16'sd4551;
                        default: dct_coeff = -16'sd1598;
                    endcase
                end
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] matrix_coeff;
        input use_idct;
        input [2:0] out_index;
        input [2:0] in_index;
        begin
            if (use_idct)
                matrix_coeff = dct_coeff(in_index, out_index);
            else
                matrix_coeff = dct_coeff(out_index, in_index);
        end
    endfunction

    function signed [OUT_W-1:0] saturate_out;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] max_val;
        reg signed [ACC_W-1:0] min_val;
        begin
            max_val = ({{(ACC_W-OUT_W){1'b0}}, {1'b0, {(OUT_W-1){1'b1}}}});
            min_val = -({{(ACC_W-OUT_W){1'b0}}, {1'b1, {(OUT_W-1){1'b0}}}});

            if (value > max_val)
                saturate_out = {1'b0, {(OUT_W-1){1'b1}}};
            else if (value < min_val)
                saturate_out = {1'b1, {(OUT_W-1){1'b0}}};
            else
                saturate_out = value[OUT_W-1:0];
        end
    endfunction

    function signed [OUT_W-1:0] compute_output;
        input use_idct;
        input [2:0] out_index;
        reg signed [ACC_W-1:0] acc;
        reg signed [ACC_W-1:0] rounded;
        integer j;
        begin
            acc = {ACC_W{1'b0}};
            for (j = 0; j < 8; j = j + 1) begin
                acc = acc + active_buf[j] * matrix_coeff(use_idct, out_index, j[2:0]);
            end

            if (acc >= 0)
                rounded = (acc + (1 <<< (FRAC_W-1))) >>> FRAC_W;
            else
                rounded = -(((-acc) + (1 <<< (FRAC_W-1))) >>> FRAC_W);

            compute_output = saturate_out(rounded);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            coeff_out    <= {OUT_W{1'b0}};
            valid_out    <= 1'b0;
            index_out    <= 3'd0;
            in_count     <= 4'd0;
            busy         <= 1'b0;
            out_idx      <= 3'd0;
            active_mode  <= 1'b0;
            pending_mode <= 1'b0;

            for (i = 0; i < 8; i = i + 1) begin
                sample_buf[i] <= {DATA_W{1'b0}};
                active_buf[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                sample_buf[index] <= sample_in;
                pending_mode <= mode;

                if (in_count == 4'd0)
                    pending_mode <= mode;

                if (index == 3'd7 || in_count == 4'd7) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (i[2:0] == index)
                            active_buf[i] <= sample_in;
                        else
                            active_buf[i] <= sample_buf[i];
                    end

                    active_mode <= mode;
                    busy <= 1'b1;
                    out_idx <= 3'd0;
                    in_count <= 4'd0;
                end else begin
                    in_count <= in_count + 4'd1;
                end
            end

            if (busy) begin
                coeff_out <= compute_output(active_mode, out_idx);
                index_out <= out_idx;
                valid_out <= 1'b1;

                if (out_idx == 3'd7) begin
                    busy <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule