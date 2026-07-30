module test_arc_param_collection_path;
  import arc_param_pkg::*;
  class cfg_c extends arc_param_object;
    int values[];
    function new(string name = ""); super.new(name); endfunction
    `arc_param_begin
      `arc_param_array_int(values)
    `arc_param_end
  endclass
  initial begin
    cfg_c cfg = new("cfg");
    ARC_PARAM_DB.clear();
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.values[1]=7");
    ARC_PARAM_DB.parse_line("-ARC_PARAM:cfg.values[0]=3");
    cfg.load_arc_param();
    if (cfg.values.size() != 2 || cfg.values[0] != 3 || cfg.values[1] != 7) $fatal(1, "array path injection failed");
    $display("test_arc_param_collection_path PASS");
    $finish;
  end
endmodule
