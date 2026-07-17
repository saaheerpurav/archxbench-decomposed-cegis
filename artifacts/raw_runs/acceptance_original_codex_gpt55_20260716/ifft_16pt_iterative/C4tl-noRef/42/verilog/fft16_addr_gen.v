module fft16_addr_gen (
    input  wire [1:0] stage,
    input  wire [2:0] bfly_idx,
    output reg  [3:0] addr_p,
    output reg  [3:0] addr_q,
    output reg  [3:0] tw_idx
);

    reg [3:0] logical_p;
    reg [3:0] logical_q;

    function [3:0] bit_reverse4;
        input [3:0] value;
        begin
            bit_reverse4 = {value[0], value[1], value[2], value[3]};
        end
    endfunction

    always @(*) begin
        logical_p = 4'd0;
        logical_q = 4'd0;
        addr_p    = 4'd0;
        addr_q    = 4'd0;
        tw_idx    = 4'd0;

        case (stage)
            2'd0: begin
                logical_p = {bfly_idx, 1'b0};
                logical_q = {bfly_idx, 1'b1};
                tw_idx    = 4'd0;
            end

            2'd1: begin
                logical_p = {bfly_idx[2:1], 1'b0, bfly_idx[0]};
                logical_q = {bfly_idx[2:1], 1'b1, bfly_idx[0]};
                tw_idx    = {1'b0, bfly_idx[0], 2'b00};
            end

            2'd2: begin
                logical_p = {bfly_idx[2], 1'b0, bfly_idx[1:0]};
                logical_q = {bfly_idx[2], 1'b1, bfly_idx[1:0]};
                tw_idx    = {1'b0, bfly_idx[1:0], 1'b0};
            end

            2'd3: begin
                logical_p = {1'b0, bfly_idx};
                logical_q = {1'b1, bfly_idx};
                tw_idx    = {1'b0, bfly_idx};
            end

            default: begin
                logical_p = 4'd0;
                logical_q = 4'd0;
                tw_idx    = 4'd0;
            end
        endcase

        addr_p = bit_reverse4(logical_p);
        addr_q = bit_reverse4(logical_q);
    end

endmodule