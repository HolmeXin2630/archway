module test_arc_param_negative;
  import arc_param_pkg::*;
  class cfg_c extends arc_param_object;
    int run_list[$];
    function new(string name = ""); super.new(name); run_list.push_back(5); endfunction
    `arc_param_begin
      `arc_param_queue_int(run_list)
    `arc_param_end
  endclass
  initial begin
    cfg_c cfg = new("cfg");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.run_list[-1]=99");
    cfg.load_arc_param();
    if (cfg.run_list.size() != 1 || cfg.run_list[0] != 5 || ARC_PARAM_DB.error_count != 1 || ARC_PARAM_DB.unknown_count != 0) $fatal(1, "negative index safety failed");
    $display("test_arc_param_negative PASS");
    $finish;
  end
endmodule
