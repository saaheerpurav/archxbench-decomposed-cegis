module twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] k,   // 0..15
    output reg signed [COEFF_W-1:0] cos_out,
    output reg signed [COEFF_W-1:0] sin_out
);

    // Base table for k=0..8 (Q1.15)
    function signed [COEFF_W-1:0] cos_base;
        input [3:0] idx;
        begin
            case (idx)
                4'd0: cos_base = 16'sd32767;
                4'd1: cos_base = 16'sd30274;
                4'd2: cos_base = 16'sd23170;
                4'd3: cos_base = 16'sd12540;
                4'd4: cos_base = 16'sd0;
                4'd5: cos_base = -16'sd12540;
                4'd6: cos_base = -16'sd23170;
                4'd7: cos_base = -16'sd30274;
                4'd8: cos_base = -16'sd32768;
                default: cos_base = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] sin_base;
        input [3:0] idx;
        begin
            case (idx)
                4'd0: sin_base = 16'sd0;
                4'd1: sin_base = 16'sd12540;
                4'd2: sin_base = 16'sd23170;
                4'd3: sin_base = 16'sd30274;
                4'd4: sin_base = 16'sd32767;
                4'd5: sin_base = 16'sd30274;
                4'd6: sin_base = 16'sd23170;
                4'd7: sin_base = 16'sd12540;
                4'd8: sin_base = 16'sd0;
                default: sin_base = 16'sd0;
            endcase
        end
    endfunction

    always @(*) begin
        if (k <= 4'd8) begin
            cos_out = cos_base(k);
            sin_out = sin_base(k);
        end else begin
            cos_out = cos_base(4'd16 - k);
            sin_out = -sin_base(4'd16 - k);
        end
    end

endmodule