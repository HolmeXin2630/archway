module test_arc_param_collections_usage;
  import arc_param_pkg::*;
  import arc_param_test_pkg::*;

  initial begin
    tap_config cfg;
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/tc/common.tc");
    cfg = new("collection_cfg");

    if (cfg.int_queue.size() != 3 || cfg.int_queue[0] != 1 || cfg.int_queue[2] != 3) $fatal(1, "int queue whole assignment failed");
    if (cfg.real_queue.size() != 2 || cfg.real_queue[1] != 1.25) $fatal(1, "real queue whole assignment failed");
    if (cfg.string_queue.size() != 2 || cfg.string_queue[0] != "a,b" || cfg.string_queue[1] != "c") $fatal(1, "string queue whole assignment failed");
    if (cfg.int_array.size() != 3 || cfg.int_array[0] != 4 || cfg.int_array[2] != 6) $fatal(1, "int array assignment failed");
    if (cfg.real_array.size() != 2 || cfg.real_array[0] != 2.5) $fatal(1, "real array assignment failed");
    if (cfg.string_array.size() != 2 || cfg.string_array[1] != "two,three") $fatal(1, "string array assignment failed");
    if (cfg.weight["tap0"] != 7 || cfg.weight_ratio["tap0"] != 0.5 || cfg.alias_name["tap0"] != "fast") $fatal(1, "associative assignment failed");
    if (cfg.lanes.size() != 2 || cfg.lanes[1].run_num != 9 || cfg.lanes[1].get_param_path() != "collection_cfg.lanes[1]") $fatal(1, "automatic sub-config queue failed");
    if (cfg.precreated_lanes[0].run_num != 3 || cfg.precreated_lanes[0].get_param_path() != "collection_cfg.precreated_lanes[0]") $fatal(1, "precreated sub-config queue failed");

    $display("test_arc_param_collections_usage PASS");
    $finish;
  end
endmodule
