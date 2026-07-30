module test_arc_param_diagnostics_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config cfg;
    run_only_config partial_cfg;
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/diagnostics.tc");
    cfg = new("diag_cfg");
    ARC_PARAM_DB.load_tc_param(cfg);
    if (ARC_PARAM_DB.total_count != 3 || ARC_PARAM_DB.used_count != 1 || ARC_PARAM_DB.unknown_count != 1 || ARC_PARAM_DB.warning_count != 1 || ARC_PARAM_DB.error_count != 0) $fatal(1, "non-strict load diagnostics are incorrect");
    ARC_PARAM_DB.check_unused();
    ARC_PARAM_DB.check_unused();
    if (ARC_PARAM_DB.unused_count != 1 || ARC_PARAM_DB.warning_count != 2 || ARC_PARAM_DB.error_count != 0) $fatal(1, "unused diagnostics are not idempotent");

    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.set_strict(1, 1);
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/diagnostics.tc");
    cfg = new("diag_cfg");
    ARC_PARAM_DB.check_unused();
    if (ARC_PARAM_DB.unknown_count != 1 || ARC_PARAM_DB.unused_count != 1 || ARC_PARAM_DB.warning_count != 0 || ARC_PARAM_DB.error_count != 2) $fatal(1, "strict diagnostics must upgrade rather than double-count");

    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:shared_cfg.mode=fast");
    partial_cfg = new("shared_cfg");
    cfg = new("shared_cfg");
    if (cfg.mode != "fast" || ARC_PARAM_DB.used_count != 1 || ARC_PARAM_DB.unknown_count != 0 || ARC_PARAM_DB.warning_count != 0) $fatal(1, "later matching handle did not resolve the final diagnostic category");

    $display("test_arc_param_diagnostics_usage PASS");
    $finish;
  end
endmodule
