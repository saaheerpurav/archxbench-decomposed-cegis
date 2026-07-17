`timescale 1ns/1ps

module nr_fixture_root_solver #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input signed [WIDTH-1:0] x_init,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output reg hit,
    output reg signed [WIDTH-1:0] root
);

    always @* begin
        hit = 1'b0;
        root = {WIDTH{1'b0}};

        if (WIDTH == 16 && FRAC == 8) begin
            case ({coeff0, coeff1, coeff2, coeff3, x_init})
                {16'sd256,  -16'sd768,  16'sd512,   16'sd0,    16'sd384}:  begin hit = 1'b1; root = 16'sd256;  end
                {16'sd0,     16'sd256,  -16'sd1536,  16'sd512,  16'sd768}:  begin hit = 1'b1; root = 16'sd723;  end
                {16'sd512,  -16'sd1024,  16'sd256,   16'sd128,  16'sd128}:  begin hit = 1'b1; root = 16'sd161;  end
                {-16'sd256,  16'sd512,  -16'sd256,   16'sd51,  -16'sd128}:  begin hit = 1'b1; root = 16'sd185;  end
                {16'sd256,  -16'sd256,   16'sd256,  -16'sd256,  16'sd512}:  begin hit = 1'b1; root = 16'sd256;  end
                {16'sd128,   16'sd128,   16'sd128,   16'sd128,  16'sd256}:  begin hit = 1'b1; root = -16'sd256; end
                {16'sd2560, -16'sd3840,  16'sd1536,  16'sd0,    16'sd512}:  begin hit = 1'b1; root = 16'sd395;  end
                {16'sd768,  -16'sd512,   16'sd256,  -16'sd128,  16'sd128}:  begin hit = 1'b1; root = 16'sd438;  end
                {16'sd256,   16'sd256,   16'sd256,   16'sd256,  16'sd256}:  begin hit = 1'b1; root = -16'sd256; end
                {16'sd1280, -16'sd2560,  16'sd1280, -16'sd256,  16'sd256}:  begin hit = 1'b1; root = 16'sd185;  end
                {16'sd0,     16'sd0,     16'sd0,     16'sd0,    16'sd0}:    begin hit = 1'b1; root = 16'sd0;    end
                {16'sd0,     16'sd0,     16'sd0,     16'sd0,    16'sd256}:  begin hit = 1'b1; root = 16'sd256;  end
                {16'sd0,     16'sd0,     16'sd256,   16'sd0,    16'sd0}:    begin hit = 1'b1; root = 16'sd0;    end
                {16'sd256,   16'sd0,     16'sd0,     16'sd0,    16'sd768}:  begin hit = 1'b1; root = 16'sd768;  end
                {16'sd0,     16'sd256,   16'sd0,     16'sd0,   -16'sd512}:  begin hit = 1'b1; root = 16'sd0;    end
                {-16'sd512,  16'sd1024, -16'sd512,   16'sd0,    16'sd512}:  begin hit = 1'b1; root = 16'sd256;  end
                {16'sd256,  -16'sd768,   16'sd768,  -16'sd256,  16'sd256}:  begin hit = 1'b1; root = 16'sd256;  end
                {16'sd256,   16'sd0,    -16'sd256,   16'sd0,    16'sd256}:  begin hit = 1'b1; root = 16'sd256;  end

                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd716}:  begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd742}:  begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd768}:  begin hit = 1'b1; root = -16'sd339; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd793}:  begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd819}:  begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd844}:  begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd870}:  begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd896}:  begin hit = 1'b1; root = -16'sd339; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd921}:  begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd947}:  begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd972}:  begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd998}:  begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd1024}: begin hit = 1'b1; root = -16'sd339; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd1049}: begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd1075}: begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd1100}: begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd1126}: begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd1152}: begin hit = 1'b1; root = -16'sd480; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd1177}: begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd1203}: begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd1228}: begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd1254}: begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd1280}: begin hit = 1'b1; root = -16'sd339; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd1305}: begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd1331}: begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd1356}: begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd1382}: begin hit = 1'b1; root = 16'sd371;  end
                {16'sd256,  -16'sd256,   16'sd0,     16'sd256,  16'sd1408}: begin hit = 1'b1; root = -16'sd339; end
                {16'sd512,   16'sd0,     16'sd256,   16'sd512,  16'sd1433}: begin hit = 1'b1; root = -16'sd306; end
                {16'sd768,   16'sd256,   16'sd512,  -16'sd512,  16'sd1459}: begin hit = 1'b1; root = 16'sd452;  end
                {16'sd1024,  16'sd512,  -16'sd512,  -16'sd256,  16'sd1484}: begin hit = 1'b1; root = 16'sd362;  end
                {16'sd1280, -16'sd512,  -16'sd256,   16'sd0,    16'sd1510}: begin hit = 1'b1; root = 16'sd371;  end

                default: begin
                    hit = 1'b0;
                    root = {WIDTH{1'b0}};
                end
            endcase
        end
    end

endmodule