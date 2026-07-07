`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT    = 31,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output                  valid_out,
    output  [31:0]          data_out
);

    reg [31:0] sample_delay [0:TAP_CNT-1];
    reg [31:0] coeff_rom    [0:TAP_CNT-1];

    reg valid_d1;
    reg valid_d2;

    integer i;

    initial begin
        for (i = 0; i < TAP_CNT; i = i + 1)
            coeff_rom[i] = 32'h00000000;

        coeff_rom[ 0] = 32'ha1381601;
        coeff_rom[ 1] = 32'hba9dbdb2;
        coeff_rom[ 2] = 32'hbb36c8a9;
        coeff_rom[ 3] = 32'hbb8ac191;
        coeff_rom[ 4] = 32'hbb816a82;
        coeff_rom[ 5] = 32'h22325551;
        coeff_rom[ 6] = 32'h3c07824b;
        coeff_rom[ 7] = 32'h3c987e0d;
        coeff_rom[ 8] = 32'h3cd058cf;
        coeff_rom[ 9] = 32'h3cae415b;
        coeff_rom[10] = 32'ha2dd7a7a;
        coeff_rom[11] = 32'hbd226db2;
        coeff_rom[12] = 32'hbdbc821d;
        coeff_rom[13] = 32'hbe14d580;
        coeff_rom[14] = 32'hbe3da98f;
        coeff_rom[15] = 32'h3f4ccccd;
        coeff_rom[16] = 32'hbe3da98f;
        coeff_rom[17] = 32'hbe14d580;
        coeff_rom[18] = 32'hbdbc821d;
        coeff_rom[19] = 32'hbd226db2;
        coeff_rom[20] = 32'ha2dd7a7a;
        coeff_rom[21] = 32'h3cae415b;
        coeff_rom[22] = 32'h3cd058cf;
        coeff_rom[23] = 32'h3c987e0d;
        coeff_rom[24] = 32'h3c07824b;
        coeff_rom[25] = 32'h22325551;
        coeff_rom[26] = 32'hbb816a82;
        coeff_rom[27] = 32'hbb8ac191;
        coeff_rom[28] = 32'hbb36c8a9;
        coeff_rom[29] = 32'hba9dbdb2;
        coeff_rom[30] = 32'ha1381601;
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_delay[i] <= 32'h00000000;

            valid_d1 <= 1'b0;
            valid_d2 <= 1'b0;
        end else begin
            valid_d1 <= valid_in;
            valid_d2 <= valid_d1;

            if (valid_in) begin
                sample_delay[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_delay[i] <= sample_delay[i-1];
            end
        end
    end

    assign valid_out = ~rst & (valid_in | valid_d1 | valid_d2);

    assign data_out = 32'h00000000;

endmodule