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
    localparam STAGES = clog2_const(POINTS);

    function integer clog2_const;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2_const = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2_const = clog2_const + 1;
            end
        end
    endfunction

    wire signed [OUT_W-1:0] in_real_ext;
    wire signed [OUT_W-1:0] in_imag_ext;

    fft64_sign_extend #(
        .IN_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_input_extend (
        .real_in(real_in),
        .imag_in(imag_in),
        .real_out(in_real_ext),
        .imag_out(in_imag_ext)
    );

    reg signed [OUT_W-1:0] pipe_real [0:STAGES-1];
    reg signed [OUT_W-1:0] pipe_imag [0:STAGES-1];
    reg [STAGES-1:0] valid_pipe;
    reg [STAGES-1:0] last_pipe;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= {STAGES{1'b0}};
            last_pipe  <= {STAGES{1'b0}};
            for (i = 0; i < STAGES; i = i + 1) begin
                pipe_real[i] <= {OUT_W{1'b0}};
                pipe_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            pipe_real[0] <= in_real_ext;
            pipe_imag[0] <= in_imag_ext;
            valid_pipe[0] <= valid_in;
            last_pipe[0] <= valid_in & last_in;

            for (i = 1; i < STAGES; i = i + 1) begin
                pipe_real[i] <= pipe_real[i-1];
                pipe_imag[i] <= pipe_imag[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
                last_pipe[i] <= last_pipe[i-1];
            end
        end
    end

    wire signed [OUT_W-1:0] ordered_real;
    wire signed [OUT_W-1:0] ordered_imag;

    fft64_output_order #(
        .DATA_W(OUT_W),
        .POINTS(POINTS)
    ) u_output_order (
        .real_in(pipe_real[STAGES-1]),
        .imag_in(pipe_imag[STAGES-1]),
        .valid_in(valid_pipe[STAGES-1]),
        .last_in(last_pipe[STAGES-1]),
        .real_out(ordered_real),
        .imag_out(ordered_imag),
        .valid_out(valid_out),
        .last_out(last_out)
    );

    fft64_done_flag u_done_flag (
        .valid_in(valid_out),
        .last_in(last_out),
        .done(done)
    );

    assign real_out = ordered_real;
    assign imag_out = ordered_imag;

endmodule