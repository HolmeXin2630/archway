module test_arc_param_codec;
  import arc_param_pkg::*;

  task automatic expect_int(string name, longint actual, longint expected);
    if (actual !== expected) $fatal(1, "%s: expected %0d, got %0d", name, expected, actual);
  endtask

  initial begin
    expect_int("digit", arc_param_utils::arc_param_base_digit_value("1"), 1);
    if (!arc_param_utils::arc_param_char_is_base_digit("f", 16)) $fatal(1, "base digit recognition failed");
    expect_int("based digits", $signed(arc_param_utils::arc_param_parse_based_digits("123", 10)), 123);
    expect_int("decimal", arc_param_utils::arc_param_to_int("123"), 123);
    expect_int("signed", arc_param_utils::arc_param_to_int("-123"), -123);
    expect_int("underscore", arc_param_utils::arc_param_to_int("1_000"), 1000);
    expect_int("hex", arc_param_utils::arc_param_to_int("0x10"), 16);
    expect_int("binary", arc_param_utils::arc_param_to_int("0b1010"), 10);
    expect_int("octal", arc_param_utils::arc_param_to_int("0o17"), 15);
    expect_int("sv hex", arc_param_utils::arc_param_to_int("32'hff"), 255);
    expect_int("sv binary", arc_param_utils::arc_param_to_int("'b1010"), 10);
    expect_int("sv octal", arc_param_utils::arc_param_to_int("'o17"), 15);
    expect_int("sv decimal", arc_param_utils::arc_param_to_int("'d10"), 10);
    expect_int("longint", arc_param_utils::arc_param_to_longint("12345678901"), 64'sd12345678901);
    expect_int("unsigned", $signed(arc_param_utils::arc_param_to_longint_unsigned("0xffffffff")), 64'sd4294967295);
    if ((arc_param_utils::arc_param_to_real("0.75") - 0.75 > 0.000001) || (0.75 - arc_param_utils::arc_param_to_real("0.75") > 0.000001)) $fatal(1, "real conversion failed");
    if (arc_param_utils::arc_param_unquote("  \"fast\" ") != "fast") $fatal(1, "unquote failed");
    if (arc_param_utils::arc_param_to_longint_unsigned("0xno") != 64'hffff_ffff_ffff_ffff) $fatal(1, "sentinel failed");
    $display("test_arc_param_codec PASS");
    $finish;
  end
endmodule

