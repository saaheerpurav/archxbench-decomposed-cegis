`timescale 1ns/1ps

module fft64_twiddle_rom #(
    parameter DATA_W = 20,
    parameter POINTS = 64
) (
    input [5:0] index,
    output reg signed [DATA_W-1:0] tw_real,
    output reg signed [DATA_W-1:0] tw_imag
);
    localparam signed [DATA_W-1:0] SCALE = 16'sd32767;

    always @* begin
        case (index[5:0])
            6'd0:  begin tw_real =  32767; tw_imag =      0; end
            6'd1:  begin tw_real =  32610; tw_imag =  -3212; end
            6'd2:  begin tw_real =  32138; tw_imag =  -6393; end
            6'd3:  begin tw_real =  31357; tw_imag =  -9512; end
            6'd4:  begin tw_real =  30274; tw_imag = -12539; end
            6'd5:  begin tw_real =  28899; tw_imag = -15446; end
            6'd6:  begin tw_real =  27246; tw_imag = -18205; end
            6'd7:  begin tw_real =  25330; tw_imag = -20788; end
            6'd8:  begin tw_real =  23170; tw_imag = -23170; end
            6'd9:  begin tw_real =  20788; tw_imag = -25330; end
            6'd10: begin tw_real =  18205; tw_imag = -27246; end
            6'd11: begin tw_real =  15446; tw_imag = -28899; end
            6'd12: begin tw_real =  12539; tw_imag = -30274; end
            6'd13: begin tw_real =   9512; tw_imag = -31357; end
            6'd14: begin tw_real =   6393; tw_imag = -32138; end
            6'd15: begin tw_real =   3212; tw_imag = -32610; end
            6'd16: begin tw_real =      0; tw_imag = -32767; end
            6'd17: begin tw_real =  -3212; tw_imag = -32610; end
            6'd18: begin tw_real =  -6393; tw_imag = -32138; end
            6'd19: begin tw_real =  -9512; tw_imag = -31357; end
            6'd20: begin tw_real = -12539; tw_imag = -30274; end
            6'd21: begin tw_real = -15446; tw_imag = -28899; end
            6'd22: begin tw_real = -18205; tw_imag = -27246; end
            6'd23: begin tw_real = -20788; tw_imag = -25330; end
            6'd24: begin tw_real = -23170; tw_imag = -23170; end
            6'd25: begin tw_real = -25330; tw_imag = -20788; end
            6'd26: begin tw_real = -27246; tw_imag = -18205; end
            6'd27: begin tw_real = -28899; tw_imag = -15446; end
            6'd28: begin tw_real = -30274; tw_imag = -12539; end
            6'd29: begin tw_real = -31357; tw_imag =  -9512; end
            6'd30: begin tw_real = -32138; tw_imag =  -6393; end
            6'd31: begin tw_real = -32610; tw_imag =  -3212; end
            6'd32: begin tw_real = -32767; tw_imag =      0; end
            6'd33: begin tw_real = -32610; tw_imag =   3212; end
            6'd34: begin tw_real = -32138; tw_imag =   6393; end
            6'd35: begin tw_real = -31357; tw_imag =   9512; end
            6'd36: begin tw_real = -30274; tw_imag =  12539; end
            6'd37: begin tw_real = -28899; tw_imag =  15446; end
            6'd38: begin tw_real = -27246; tw_imag =  18205; end
            6'd39: begin tw_real = -25330; tw_imag =  20788; end
            6'd40: begin tw_real = -23170; tw_imag =  23170; end
            6'd41: begin tw_real = -20788; tw_imag =  25330; end
            6'd42: begin tw_real = -18205; tw_imag =  27246; end
            6'd43: begin tw_real = -15446; tw_imag =  28899; end
            6'd44: begin tw_real = -12539; tw_imag =  30274; end
            6'd45: begin tw_real =  -9512; tw_imag =  31357; end
            6'd46: begin tw_real =  -6393; tw_imag =  32138; end
            6'd47: begin tw_real =  -3212; tw_imag =  32610; end
            6'd48: begin tw_real =      0; tw_imag =  32767; end
            6'd49: begin tw_real =   3212; tw_imag =  32610; end
            6'd50: begin tw_real =   6393; tw_imag =  32138; end
            6'd51: begin tw_real =   9512; tw_imag =  31357; end
            6'd52: begin tw_real =  12539; tw_imag =  30274; end
            6'd53: begin tw_real =  15446; tw_imag =  28899; end
            6'd54: begin tw_real =  18205; tw_imag =  27246; end
            6'd55: begin tw_real =  20788; tw_imag =  25330; end
            6'd56: begin tw_real =  23170; tw_imag =  23170; end
            6'd57: begin tw_real =  25330; tw_imag =  20788; end
            6'd58: begin tw_real =  27246; tw_imag =  18205; end
            6'd59: begin tw_real =  28899; tw_imag =  15446; end
            6'd60: begin tw_real =  30274; tw_imag =  12539; end
            6'd61: begin tw_real =  31357; tw_imag =   9512; end
            6'd62: begin tw_real =  32138; tw_imag =   6393; end
            default: begin tw_real = 32610; tw_imag =   3212; end
        endcase
    end
endmodule