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

    localparam ACC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] x_d1;
    reg [DATA_W-1:0] x_d2;
    reg [DATA_W-1:0] x_d3;
    reg [DATA_W-1:0] x_d4;

    wire [ACC_W-1:0] mac;

    assign valid_out = valid_in;

    assign mac =
        (data_in << 1) +
        (x_d1    << 3) +
        ((x_d2   << 3) + (x_d2 << 2)) +
        (x_d3    << 3) +
        (x_d4    << 1);

    assign data_out = mac >> GAIN_W;

    always @(posedge clk) begin
        if (rst) begin
            x_d1 <= {DATA_W{1'b0}};
            x_d2 <= {DATA_W{1'b0}};
            x_d3 <= {DATA_W{1'b0}};
            x_d4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            x_d4 <= x_d3;
            x_d3 <= x_d2;
            x_d2 <= x_d1;
            x_d1 <= data_in;
        end
    end

endmodule