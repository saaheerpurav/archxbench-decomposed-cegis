module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output                      valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] tap1;
    reg [DATA_W-1:0] tap2;
    reg [DATA_W-1:0] tap3;
    reg [DATA_W-1:0] tap4;

    wire [MAC_W-1:0] mac;

    assign mac =
        ({ {(MAC_W-DATA_W){1'b0}}, data_in } * 2)  +
        ({ {(MAC_W-DATA_W){1'b0}}, tap1    } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, tap2    } * 12) +
        ({ {(MAC_W-DATA_W){1'b0}}, tap3    } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, tap4    } * 2);

    assign valid_out = valid_in;
    assign data_out  = mac >> GAIN_W;

    always @(posedge clk) begin
        if (rst) begin
            tap1 <= {DATA_W{1'b0}};
            tap2 <= {DATA_W{1'b0}};
            tap3 <= {DATA_W{1'b0}};
            tap4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            tap4 <= tap3;
            tap3 <= tap2;
            tap2 <= tap1;
            tap1 <= data_in;
        end
    end

endmodule