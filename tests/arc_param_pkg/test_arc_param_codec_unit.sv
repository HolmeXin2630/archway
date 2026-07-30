module test_arc_param_codec_unit;
  import arc_param_pkg::*;

  task automatic expect_int(string name, longint actual, longint expected);
    if (actual !== expected) $fatal(1, "%s: expected %0d, got %0d", name, expected, actual);
  endtask

  initial begin
    int parsed_int;
    real parsed_real;
    longint parsed_longint;
    longint unsigned parsed_unsigned;
    expect_int("decimal", arc_param_utils::arc_param_to_int("123"), 123);
    expect_int("signed", arc_param_utils::arc_param_to_int("-123"), -123);
    expect_int("underscore", arc_param_utils::arc_param_to_int("1_000"), 1000);
    expect_int("hex", arc_param_utils::arc_param_to_int("0x10"), 16);
    expect_int("binary", arc_param_utils::arc_param_to_int("0b1010"), 10);
    expect_int("octal", arc_param_utils::arc_param_to_int("0o17"), 15);
    expect_int("SV hex", arc_param_utils::arc_param_to_int("32'hff"), 255);
    expect_int("SV binary", arc_param_utils::arc_param_to_int("'b1010"), 10);
    expect_int("SV octal", arc_param_utils::arc_param_to_int("'o17"), 15);
    expect_int("SV decimal", arc_param_utils::arc_param_to_int("'d10"), 10);
    if (!arc_param_utils::arc_param_try_to_int("123", parsed_int) || parsed_int != 123) $fatal(1, "try int failed");
    if (!arc_param_utils::arc_param_try_to_longint("12345678901", parsed_longint) || parsed_longint != 64'sd12345678901) $fatal(1, "try longint failed");
    if (!arc_param_utils::arc_param_try_to_longint_unsigned("0xffffffff", parsed_unsigned) || parsed_unsigned != 64'd4294967295) $fatal(1, "try unsigned failed");
    if (!arc_param_utils::arc_param_try_to_real("0.75", parsed_real) || (parsed_real - 0.75 > 0.000001) || (0.75 - parsed_real > 0.000001)) $fatal(1, "try real failed");
    if (arc_param_utils::arc_param_try_to_int("0xno", parsed_int) || arc_param_utils::arc_param_try_to_longint("-", parsed_longint) || arc_param_utils::arc_param_try_to_real("+", parsed_real) || arc_param_utils::arc_param_try_to_real("not_a_real", parsed_real)) $fatal(1, "invalid codec input accepted");
    if (arc_param_utils::arc_param_unquote("  \"fast\" ") != "fast") $fatal(1, "unquote failed");
    $display("test_arc_param_codec_unit PASS");
    $finish;
  end
endmodule
