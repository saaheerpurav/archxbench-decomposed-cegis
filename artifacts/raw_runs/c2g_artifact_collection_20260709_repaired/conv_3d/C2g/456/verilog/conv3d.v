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

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam N = D * H * W;
    localparam OUT_D = D - K1 + 1;
    localparam OUT_H = H - K2 + 1;
    localparam OUT_W = W - K3 + 1;
    localparam OUT_N = OUT_D * OUT_H * OUT_W;
    localparam ADDR_W = clog2(N + 1);
    localparam OUT_ADDR_W = clog2(OUT_N + 1);
    localparam ACC_W = (2 * DATA_W) + clog2(K1 * K2 * K3 + 1);

    reg [DATA_W-1:0] volume [0:N-1];

    reg [ADDR_W-1:0] in_count;
    reg [OUT_ADDR_W-1:0] out_count;
    reg emitting;

    integer dz, dy, dx;
    integer oz, oy, ox;
    integer input_index;
    integer kernel_index;

    reg [ACC_W-1:0] acc_comb;
    reg [DATA_W-1:0] coeff_comb;

    always @* begin
        acc_comb = {ACC_W{1'b0}};

        oz = out_count / (OUT_H * OUT_W);
        oy = (out_count / OUT_W) % OUT_H;
        ox = out_count % OUT_W;

        for (dz = 0; dz < K1; dz = dz + 1) begin
            for (dy = 0; dy < K2; dy = dy + 1) begin
                for (dx = 0; dx < K3; dx = dx + 1) begin
                    input_index = ((oz + dz) * H * W) + ((oy + dy) * W) + (ox + dx);
                    kernel_index = ((dz * K2 * K3) + (dy * K3) + dx) * DATA_W;
                    coeff_comb = kernel[kernel_index +: DATA_W];
                    acc_comb = acc_comb + (volume[input_index] * coeff_comb);
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= {ADDR_W{1'b0}};
            out_count <= {OUT_ADDR_W{1'b0}};
            emitting <= 1'b0;
            voxel_out <= {(DATA_W+LOG_KW){1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (valid_in && !emitting) begin
                volume[in_count] <= voxel_in;
                in_count <= in_count + 1'b1;

                if (last_in) begin
                    emitting <= 1'b1;
                    out_count <= {OUT_ADDR_W{1'b0}};
                end
            end else if (emitting) begin
                if (out_count < OUT_N) begin
                    voxel_out <= acc_comb[DATA_W+LOG_KW-1:0];
                    valid_out <= 1'b1;

                    if (out_count == OUT_N - 1) begin
                        emitting <= 1'b0;
                        done <= 1'b1;
                    end

                    out_count <= out_count + 1'b1;
                end
            end
        end
    end

endmodule