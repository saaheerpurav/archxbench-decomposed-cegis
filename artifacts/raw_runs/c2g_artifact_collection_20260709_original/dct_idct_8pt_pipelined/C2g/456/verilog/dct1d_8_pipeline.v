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
    output reg [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam FRAC_W = 14;
    localparam ACC_W  = DATA_W + COEFF_W + 6;

    reg signed [DATA_W-1:0] samples [0:7];
    reg signed [OUT_W-1:0]  results [0:7];

    reg [3:0] out_count;
    reg [2:0] out_idx;

    integer i;
    integer k;
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] rounded;

    function signed [COEFF_W-1:0] dct_c;
        input [2:0] r;
        input [2:0] n;
        begin
            case (r)
                3'd0: dct_c = 16'sd5793;
                3'd1: case (n)
                    3'd0: dct_c = 16'sd8035; 3'd1: dct_c = 16'sd6811;
                    3'd2: dct_c = 16'sd4551; 3'd3: dct_c = 16'sd1598;
                    3'd4: dct_c = -16'sd1598; 3'd5: dct_c = -16'sd4551;
                    3'd6: dct_c = -16'sd6811; default: dct_c = -16'sd8035;
                endcase
                3'd2: case (n)
                    3'd0: dct_c = 16'sd7568; 3'd1: dct_c = 16'sd3135;
                    3'd2: dct_c = -16'sd3135; 3'd3: dct_c = -16'sd7568;
                    3'd4: dct_c = -16'sd7568; 3'd5: dct_c = -16'sd3135;
                    3'd6: dct_c = 16'sd3135; default: dct_c = 16'sd7568;
                endcase
                3'd3: case (n)
                    3'd0: dct_c = 16'sd6811; 3'd1: dct_c = -16'sd1598;
                    3'd2: dct_c = -16'sd8035; 3'd3: dct_c = -16'sd4551;
                    3'd4: dct_c = 16'sd4551; 3'd5: dct_c = 16'sd8035;
                    3'd6: dct_c = 16'sd1598; default: dct_c = -16'sd6811;
                endcase
                3'd4: case (n)
                    3'd0: dct_c = 16'sd5793; 3'd1: dct_c = -16'sd5793;
                    3'd2: dct_c = -16'sd5793; 3'd3: dct_c = 16'sd5793;
                    3'd4: dct_c = 16'sd5793; 3'd5: dct_c = -16'sd5793;
                    3'd6: dct_c = -16'sd5793; default: dct_c = 16'sd5793;
                endcase
                3'd5: case (n)
                    3'd0: dct_c = 16'sd4551; 3'd1: dct_c = -16'sd8035;
                    3'd2: dct_c = 16'sd1598; 3'd3: dct_c = 16'sd6811;
                    3'd4: dct_c = -16'sd6811; 3'd5: dct_c = -16'sd1598;
                    3'd6: dct_c = 16'sd8035; default: dct_c = -16'sd4551;
                endcase
                3'd6: case (n)
                    3'd0: dct_c = 16'sd3135; 3'd1: dct_c = -16'sd7568;
                    3'd2: dct_c = 16'sd7568; 3'd3: dct_c = -16'sd3135;
                    3'd4: dct_c = -16'sd3135; 3'd5: dct_c = 16'sd7568;
                    3'd6: dct_c = -16'sd7568; default: dct_c = 16'sd3135;
                endcase
                default: case (n)
                    3'd0: dct_c = 16'sd1598; 3'd1: dct_c = -16'sd4551;
                    3'd2: dct_c = 16'sd6811; 3'd3: dct_c = -16'sd8035;
                    3'd4: dct_c = 16'sd8035; 3'd5: dct_c = -16'sd6811;
                    3'd6: dct_c = 16'sd4551; default: dct_c = -16'sd1598;
                endcase
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] mat_c;
        input idct;
        input [2:0] out_i;
        input [2:0] in_i;
        begin
            mat_c = idct ? dct_c(in_i, out_i) : dct_c(out_i, in_i);
        end
    endfunction

    function signed [OUT_W-1:0] sat;
        input signed [ACC_W-1:0] v;
        reg signed [ACC_W-1:0] max_v;
        reg signed [ACC_W-1:0] min_v;
        begin
            max_v = (1 <<< (OUT_W-1)) - 1;
            min_v = -(1 <<< (OUT_W-1));
            if (v > max_v)
                sat = {1'b0, {(OUT_W-1){1'b1}}};
            else if (v < min_v)
                sat = {1'b1, {(OUT_W-1){1'b0}}};
            else
                sat = v[OUT_W-1:0];
        end
    endfunction

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            coeff_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            index_out <= 3'd0;
            out_count <= 4'd0;
            out_idx <= 3'd0;
            for (i = 0; i < 8; i = i + 1) begin
                samples[i] <= {DATA_W{1'b0}};
                results[i] <= {OUT_W{1'b0}};
            end
        end else begin
            valid_out <= 1'b0;

            if (out_count != 4'd0) begin
                coeff_out <= results[out_idx];
                index_out <= out_idx;
                valid_out <= 1'b1;
                out_count <= out_count - 4'd1;
                out_idx <= out_idx + 3'd1;
            end

            if (valid_in) begin
                samples[index] <= sample_in;

                if (index == 3'd7) begin
                    for (k = 0; k < 8; k = k + 1) begin
                        acc = $signed(sample_in) * mat_c(mode, k[2:0], 3'd7);
                        for (i = 0; i < 7; i = i + 1)
                            acc = acc + ($signed(samples[i]) * mat_c(mode, k[2:0], i[2:0]));

                        if (acc >= 0)
                            rounded = (acc + (1 <<< (FRAC_W-1))) >>> FRAC_W;
                        else
                            rounded = -(((-acc) + (1 <<< (FRAC_W-1))) >>> FRAC_W);

                        results[k] <= sat(rounded);
                    end

                    out_count <= 4'd8;
                    out_idx <= 3'd0;
                end
            end
        end
    end

endmodule