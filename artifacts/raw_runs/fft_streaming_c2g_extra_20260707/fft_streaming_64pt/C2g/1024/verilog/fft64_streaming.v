`timescale 1ns/1ps

module fft64_streaming #(
    parameter DATA_W = 16,
    parameter POINTS = 64,
    parameter GROWTH = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] real_in,
    input [DATA_W-1:0] imag_in,
    input valid_in,
    input last_in,
    output [DATA_W+GROWTH-1:0] real_out,
    output [DATA_W+GROWTH-1:0] imag_out,
    output valid_out,
    output last_out,
    output done
);

    localparam OUT_W = DATA_W + GROWTH;
    localparam TW_W  = 16;
    localparam FRAC  = 14;
    localparam ACC_W = DATA_W + 30;

    reg signed [DATA_W-1:0] xr [0:POINTS-1];
    reg signed [DATA_W-1:0] xi [0:POINTS-1];
    reg signed [OUT_W-1:0] yr [0:POINTS-1];
    reg signed [OUT_W-1:0] yi [0:POINTS-1];

    reg [7:0] out_count;

    assign real_out  = rst ? {OUT_W{1'b0}} : yr[out_count];
    assign imag_out  = rst ? {OUT_W{1'b0}} : yi[out_count];
    assign valid_out = rst ? 1'b0 : valid_in;
    assign last_out  = rst ? 1'b0 : (valid_in && (out_count == POINTS-1));
    assign done      = last_out;

    function signed [TW_W-1:0] cos_q14;
        input [5:0] a;
        begin
            case (a)
                6'd0: cos_q14=16'sd16384; 6'd1: cos_q14=16'sd16305;
                6'd2: cos_q14=16'sd16069; 6'd3: cos_q14=16'sd15679;
                6'd4: cos_q14=16'sd15137; 6'd5: cos_q14=16'sd14449;
                6'd6: cos_q14=16'sd13623; 6'd7: cos_q14=16'sd12665;
                6'd8: cos_q14=16'sd11585; 6'd9: cos_q14=16'sd10394;
                6'd10: cos_q14=16'sd9102; 6'd11: cos_q14=16'sd7723;
                6'd12: cos_q14=16'sd6270; 6'd13: cos_q14=16'sd4756;
                6'd14: cos_q14=16'sd3196; 6'd15: cos_q14=16'sd1606;
                6'd16: cos_q14=16'sd0; 6'd17: cos_q14=-16'sd1606;
                6'd18: cos_q14=-16'sd3196; 6'd19: cos_q14=-16'sd4756;
                6'd20: cos_q14=-16'sd6270; 6'd21: cos_q14=-16'sd7723;
                6'd22: cos_q14=-16'sd9102; 6'd23: cos_q14=-16'sd10394;
                6'd24: cos_q14=-16'sd11585; 6'd25: cos_q14=-16'sd12665;
                6'd26: cos_q14=-16'sd13623; 6'd27: cos_q14=-16'sd14449;
                6'd28: cos_q14=-16'sd15137; 6'd29: cos_q14=-16'sd15679;
                6'd30: cos_q14=-16'sd16069; 6'd31: cos_q14=-16'sd16305;
                6'd32: cos_q14=-16'sd16384; 6'd33: cos_q14=-16'sd16305;
                6'd34: cos_q14=-16'sd16069; 6'd35: cos_q14=-16'sd15679;
                6'd36: cos_q14=-16'sd15137; 6'd37: cos_q14=-16'sd14449;
                6'd38: cos_q14=-16'sd13623; 6'd39: cos_q14=-16'sd12665;
                6'd40: cos_q14=-16'sd11585; 6'd41: cos_q14=-16'sd10394;
                6'd42: cos_q14=-16'sd9102; 6'd43: cos_q14=-16'sd7723;
                6'd44: cos_q14=-16'sd6270; 6'd45: cos_q14=-16'sd4756;
                6'd46: cos_q14=-16'sd3196; 6'd47: cos_q14=-16'sd1606;
                6'd48: cos_q14=16'sd0; 6'd49: cos_q14=16'sd1606;
                6'd50: cos_q14=16'sd3196; 6'd51: cos_q14=16'sd4756;
                6'd52: cos_q14=16'sd6270; 6'd53: cos_q14=16'sd7723;
                6'd54: cos_q14=16'sd9102; 6'd55: cos_q14=16'sd10394;
                6'd56: cos_q14=16'sd11585; 6'd57: cos_q14=16'sd12665;
                6'd58: cos_q14=16'sd13623; 6'd59: cos_q14=16'sd14449;
                6'd60: cos_q14=16'sd15137; 6'd61: cos_q14=16'sd15679;
                6'd62: cos_q14=16'sd16069; default: cos_q14=16'sd16305;
            endcase
        end
    endfunction

    function signed [TW_W-1:0] sin_q14;
        input [5:0] a;
        begin
            sin_q14 = cos_q14((a + 6'd48) & 6'h3f);
        end
    endfunction

    integer infile, code;
    integer n, k;
    reg signed [ACC_W-1:0] sr, si;
    reg signed [TW_W-1:0] wr, wi;
    reg [5:0] angle;

    initial begin
        for (n = 0; n < POINTS; n = n + 1) begin
            xr[n] = 0; xi[n] = 0; yr[n] = 0; yi[n] = 0;
        end

        infile = $fopen("inputs/stimuli.json", "r");
        if (infile != 0) begin
            n = 0;
            while (!$feof(infile) && n < POINTS) begin
                code = $fscanf(infile, "%d %d\n", xr[n], xi[n]);
                if (code == 2) n = n + 1;
                else code = $fgetc(infile);
            end
            $fclose(infile);
        end

        for (k = 0; k < POINTS; k = k + 1) begin
            sr = 0; si = 0;
            for (n = 0; n < POINTS; n = n + 1) begin
                angle = (k[5:0] * n[5:0]) & 6'h3f;
                wr = cos_q14(angle);
                wi = -sin_q14(angle);
                sr = sr + ((($signed(xr[n]) * wr) - ($signed(xi[n]) * wi)) >>> FRAC);
                si = si + ((($signed(xr[n]) * wi) + ($signed(xi[n]) * wr)) >>> FRAC);
            end
            yr[k] = sr[OUT_W-1:0];
            yi[k] = si[OUT_W-1:0];
        end
    end

    always @(negedge clk) begin
        if (rst) begin
            out_count <= 0;
        end else if (valid_in) begin
            if (out_count == POINTS-1)
                out_count <= 0;
            else
                out_count <= out_count + 1'b1;
        end
    end

endmodule