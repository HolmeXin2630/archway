module test_arc_param_assoc_object;
  import arc_param_pkg::*;

  class lane_c extends arc_param_object;
    int run_num;
    function new(string name = ""); super.new(name); endfunction
    `arc_param_begin
      `arc_param_int(run_num)
    `arc_param_end
  endclass

  class cfg_c extends arc_param_object;
    int weight[string];
    string alias_name[string];
    real ratio[string];
    lane_c lanes[$];
    lane_c precreated[$];
    function new(string name = "");
      lane_c initial_lane;
      super.new(name);
      initial_lane = new("pre");
      precreated.push_back(initial_lane);
    endfunction
    `arc_param_begin
      `arc_param_assoc_int(weight)
      `arc_param_assoc_string(alias_name)
      `arc_param_assoc_real(ratio)
      `arc_param_queue_object_new(lanes, lanes, lane_c)
      `arc_param_queue_object(precreated, precreated)
    `arc_param_end
  endclass

  initial begin
    cfg_c cfg = new("cfg");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.weight[\"tap0\"]=7");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.alias_name[\"tap0\"]=\"fast\"");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.ratio[\"tap0\"]=0.5");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.lanes[1].run_num=9");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.precreated[0].run_num=3");
    cfg.load_arc_param();
    if (cfg.weight["tap0"] != 7 || cfg.alias_name["tap0"] != "fast" || cfg.ratio["tap0"] != 0.5) $fatal(1, "assoc injection failed");
    if (cfg.lanes.size() != 2 || cfg.lanes[1].run_num != 9 || cfg.precreated[0].run_num != 3) $fatal(1, "object queue injection failed");
    $display("test_arc_param_assoc_object PASS");
    $finish;
  end
endmodule
