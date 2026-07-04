`timescale 1ns/1ps

module fft_twiddle_rom #(
    parameter DATA_W = 20,
    parameter POINTS = 64,
    parameter STAGE = 0
) (
    input [5:0] index,
    output reg signed [DATA_W-1:0] tw_real,
    output reg signed [DATA_W-1:0] tw_imag
);

    reg [4:0] tw_exp;

    function signed [DATA_W-1:0] q14;
        input integer value;
        begin
            q14 = value;
        end
    endfunction

    always @* begin
        case (STAGE)
            0: tw_exp = 5'd0;
            1: tw_exp = {index[0],   4'b0000};
            2: tw_exp = {index[1:0], 3'b000};
            3: tw_exp = {index[2:0], 2'b00};
            4: tw_exp = {index[3:0], 1'b0};
            5: tw_exp = index[4:0];
            default: tw_exp = 5'd0;
        endcase

        case (tw_exp)
            5'd0:  begin tw_real = q14( 16384); tw_imag = q14(     0); end
            5'd1:  begin tw_real = q14( 16305); tw_imag = q14( -1606); end
            5'd2:  begin tw_real = q14( 16069); tw_imag = q14( -3196); end
            5'd3:  begin tw_real = q14( 15679); tw_imag = q14( -4756); end
            5'd4:  begin tw_real = q14( 15137); tw_imag = q14( -6270); end
            5'd5:  begin tw_real = q14( 14449); tw_imag = q14( -7723); end
            5'd6:  begin tw_real = q14( 13623); tw_imag = q14( -9102); end
            5'd7:  begin tw_real = q14( 12665); tw_imag = q14(-10394); end
            5'd8:  begin tw_real = q14( 11585); tw_imag = q14(-11585); end
            5'd9:  begin tw_real = q14( 10394); tw_imag = q14(-12665); end
            5'd10: begin tw_real = q14(  9102); tw_imag = q14(-13623); end
            5'd11: begin tw_real = q14(  7723); tw_imag = q14(-14449); end
            5'd12: begin tw_real = q14(  6270); tw_imag = q14(-15137); end
            5'd13: begin tw_real = q14(  4756); tw_imag = q14(-15679); end
            5'd14: begin tw_real = q14(  3196); tw_imag = q14(-16069); end
            5'd15: begin tw_real = q14(  1606); tw_imag = q14(-16305); end
            5'd16: begin tw_real = q14(     0); tw_imag = q14(-16384); end
            5'd17: begin tw_real = q14( -1606); tw_imag = q14(-16305); end
            5'd18: begin tw_real = q14( -3196); tw_imag = q14(-16069); end
            5'd19: begin tw_real = q14( -4756); tw_imag = q14(-15679); end
            5'd20: begin tw_real = q14( -6270); tw_imag = q14(-15137); end
            5'd21: begin tw_real = q14( -7723); tw_imag = q14(-14449); end
            5'd22: begin tw_real = q14( -9102); tw_imag = q14(-13623); end
            5'd23: begin tw_real = q14(-10394); tw_imag = q14(-12665); end
            5'd24: begin tw_real = q14(-11585); tw_imag = q14(-11585); end
            5'd25: begin tw_real = q14(-12665); tw_imag = q14(-10394); end
            5'd26: begin tw_real = q14(-13623); tw_imag = q14( -9102); end
            5'd27: begin tw_real = q14(-14449); tw_imag = q14( -7723); end
            5'd28: begin tw_real = q14(-15137); tw_imag = q14( -6270); end
            5'd29: begin tw_real = q14(-15679); tw_imag = q14( -4756); end
            5'd30: begin tw_real = q14(-16069); tw_imag = q14( -3196); end
            5'd31: begin tw_real = q14(-16305); tw_imag = q14( -1606); end
            default: begin tw_real = q14(16384); tw_imag = q14(0); end
        endcase
    end

endmodule