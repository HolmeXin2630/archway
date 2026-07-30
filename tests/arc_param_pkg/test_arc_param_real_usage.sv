module test_arc_param_real_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config tap0;
    tap_config tap1;
    tap_config tap0_copy;

    if (ARC_PARAM_DB !== arc_param_db::get()) $fatal(1, "ARC_PARAM_DB is not the singleton instance");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/real_usage.tc");

    tap0 = new("tch0_tap0_opt");
    tap1 = new("tch1_tap0_opt");
    tap0_copy = new("tch0_tap0_opt");

    if (tap0.run_num != 1 || tap0.start_ms != 0 || tap0.end_ms != 80) $fatal(1, "tap0 scalar injection failed");
    if (tap0.mode != "fast" || tap0.enabled != 1 || tap0.sat_type != GLO_L10F) $fatal(1, "tap0 type injection failed");
    if ((tap0.ratio - 0.75 > 0.000001) || (0.75 - tap0.ratio > 0.000001)) $fatal(1, "tap0 real injection failed");
    if (tap0.run_list.size() != 2 || tap0.run_list[0] != 10 || tap0.run_list[1] != 20) $fatal(1, "tap0 queue injection failed");
    if (tap0.sub_cfg.delay != 5 || tap0.sub_cfg.get_param_path() != "tch0_tap0_opt.sub_cfg") $fatal(1, "nested config injection failed");
    if (tap1.run_num != 2 || tap1.mode != "default") $fatal(1, "path isolation failed");
    if (tap0_copy.run_num != 1 || tap0_copy.sub_cfg.delay != 5) $fatal(1, "same path must load into each handle");
    if (ARC_PARAM_DB.used_count != 11 || ARC_PARAM_DB.unknown_count != 1 || ARC_PARAM_DB.warning_count != 1) $fatal(1, "unexpected initial diagnostics");

    $display("test_arc_param_real_usage PASS");
    $finish;
  end
endmodule
