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
localparam PROD_W = DATA_W + COEFF_W;
localparam ACC_W  = PROD_W + 4;

reg signed [DATA_W-1:0] bank0 [0:7];
reg signed [DATA_W-1:0] bank1 [0:7];

reg write_bank;
reg compute_req;
reg compute_bank;
reg compute_mode;

reg signed [ACC_W-1:0] sum0_r, sum1_r, sum2_r, sum3_r;
reg signed [ACC_W-1:0] sum4_r, sum5_r, sum6_r, sum7_r;
reg sums_valid_r;

reg signed [OUT_W-1:0] out_buf [0:7];
reg [2:0] out_count;
reg out_active;
reg valid_out_r;
reg [2:0] index_out_r;
reg signed [OUT_W-1:0] coeff_out_r;

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

function signed [COEFF_W-1:0] xform_coeff;
    input mode_sel;
    input [2:0] out_idx;
    input [2:0] in_idx;
    begin
        if (mode_sel)
            xform_coeff = dct_coeff(in_idx, out_idx);
        else
            xform_coeff = dct_coeff(out_idx, in_idx);
    end
endfunction

function signed [DATA_W-1:0] bank_sample;
    input bank_sel;
    input [2:0] sample_idx;
    begin
        if (bank_sel)
            bank_sample = bank1[sample_idx];
        else
            bank_sample = bank0[sample_idx];
    end
endfunction

function signed [OUT_W-1:0] round_sat;
    input signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] rounded;
    reg signed [ACC_W-1:0] scaled;
    reg signed [ACC_W-1:0] max_val;
    reg signed [ACC_W-1:0] min_val;
    begin
        rounded = acc + ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));
        scaled = rounded >>> FRAC_W;
        max_val = ({{(ACC_W-OUT_W+1){1'b0}}, {(OUT_W-1){1'b1}}});
        min_val = -({{(ACC_W-OUT_W+1){1'b0}}, 1'b1, {(OUT_W-1){1'b0}}});
        if (scaled > max_val)
            round_sat = {1'b0, {(OUT_W-1){1'b1}}};
        else if (scaled < min_val)
            round_sat = {1'b1, {(OUT_W-1){1'b0}}};
        else
            round_sat = scaled[OUT_W-1:0];
    end
endfunction

always @(posedge clk) begin
    if (rst) begin
        write_bank <= 1'b0;
        compute_req <= 1'b0;
        compute_bank <= 1'b0;
        compute_mode <= 1'b0;
        sums_valid_r <= 1'b0;
        out_active <= 1'b0;
        out_count <= 3'd0;
        valid_out_r <= 1'b0;
        index_out_r <= 3'd0;
        coeff_out_r <= {OUT_W{1'b0}};
        sum0_r <= {ACC_W{1'b0}};
        sum1_r <= {ACC_W{1'b0}};
        sum2_r <= {ACC_W{1'b0}};
        sum3_r <= {ACC_W{1'b0}};
        sum4_r <= {ACC_W{1'b0}};
        sum5_r <= {ACC_W{1'b0}};
        sum6_r <= {ACC_W{1'b0}};
        sum7_r <= {ACC_W{1'b0}};
        for (i = 0; i < 8; i = i + 1) begin
            bank0[i] <= {DATA_W{1'b0}};
            bank1[i] <= {DATA_W{1'b0}};
            out_buf[i] <= {OUT_W{1'b0}};
        end
    end else begin
        valid_out_r <= 1'b0;
        sums_valid_r <= compute_req;

        if (valid_in) begin
            if (write_bank)
                bank1[index] <= sample_in;
            else
                bank0[index] <= sample_in;

            if (index == 3'd7) begin
                compute_req <= 1'b1;
                compute_bank <= write_bank;
                compute_mode <= mode;
                write_bank <= ~write_bank;
            end else begin
                compute_req <= 1'b0;
            end
        end else begin
            compute_req <= 1'b0;
        end

        if (compute_req) begin
            sum0_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd0, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd0, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd0, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd0, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd0, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd0, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd0, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd0, 3'd7);
            sum1_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd1, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd1, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd1, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd1, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd1, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd1, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd1, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd1, 3'd7);
            sum2_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd2, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd2, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd2, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd2, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd2, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd2, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd2, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd2, 3'd7);
            sum3_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd3, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd3, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd3, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd3, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd3, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd3, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd3, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd3, 3'd7);
            sum4_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd4, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd4, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd4, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd4, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd4, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd4, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd4, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd4, 3'd7);
            sum5_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd5, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd5, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd5, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd5, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd5, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd5, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd5, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd5, 3'd7);
            sum6_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd6, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd6, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd6, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd6, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd6, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd6, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd6, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd6, 3'd7);
            sum7_r <= bank_sample(compute_bank, 3'd0) * xform_coeff(compute_mode, 3'd7, 3'd0)
                    + bank_sample(compute_bank, 3'd1) * xform_coeff(compute_mode, 3'd7, 3'd1)
                    + bank_sample(compute_bank, 3'd2) * xform_coeff(compute_mode, 3'd7, 3'd2)
                    + bank_sample(compute_bank, 3'd3) * xform_coeff(compute_mode, 3'd7, 3'd3)
                    + bank_sample(compute_bank, 3'd4) * xform_coeff(compute_mode, 3'd7, 3'd4)
                    + bank_sample(compute_bank, 3'd5) * xform_coeff(compute_mode, 3'd7, 3'd5)
                    + bank_sample(compute_bank, 3'd6) * xform_coeff(compute_mode, 3'd7, 3'd6)
                    + bank_sample(compute_bank, 3'd7) * xform_coeff(compute_mode, 3'd7, 3'd7);
        end

        if (sums_valid_r) begin
            out_buf[0] <= round_sat(sum0_r);
            out_buf[1] <= round_sat(sum1_r);
            out_buf[2] <= round_sat(sum2_r);
            out_buf[3] <= round_sat(sum3_r);
            out_buf[4] <= round_sat(sum4_r);
            out_buf[5] <= round_sat(sum5_r);
            out_buf[6] <= round_sat(sum6_r);
            out_buf[7] <= round_sat(sum7_r);
            out_active <= 1'b1;
            out_count <= 3'd0;
        end else if (out_active) begin
            coeff_out_r <= out_buf[out_count];
            index_out_r <= out_count;
            valid_out_r <= 1'b1;
            if (out_count == 3'd7) begin
                out_active <= 1'b0;
                out_count <= 3'd0;
            end else begin
                out_count <= out_count + 3'd1;
            end
        end
    end
end

assign coeff_out = coeff_out_r;
assign valid_out = valid_out_r;
assign index_out = index_out_r;

endmodule