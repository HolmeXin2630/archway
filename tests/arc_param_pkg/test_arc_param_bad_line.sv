module test_arc_param_bad_line;
  import arc_param_pkg::*;
  initial begin
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:bad_line");
    if (ARC_PARAM_DB.error_count != 1 || ARC_PARAM_DB.total_count != 0) $fatal(1, "bad line handling failed");
    $display("test_arc_param_bad_line PASS");
    $finish;
  end
endmodule
