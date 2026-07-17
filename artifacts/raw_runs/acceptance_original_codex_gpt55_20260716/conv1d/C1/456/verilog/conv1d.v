module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  data_out
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] shift_reg [0:KERNEL_SIZE-1];

    integer i;

    wire [MAC_W-1:0] mac;

    assign mac =
        ({ {(MAC_W-DATA_W){1'b0}}, data_in      } * 2)  +
        ({ {(MAC_W-DATA_W){1'b0}}, shift_reg[0] } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, shift_reg[1] } * 12) +
        ({ {(MAC_W-DATA_W){1'b0}}, shift_reg[2] } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, shift_reg[3] } * 2);

    assign valid_out = valid_in;
    assign data_out  = mac >> GAIN_W;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
                shift_reg[i] <= {DATA_W{1'b0}};
            end
        end else if (valid_in) begin
            shift_reg[0] <= data_in;
            for (i = 1; i < KERNEL_SIZE; i = i + 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

endmodule