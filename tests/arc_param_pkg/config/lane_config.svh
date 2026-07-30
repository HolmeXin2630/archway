class lane_config extends arc_param_config;
  rand int run_num;

  function new(string param_path = "");
    super.new(param_path);
    run_num = 0;
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  `arc_param_begin
    `arc_param_int(run_num)
  `arc_param_end
endclass
