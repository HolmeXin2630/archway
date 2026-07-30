class randomize_override_config extends arc_param_config;
  rand int run_num;
  bit business_post_randomize_ran;

  function new(string param_path = "");
    super.new(param_path);
    run_num = 1;
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  function void post_randomize();
    business_post_randomize_ran = 1;
    super.post_randomize();
  endfunction

  `arc_param_begin
    `arc_param_int(run_num)
  `arc_param_end
endclass
