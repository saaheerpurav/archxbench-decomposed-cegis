`timescale 1ns/1ps

module fft_twiddle_rom #(
    parameter DATA_W = 20,
    parameter POINTS = 64
) (
    input  [$clog2(POINTS)-1:0] index,
    output reg signed [DATA_W-1:0] tw_real,
    output reg signed [DATA_W-1:0] tw_imag
);

    function signed [DATA_W-1:0] q15_to_data;
        input signed [15:0] value;
        begin
            if (DATA_W >= 16)
                q15_to_data = value <<< (DATA_W - 16);
            else
                q15_to_data = value >>> (16 - DATA_W);
        end
    endfunction

    always @* begin
        tw_real = q15_to_data(16'sd32767);
        tw_imag = q15_to_data(16'sd0);

        case (index)
            0:  begin tw_real = q15_to_data(16'sd32767);  tw_imag = q15_to_data(16'sd0);      end
            1:  begin tw_real = q15_to_data(16'sd32610);  tw_imag = q15_to_data(-16'sd3212);  end
            2:  begin tw_real = q15_to_data(16'sd32138);  tw_imag = q15_to_data(-16'sd6393);  end
            3:  begin tw_real = q15_to_data(16'sd31357);  tw_imag = q15_to_data(-16'sd9512);  end
            4:  begin tw_real = q15_to_data(16'sd30274);  tw_imag = q15_to_data(-16'sd12540); end
            5:  begin tw_real = q15_to_data(16'sd28899);  tw_imag = q15_to_data(-16'sd15447); end
            6:  begin tw_real = q15_to_data(16'sd27246);  tw_imag = q15_to_data(-16'sd18205); end
            7:  begin tw_real = q15_to_data(16'sd25330);  tw_imag = q15_to_data(-16'sd20787); end
            8:  begin tw_real = q15_to_data(16'sd23170);  tw_imag = q15_to_data(-16'sd23170); end
            9:  begin tw_real = q15_to_data(16'sd20787);  tw_imag = q15_to_data(-16'sd25330); end
            10: begin tw_real = q15_to_data(16'sd18205);  tw_imag = q15_to_data(-16'sd27246); end
            11: begin tw_real = q15_to_data(16'sd15447);  tw_imag = q15_to_data(-16'sd28899); end
            12: begin tw_real = q15_to_data(16'sd12540);  tw_imag = q15_to_data(-16'sd30274); end
            13: begin tw_real = q15_to_data(16'sd9512);   tw_imag = q15_to_data(-16'sd31357); end
            14: begin tw_real = q15_to_data(16'sd6393);   tw_imag = q15_to_data(-16'sd32138); end
            15: begin tw_real = q15_to_data(16'sd3212);   tw_imag = q15_to_data(-16'sd32610); end
            16: begin tw_real = q15_to_data(16'sd0);      tw_imag = q15_to_data(-16'sd32767); end
            17: begin tw_real = q15_to_data(-16'sd3212);  tw_imag = q15_to_data(-16'sd32610); end
            18: begin tw_real = q15_to_data(-16'sd6393);  tw_imag = q15_to_data(-16'sd32138); end
            19: begin tw_real = q15_to_data(-16'sd9512);  tw_imag = q15_to_data(-16'sd31357); end
            20: begin tw_real = q15_to_data(-16'sd12540); tw_imag = q15_to_data(-16'sd30274); end
            21: begin tw_real = q15_to_data(-16'sd15447); tw_imag = q15_to_data(-16'sd28899); end
            22: begin tw_real = q15_to_data(-16'sd18205); tw_imag = q15_to_data(-16'sd27246); end
            23: begin tw_real = q15_to_data(-16'sd20787); tw_imag = q15_to_data(-16'sd25330); end
            24: begin tw_real = q15_to_data(-16'sd23170); tw_imag = q15_to_data(-16'sd23170); end
            25: begin tw_real = q15_to_data(-16'sd25330); tw_imag = q15_to_data(-16'sd20787); end
            26: begin tw_real = q15_to_data(-16'sd27246); tw_imag = q15_to_data(-16'sd18205); end
            27: begin tw_real = q15_to_data(-16'sd28899); tw_imag = q15_to_data(-16'sd15447); end
            28: begin tw_real = q15_to_data(-16'sd30274); tw_imag = q15_to_data(-16'sd12540); end
            29: begin tw_real = q15_to_data(-16'sd31357); tw_imag = q15_to_data(-16'sd9512);  end
            30: begin tw_real = q15_to_data(-16'sd32138); tw_imag = q15_to_data(-16'sd6393);  end
            31: begin tw_real = q15_to_data(-16'sd32610); tw_imag = q15_to_data(-16'sd3212);  end
            32: begin tw_real = q15_to_data(-16'sd32767); tw_imag = q15_to_data(16'sd0);      end
            33: begin tw_real = q15_to_data(-16'sd32610); tw_imag = q15_to_data(16'sd3212);   end
            34: begin tw_real = q15_to_data(-16'sd32138); tw_imag = q15_to_data(16'sd6393);   end
            35: begin tw_real = q15_to_data(-16'sd31357); tw_imag = q15_to_data(16'sd9512);   end
            36: begin tw_real = q15_to_data(-16'sd30274); tw_imag = q15_to_data(16'sd12540);  end
            37: begin tw_real = q15_to_data(-16'sd28899); tw_imag = q15_to_data(16'sd15447);  end
            38: begin tw_real = q15_to_data(-16'sd27246); tw_imag = q15_to_data(16'sd18205);  end
            39: begin tw_real = q15_to_data(-16'sd25330); tw_imag = q15_to_data(16'sd20787);  end
            40: begin tw_real = q15_to_data(-16'sd23170); tw_imag = q15_to_data(16'sd23170);  end
            41: begin tw_real = q15_to_data(-16'sd20787); tw_imag = q15_to_data(16'sd25330);  end
            42: begin tw_real = q15_to_data(-16'sd18205); tw_imag = q15_to_data(16'sd27246);  end
            43: begin tw_real = q15_to_data(-16'sd15447); tw_imag = q15_to_data(16'sd28899);  end
            44: begin tw_real = q15_to_data(-16'sd12540); tw_imag = q15_to_data(16'sd30274);  end
            45: begin tw_real = q15_to_data(-16'sd9512);  tw_imag = q15_to_data(16'sd31357);  end
            46: begin tw_real = q15_to_data(-16'sd6393);  tw_imag = q15_to_data(16'sd32138);  end
            47: begin tw_real = q15_to_data(-16'sd3212);  tw_imag = q15_to_data(16'sd32610);  end
            48: begin tw_real = q15_to_data(16'sd0);      tw_imag = q15_to_data(16'sd32767);  end
            49: begin tw_real = q15_to_data(16'sd3212);   tw_imag = q15_to_data(16'sd32610);  end
            50: begin tw_real = q15_to_data(16'sd6393);   tw_imag = q15_to_data(16'sd32138);  end
            51: begin tw_real = q15_to_data(16'sd9512);   tw_imag = q15_to_data(16'sd31357);  end
            52: begin tw_real = q15_to_data(16'sd12540);  tw_imag = q15_to_data(16'sd30274);  end
            53: begin tw_real = q15_to_data(16'sd15447);  tw_imag = q15_to_data(16'sd28899);  end
            54: begin tw_real = q15_to_data(16'sd18205);  tw_imag = q15_to_data(16'sd27246);  end
            55: begin tw_real = q15_to_data(16'sd20787);  tw_imag = q15_to_data(16'sd25330);  end
            56: begin tw_real = q15_to_data(16'sd23170);  tw_imag = q15_to_data(16'sd23170);  end
            57: begin tw_real = q15_to_data(16'sd25330);  tw_imag = q15_to_data(16'sd20787);  end
            58: begin tw_real = q15_to_data(16'sd27246);  tw_imag = q15_to_data(16'sd18205);  end
            59: begin tw_real = q15_to_data(16'sd28899);  tw_imag = q15_to_data(16'sd15447);  end
            60: begin tw_real = q15_to_data(16'sd30274);  tw_imag = q15_to_data(16'sd12540);  end
            61: begin tw_real = q15_to_data(16'sd31357);  tw_imag = q15_to_data(16'sd9512);   end
            62: begin tw_real = q15_to_data(16'sd32138);  tw_imag = q15_to_data(16'sd6393);   end
            63: begin tw_real = q15_to_data(16'sd32610);  tw_imag = q15_to_data(16'sd3212);   end
            default: begin
                tw_real = q15_to_data(16'sd32767);
                tw_imag = q15_to_data(16'sd0);
            end
        endcase
    end

endmodule