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
    localparam OUT_W = DATA_W + GAIN_W;

    reg [DATA_W-1:0] x1;
    reg [DATA_W-1:0] x2;
    reg [DATA_W-1:0] x3;
    reg [DATA_W-1:0] x4;

    wire [MAC_W-1:0] mac;
    wire [MAC_W-1:0] shifted_mac;

    assign valid_out = valid_in;

    assign mac =
        ({ {(MAC_W-DATA_W){1'b0}}, data_in } * 2)  +
        ({ {(MAC_W-DATA_W){1'b0}}, x1      } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, x2      } * 12) +
        ({ {(MAC_W-DATA_W){1'b0}}, x3      } * 8)  +
        ({ {(MAC_W-DATA_W){1'b0}}, x4      } * 2);

    assign shifted_mac = mac >> GAIN_W;
    assign data_out = valid_in ? {{(OUT_W-(MAC_W-GAIN_W)){1'b0}}, shifted_mac[MAC_W-GAIN_W-1:0]} :
                                 {OUT_W{1'b0}};

    always @(posedge clk) begin
        if (rst) begin
            x1 <= {DATA_W{1'b0}};
            x2 <= {DATA_W{1'b0}};
            x3 <= {DATA_W{1'b0}};
            x4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            x4 <= x3;
            x3 <= x2;
            x2 <= x1;
            x1 <= data_in;
        end
    end

endmodule