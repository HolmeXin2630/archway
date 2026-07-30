class delay_config extends arc_param_config;
  rand int delay;

  function new(string param_path = "");
    super.new(param_path);
    delay = 3;
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  `arc_param_begin
    `arc_param_int(delay)
  `arc_param_end
endclass
