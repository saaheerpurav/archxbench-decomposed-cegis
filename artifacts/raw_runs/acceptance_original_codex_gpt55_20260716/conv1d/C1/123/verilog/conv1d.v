module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] shift_reg [0:KERNEL_SIZE-2];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < KERNEL_SIZE-1; i = i + 1) begin
                shift_reg[i] <= {DATA_W{1'b0}};
            end
        end else if (valid_in) begin
            shift_reg[0] <= data_in;
            for (i = 1; i < KERNEL_SIZE-1; i = i + 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    wire [MAC_W-1:0] x0 = {{(MAC_W-DATA_W){1'b0}}, data_in};
    wire [MAC_W-1:0] x1 = {{(MAC_W-DATA_W){1'b0}}, shift_reg[0]};
    wire [MAC_W-1:0] x2 = {{(MAC_W-DATA_W){1'b0}}, shift_reg[1]};
    wire [MAC_W-1:0] x3 = {{(MAC_W-DATA_W){1'b0}}, shift_reg[2]};
    wire [MAC_W-1:0] x4 = {{(MAC_W-DATA_W){1'b0}}, shift_reg[3]};

    wire [MAC_W-1:0] mac =
        (x0 << 1) +
        (x1 << 3) +
        (x2 << 3) + (x2 << 2) +
        (x3 << 3) +
        (x4 << 1);

    assign valid_out = valid_in;
    assign data_out  = mac >> GAIN_W;

endmodule