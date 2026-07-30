module test_arc_param_randomize_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    randomize_base_config base_cfg;
    randomize_override_config override_cfg;
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/common.tc");
    base_cfg = new("base_rand");
    override_cfg = new("override_rand");

    if (!base_cfg.randomize() || !override_cfg.randomize()) $fatal(1, "randomize failed");
    if (base_cfg.run_num != 37 || override_cfg.run_num != 52 || !override_cfg.business_post_randomize_ran) $fatal(1, "post_randomize did not restore TC final priority");
    if (ARC_PARAM_DB.used_count != 2) $fatal(1, "replay changed usage statistics");

    $display("test_arc_param_randomize_usage PASS");
    $finish;
  end
endmodule
