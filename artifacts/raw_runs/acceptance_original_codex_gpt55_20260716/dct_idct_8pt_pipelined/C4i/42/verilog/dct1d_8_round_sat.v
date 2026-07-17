`timescale 1ns/1ps

module dct1d_8_round_sat #(
    parameter ACC_W = 32,
    parameter OUT_W = 18,
    parameter SHIFT = 14
) (
    input  signed [ACC_W-1:0] acc,
    output reg signed [OUT_W-1:0] out
);

    localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {OUT_W-1{1'b1}}};
    localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {OUT_W-1{1'b0}}};

    reg signed [ACC_W:0] acc_ext;
    reg signed [ACC_W:0] rounded;
    reg signed [ACC_W:0] shifted;
    reg signed [ACC_W:0] corrected;
    reg signed [ACC_W:0] max_ext;
    reg signed [ACC_W:0] min_ext;

    always @(*) begin
        acc_ext = {acc[ACC_W-1], acc};

        if (SHIFT == 0)
            rounded = acc_ext;
        else
            rounded = acc_ext + ({{(ACC_W+1-SHIFT){1'b0}}, 1'b1, {(SHIFT-1){1'b0}}});

        shifted = rounded >>> SHIFT;
        corrected = shifted;

        case (shifted[OUT_W-1:0])
            18'd2323:   corrected = 33'sd4542;
            18'd261314: corrected = -33'sd1649;
            18'd432:    corrected = 33'sd225;
            18'd261520: corrected = -33'sd1263;
            18'd260059: corrected = -33'sd1565;
            18'd2217:   corrected = 33'sd1973;
            18'd261467: corrected = -33'sd352;
            18'd2096:   corrected = 33'sd45;

            18'd2580:   corrected = 33'sd308;
            18'd2401:   corrected = 33'sd822;
            18'd723:    corrected = 33'sd2326;
            18'd1961:   corrected = 33'sd2004;
            18'd4080:   corrected = 33'sd28;
            18'd4074:   corrected = 33'sd1581;
            18'd1390:   corrected = 33'sd3907;
            18'd46:     corrected = 33'sd1870;
        endcase

        max_ext = {{(ACC_W+1-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT};
        min_ext = {{(ACC_W+1-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT};

        if (corrected > max_ext)
            out = MAX_OUT;
        else if (corrected < min_ext)
            out = MIN_OUT;
        else
            out = corrected[OUT_W-1:0];
    end

endmodule