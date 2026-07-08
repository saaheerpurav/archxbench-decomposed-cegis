`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 5
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output reg [DATA_W+LOG_KW-1:0] voxel_out,
    output reg valid_out,
    output reg done
);

    localparam N = D * H * W;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ACC_W = (2 * DATA_W) + LOG_KW + 4;

    reg [DATA_W-1:0] volume [0:N-1];

    integer in_count;
    integer x_pos;
    integer y_pos;
    integer z_pos;

    integer kd;
    integer kh;
    integer kw;
    integer vx;
    integer vy;
    integer vz;
    integer vaddr;
    integer kaddr;

    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] sample;
    reg [DATA_W-1:0] coeff;

    always @(posedge clk) begin
        if (rst) begin
            in_count  <= 0;
            x_pos     <= 0;
            y_pos     <= 0;
            z_pos     <= 0;
            voxel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done      <= 1'b0;

            if (valid_in) begin
                volume[in_count] <= voxel_in;

                if ((z_pos >= K1-1) && (y_pos >= K2-1) && (x_pos >= K3-1)) begin
                    acc = {ACC_W{1'b0}};

                    for (kd = 0; kd < K1; kd = kd + 1) begin
                        for (kh = 0; kh < K2; kh = kh + 1) begin
                            for (kw = 0; kw < K3; kw = kw + 1) begin
                                vz = z_pos - (K1 - 1) + kd;
                                vy = y_pos - (K2 - 1) + kh;
                                vx = x_pos - (K3 - 1) + kw;

                                vaddr = ((vz * H) + vy) * W + vx;
                                kaddr = ((kd * K2 * K3) + (kh * K3) + kw) * DATA_W;

                                if (vaddr == in_count)
                                    sample = voxel_in;
                                else
                                    sample = volume[vaddr];

                                coeff = kernel[kaddr +: DATA_W];
                                acc = acc + (sample * coeff);
                            end
                        end
                    end

                    voxel_out <= acc[OUT_W-1:0];
                    valid_out <= 1'b1;
                end

                done <= last_in;

                if (x_pos == W-1) begin
                    x_pos <= 0;
                    if (y_pos == H-1) begin
                        y_pos <= 0;
                        if (z_pos == D-1)
                            z_pos <= 0;
                        else
                            z_pos <= z_pos + 1;
                    end else begin
                        y_pos <= y_pos + 1;
                    end
                end else begin
                    x_pos <= x_pos + 1;
                end

                if (last_in)
                    in_count <= 0;
                else
                    in_count <= in_count + 1;
            end
        end
    end

endmodule