module test_arc_param_phase1;
  import arc_param_pkg::*;

  typedef enum {GLO_L1F, GLO_L10F} sat_type_e;

  class sub_cfg_c extends arc_param_object;
    int delay;
    function new(string name = ""); super.new(name); endfunction
    `arc_param_begin
      `arc_param_int(delay)
    `arc_param_end
  endclass

  class cfg_c extends arc_param_object;
    int run_num;
    int start_ms;
    int end_ms;
    string mode;
    bit enabled;
    real ratio;
    sat_type_e sat_type;
    int run_list[$];
    sub_cfg_c sub_cfg;

    function new(string name = "");
      super.new(name);
      sub_cfg = new("sub_cfg");
    endfunction

    function sat_type_e parse_sat_type(string text);
      return text == "GLO_L10F" ? GLO_L10F : GLO_L1F;
    endfunction

    `arc_param_begin
      `arc_param_int(run_num)
      `arc_param_int(start_ms)
      `arc_param_int(end_ms)
      `arc_param_string(mode)
      `arc_param_bit(enabled)
      `arc_param_real(ratio)
      `arc_param_enum(sat_type, parse_sat_type)
      `arc_param_queue_int(run_list)
      `arc_param_object(sub_cfg, sub_cfg)
    `arc_param_end
  endclass

  initial begin
    cfg_c cfg;
    if (ARC_PARAM_DB !== arc_param_db::get()) $fatal(1, "ARC_PARAM_DB is not the singleton instance");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_file("../../tests/arc_param_pkg/case.tc");
    cfg = new("tch0_tap0_opt");
    cfg.load_arc_param();
    if (cfg.run_num != 1 || cfg.start_ms != 0 || cfg.end_ms != 80) $fatal(1, "integer injection failed");
    if (cfg.mode != "fast") $fatal(1, "string injection failed: '%s'", cfg.mode);
    if (cfg.enabled != 1) $fatal(1, "bit injection failed: %0d", cfg.enabled);
    if ((cfg.ratio - 0.75 > 0.000001) || (0.75 - cfg.ratio > 0.000001)) $fatal(1, "real injection failed: %f", cfg.ratio);
    if (cfg.sat_type != GLO_L10F || cfg.sub_cfg.delay != 5) $fatal(1, "enum or nested injection failed");
    if (cfg.run_list.size() != 2 || cfg.run_list[0] != 10 || cfg.run_list[1] != 20) $fatal(1, "queue index injection failed");
    if (ARC_PARAM_DB.unknown_count != 1 || ARC_PARAM_DB.warning_count != 1) $fatal(1, "unknown-field diagnostics failed");
    $display("test_arc_param_phase1 PASS");
    $finish;
  end
endmodule
