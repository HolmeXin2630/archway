module test_arc_param_invalid_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config cfg;
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/invalid.tc");
    cfg = new("invalid_cfg");
    if (cfg.start_ms != 10 || cfg.ratio != 0.25 || cfg.sat_type != GLO_L1F) $fatal(1, "invalid scalar value changed a default");
    if (cfg.run_list.size() != 0 || cfg.lanes.size() != 0) $fatal(1, "invalid collection path changed topology");
    if (cfg.run_num != 17) $fatal(1, "later legal duplicate did not override invalid value");
    if (ARC_PARAM_DB.total_count != 7 || ARC_PARAM_DB.used_count != 1 || ARC_PARAM_DB.error_count != 7 || ARC_PARAM_DB.warning_count != 1) $fatal(1, "invalid diagnostics are incorrect");
    ARC_PARAM_DB.load_tc_param(cfg);
    ARC_PARAM_DB.check_unused();
    if (ARC_PARAM_DB.error_count != 7 || ARC_PARAM_DB.unused_count != 0) $fatal(1, "invalid replay duplicated diagnostics or became unused");

    ARC_PARAM_DB.load_tc_param(null);
    if (ARC_PARAM_DB.error_count != 8) $fatal(1, "null config must report an error");
    $display("test_arc_param_invalid_usage PASS");
    $finish;
  end
endmodule
