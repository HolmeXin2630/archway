module test_arc_param_binding_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config bound_cfg;
    tap_config second_cfg;
    delay_config shared_a;
    delay_config shared_b;
    delay_config single;

    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/common.tc");
    bound_cfg = new("bound_cfg");
    if (bound_cfg.sub_cfg.get_param_path() != "bound_cfg.sub_cfg" || bound_cfg.lanes[1].get_param_path() != "bound_cfg.lanes[1]") $fatal(1, "nested binding path was not derived");

    bound_cfg.sub_cfg.delay = 99;
    ARC_PARAM_DB.load_tc_param(bound_cfg.sub_cfg);
    if (bound_cfg.sub_cfg.delay != 7) $fatal(1, "bound child cannot independently replay its parameters");
    ARC_PARAM_DB.load_tc_param(bound_cfg);
    if (bound_cfg.lanes.size() != 2 || bound_cfg.lanes[1].run_num != 11) $fatal(1, "sub-config queue topology changed during replay");

    second_cfg = new("second_cfg");
    second_cfg.sub_cfg = bound_cfg.sub_cfg;
    ARC_PARAM_DB.load_tc_param(second_cfg);
    if (bound_cfg.sub_cfg.delay != 7 || ARC_PARAM_DB.error_count != 1) $fatal(1, "rebound child accepted a second parent path");

    shared_a = new("shared");
    shared_b = new("shared");
    if (shared_a.delay != 8 || shared_b.delay != 8) $fatal(1, "different handles cannot share a TC path");

    single = new();
    if (single.delay != 3) $fatal(1, "empty path must be a no-op");
    single.bind_param_path("single");
    ARC_PARAM_DB.load_tc_param(single);
    if (single.delay != 4) $fatal(1, "late first binding did not load parameters");
    single.bind_param_path("other");
    if (single.get_param_path() != "single" || ARC_PARAM_DB.error_count != 2) $fatal(1, "binding path must be immutable");

    $display("test_arc_param_binding_usage PASS");
    $finish;
  end
endmodule
