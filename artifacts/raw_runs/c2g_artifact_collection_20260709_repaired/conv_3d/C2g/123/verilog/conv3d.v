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
    localparam ACC_W = (2 * DATA_W) + LOG_KW + 1;

    reg [DATA_W-1:0] volume [0:N-1];

    integer in_count;
    integer cur_d;
    integer cur_h;
    integer cur_w;

    integer kd;
    integer kh;
    integer kw;
    integer vd;
    integer vh;
    integer vw;
    integer addr;
    integer kaddr;

    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] sample;
    reg [DATA_W-1:0] coeff;

    always @(posedge clk) begin
        if (rst) begin
            in_count  <= 0;
            voxel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done      <= 1'b0;

            if (valid_in) begin
                volume[in_count] <= voxel_in;

                cur_d = in_count / (H * W);
                cur_h = (in_count / W) % H;
                cur_w = in_count % W;

                if ((cur_d >= K1-1) && (cur_h >= K2-1) && (cur_w >= K3-1)) begin
                    acc = {ACC_W{1'b0}};

                    for (kd = 0; kd < K1; kd = kd + 1) begin
                        for (kh = 0; kh < K2; kh = kh + 1) begin
                            for (kw = 0; kw < K3; kw = kw + 1) begin
                                vd = cur_d - (K1 - 1) + kd;
                                vh = cur_h - (K2 - 1) + kh;
                                vw = cur_w - (K3 - 1) + kw;

                                addr = (vd * H * W) + (vh * W) + vw;
                                kaddr = ((kd * K2 * K3) + (kh * K3) + kw) * DATA_W;

                                if (addr == in_count)
                                    sample = voxel_in;
                                else
                                    sample = volume[addr];

                                coeff = kernel[kaddr +: DATA_W];
                                acc = acc + (sample * coeff);
                            end
                        end
                    end

                    voxel_out <= acc[OUT_W-1:0];
                    valid_out <= 1'b1;
                end

                done <= last_in;

                if (last_in)
                    in_count <= 0;
                else
                    in_count <= in_count + 1;
            end
        end
    end

endmodule