`timescale 1ns/1ps

module testbench;
  reg clk = 0;
  reg rst = 0;
  reg [31:0] a_west0, a_west1, a_west2, a_west3;
  reg [31:0] b_north0, b_north1, b_north2, b_north3;
  wire done;
  wire [63:0] result0, result1, result2, result3;
  wire [63:0] result4, result5, result6, result7;
  wire [63:0] result8, result9, result10, result11;
  wire [63:0] result12, result13, result14, result15;

  integer pass_count = 0;
  integer fail_count = 0;
  integer cycle;

  systolic_matrix_mult uut(
    .a_west0(a_west0), .a_west1(a_west1), .a_west2(a_west2), .a_west3(a_west3),
    .b_north0(b_north0), .b_north1(b_north1), .b_north2(b_north2), .b_north3(b_north3),
    .clk(clk), .rst(rst), .done(done),
    .result0(result0), .result1(result1), .result2(result2), .result3(result3),
    .result4(result4), .result5(result5), .result6(result6), .result7(result7),
    .result8(result8), .result9(result9), .result10(result10), .result11(result11),
    .result12(result12), .result13(result13), .result14(result14), .result15(result15)
  );

  always #5 clk = ~clk;

  task clear_inputs;
    begin
      a_west0 = 0; a_west1 = 0; a_west2 = 0; a_west3 = 0;
      b_north0 = 0; b_north1 = 0; b_north2 = 0; b_north3 = 0;
    end
  endtask

  task check64;
    input [127:0] label;
    input [63:0] got;
    input [63:0] exp;
    begin
      if (got === exp) begin
        $display("[PASS] %0s expected=%0d got=%0d", label, exp, got);
        pass_count = pass_count + 1;
      end else begin
        $display("[FAIL] %0s expected=%0d got=%0d", label, exp, got);
        fail_count = fail_count + 1;
      end
    end
  endtask

  task feed_first_case;
    begin
      for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
        @(negedge clk);
        a_west0 = (cycle == 0) ? 32'd1  : (cycle == 1) ? 32'd2  : (cycle == 2) ? 32'd3  : (cycle == 3) ? 32'd4  : 32'd0;
        a_west1 = (cycle == 1) ? 32'd5  : (cycle == 2) ? 32'd6  : (cycle == 3) ? 32'd7  : (cycle == 4) ? 32'd8  : 32'd0;
        a_west2 = (cycle == 2) ? 32'd9  : (cycle == 3) ? 32'd10 : (cycle == 4) ? 32'd11 : (cycle == 5) ? 32'd12 : 32'd0;
        a_west3 = (cycle == 3) ? 32'd13 : (cycle == 4) ? 32'd14 : (cycle == 5) ? 32'd15 : (cycle == 6) ? 32'd16 : 32'd0;
        b_north0 = (cycle == 0) ? 32'd1  : (cycle == 1) ? 32'd5  : (cycle == 2) ? 32'd9  : (cycle == 3) ? 32'd13 : 32'd0;
        b_north1 = (cycle == 1) ? 32'd2  : (cycle == 2) ? 32'd6  : (cycle == 3) ? 32'd10 : (cycle == 4) ? 32'd14 : 32'd0;
        b_north2 = (cycle == 2) ? 32'd3  : (cycle == 3) ? 32'd7  : (cycle == 4) ? 32'd11 : (cycle == 5) ? 32'd15 : 32'd0;
        b_north3 = (cycle == 3) ? 32'd4  : (cycle == 4) ? 32'd8  : (cycle == 5) ? 32'd12 : (cycle == 6) ? 32'd16 : 32'd0;
      end
      @(negedge clk);
      clear_inputs();
    end
  endtask

  task feed_second_case;
    begin
      for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
        @(negedge clk);
        a_west0 = (cycle == 0) ? 32'd0  : (cycle == 1) ? 32'd1  : (cycle == 2) ? 32'd2  : (cycle == 3) ? 32'd3  : 32'd0;
        a_west1 = (cycle == 1) ? 32'd4  : (cycle == 2) ? 32'd5  : (cycle == 3) ? 32'd6  : (cycle == 4) ? 32'd7  : 32'd0;
        a_west2 = (cycle == 2) ? 32'd8  : (cycle == 3) ? 32'd9  : (cycle == 4) ? 32'd10 : (cycle == 5) ? 32'd11 : 32'd0;
        a_west3 = (cycle == 3) ? 32'd12 : (cycle == 4) ? 32'd13 : (cycle == 5) ? 32'd14 : (cycle == 6) ? 32'd15 : 32'd0;
        b_north0 = (cycle == 0) ? 32'd1 : 32'd0;
        b_north1 = (cycle == 2) ? 32'd1 : 32'd0;
        b_north2 = (cycle == 4) ? 32'd1 : 32'd0;
        b_north3 = (cycle == 6) ? 32'd1 : 32'd0;
      end
      @(negedge clk);
      clear_inputs();
    end
  endtask

  task reset_dut;
    begin
      clear_inputs();
      @(negedge clk);
      rst = 1;
      @(negedge clk);
      rst = 0;
    end
  endtask

  initial begin
    reset_dut();
    feed_first_case();
    repeat (12) @(posedge clk);
    check64("A2_r0c0", result0,  64'd90);
    check64("A2_r0c1", result1,  64'd100);
    check64("A2_r0c2", result2,  64'd110);
    check64("A2_r0c3", result3,  64'd120);
    check64("A2_r1c0", result4,  64'd202);
    check64("A2_r1c1", result5,  64'd228);
    check64("A2_r1c2", result6,  64'd254);
    check64("A2_r1c3", result7,  64'd280);
    check64("A2_r2c0", result8,  64'd314);
    check64("A2_r2c1", result9,  64'd356);
    check64("A2_r2c2", result10, 64'd398);
    check64("A2_r2c3", result11, 64'd440);
    check64("A2_r3c0", result12, 64'd426);
    check64("A2_r3c1", result13, 64'd484);
    check64("A2_r3c2", result14, 64'd542);
    check64("A2_r3c3", result15, 64'd600);

    reset_dut();
    feed_second_case();
    repeat (12) @(posedge clk);
    check64("AI_r0c0", result0,  64'd0);
    check64("AI_r0c1", result1,  64'd1);
    check64("AI_r0c2", result2,  64'd2);
    check64("AI_r0c3", result3,  64'd3);
    check64("AI_r1c0", result4,  64'd4);
    check64("AI_r1c1", result5,  64'd5);
    check64("AI_r1c2", result6,  64'd6);
    check64("AI_r1c3", result7,  64'd7);
    check64("AI_r2c0", result8,  64'd8);
    check64("AI_r2c1", result9,  64'd9);
    check64("AI_r2c2", result10, 64'd10);
    check64("AI_r2c3", result11, 64'd11);
    check64("AI_r3c0", result12, 64'd12);
    check64("AI_r3c1", result13, 64'd13);
    check64("AI_r3c2", result14, 64'd14);
    check64("AI_r3c3", result15, 64'd15);

    $display("TEST SUMMARY: %0d PASS, %0d FAILED", pass_count, fail_count);
    $finish;
  end
endmodule
