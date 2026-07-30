module test_arc_param_override_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config cfg;
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:override_cfg.run_num=1", "common.tc", 1);
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/override.tc");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:override_cfg.run_num=11", "late.tc", 1);
    cfg = new("override_cfg");

    if (cfg.run_num != 11) $fatal(1, "later TC file did not override the earlier key");
    if (ARC_PARAM_DB.total_count != 3 || ARC_PARAM_DB.used_count != 3 || ARC_PARAM_DB.warning_count != 1) $fatal(1, "duplicate diagnostics are incorrect");
    $display("test_arc_param_override_usage PASS");
    $finish;
  end
endmodule
