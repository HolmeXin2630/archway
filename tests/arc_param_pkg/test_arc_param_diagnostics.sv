module test_arc_param_diagnostics;
  import arc_param_pkg::*;
  class cfg_c extends arc_param_object;
    int run_list[$];
    function new(string name = ""); super.new(name); endfunction
    `arc_param_begin
      `arc_param_queue_int(run_list)
    `arc_param_end
  endclass
  initial begin
    cfg_c cfg = new("cfg");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.run_list[0]=1");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.unknown=2");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:other.x=3");
    cfg.load_arc_param();
    cfg.load_arc_param();
    ARC_PARAM_DB.check_unused();
    ARC_PARAM_DB.check_unused();
    ARC_PARAM_DB.summary();
    if (ARC_PARAM_DB.total_count != 3 || ARC_PARAM_DB.used_count != 1 || ARC_PARAM_DB.unknown_count != 1 || ARC_PARAM_DB.unused_count != 2) $fatal(1, "diagnostic counts failed");
    if (ARC_PARAM_DB.warning_count != 3 || ARC_PARAM_DB.error_count != 0) $fatal(1, "diagnostic warning counts failed");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.set_strict(1, 1);
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.unknown=2");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:other.x=3");
    cfg.load_arc_param();
    ARC_PARAM_DB.check_unused();
    if (ARC_PARAM_DB.error_count != 3) $fatal(1, "strict diagnostics failed");
    $display("test_arc_param_diagnostics PASS");
    $finish;
  end
endmodule
