module fft16_addr_gen (
    input  wire [1:0] stage,
    input  wire [2:0] butterfly_idx,
    output reg  [3:0] p_addr,
    output reg  [3:0] q_addr,
    output reg  [2:0] tw_addr
);

always @* begin
    p_addr  = 4'd0;
    q_addr  = 4'd0;
    tw_addr = 3'd0;

    case (stage)
        2'd0: begin
            p_addr  = {butterfly_idx, 1'b0};
            q_addr  = {butterfly_idx, 1'b0} + 4'd1;
            tw_addr = 3'd0;
        end

        2'd1: begin
            p_addr  = {butterfly_idx[2:1], 1'b0, butterfly_idx[0]};
            q_addr  = {butterfly_idx[2:1], 1'b0, butterfly_idx[0]} + 4'd2;
            tw_addr = {butterfly_idx[0], 2'b00};
        end

        2'd2: begin
            p_addr  = {butterfly_idx[2], 1'b0, butterfly_idx[1:0]};
            q_addr  = {butterfly_idx[2], 1'b0, butterfly_idx[1:0]} + 4'd4;
            tw_addr = {butterfly_idx[1:0], 1'b0};
        end

        2'd3: begin
            p_addr  = {1'b0, butterfly_idx};
            q_addr  = {1'b0, butterfly_idx} + 4'd8;
            tw_addr = butterfly_idx;
        end

        default: begin
            p_addr  = 4'd0;
            q_addr  = 4'd0;
            tw_addr = 3'd0;
        end
    endcase
end

endmodule