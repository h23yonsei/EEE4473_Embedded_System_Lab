`timescale 1ns/1ps

module top;

  logic [31:0] a, b;
  wire  [31:0] result;

  // DUT
  fp32_multiplier dut (
    .a(a),
    .b(b),
    .result(result)
  );

  function automatic logic [31:0] real_to_f32bits(input real r);
    shortreal sr;
    begin
      sr = r;
      real_to_f32bits = $shortrealtobits(sr);
    end
  endfunction

  function automatic shortreal f32bits_to_shortreal(input logic [31:0] bits);
    begin
      f32bits_to_shortreal = $bitstoshortreal(bits);
    end
  endfunction

  task automatic run_case(input int id, input real ra, input real rb);
    logic [31:0] aa, bb, exp_bits;
    shortreal sa, sb, sy;

    begin
      // convert to bits
      aa = real_to_f32bits(ra);
      bb = real_to_f32bits(rb);

      a = aa;
      b = bb;
      #1;

      sa = f32bits_to_shortreal(aa);
      sb = f32bits_to_shortreal(bb);
      sy = sa * sb;
      exp_bits = $shortrealtobits(sy);

      if (result !== exp_bits) begin
        $display("FAIL[%0d]", id);
        $display("  ra=%f rb=%f", ra, rb);
        $display("  a_bits=%h (a=%f)", aa, sa);
        $display("  b_bits=%h (b=%f)", bb, sb);
        $display("  got=%h (=%f) expected=%h (=%f)",
                 result, f32bits_to_shortreal(result),
                 exp_bits, sy);
        $stop;
      end else begin
        $display("PASS[%0d] ra=%f rb=%f  => result=%h (=%f)",
                 id, ra, rb, result, f32bits_to_shortreal(result));
      end
    end
  endtask

  initial begin
    $display("---- FP32 MUL (auto real->FP32 via shortreal) ----");

    run_case(1,  1.5,    2.0);
    run_case(2, -1.5,    2.0);
    run_case(3,  0.5,   -0.5);
    run_case(4,  1.25,   1.5);
    run_case(5, -2.5,   -4.0);
    run_case(6,  6.0,    0.25);
    run_case(7,  3.0,    3.0);
    run_case(8,  0.75,   8.0);
    run_case(9,  1.3,    4.0);
    run_case(10, 0.0,   -7.25);

    $display("---- ALL PASSED ----");
    $finish;
  end

endmodule
