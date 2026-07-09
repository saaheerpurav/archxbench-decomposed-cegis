// Applies an optional arithmetic right shift (division by 2^SHIFT) for
// final output normalization (used in IFFT mode to divide by N).
module scale_shift #(
    parameter W = 16,
    parameter SHIFT = 4
) (
    input  signed [W-1:0] in_real,
    input  signed [W-1:0] in_imag,
    input                 do_scale,
    output signed [W-1:0] out_real,
    output signed [W-1:0] out_imag
);

    // Arithmetic right shift preserves sign extension, giving correct
    // truncating division by 2^SHIFT for two's complement signed values.
    assign out_real = do_scale ? (in_real >>> SHIFT) : in_real;
    assign out_imag = do_scale ? (in_imag >>> SHIFT) : in_imag;

endmodule