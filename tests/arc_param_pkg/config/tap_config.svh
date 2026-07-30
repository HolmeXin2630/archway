typedef enum {GLO_L1F, GLO_L10F} sat_type_e;

class tap_config extends arc_param_config;
  rand int run_num;
  int start_ms;
  int end_ms;
  string mode;
  bit enabled;
  real ratio;
  sat_type_e sat_type;
  int run_list[$];
  int int_queue[$];
  real real_queue[$];
  string string_queue[$];
  int int_array[];
  real real_array[];
  string string_array[];
  int weight[string];
  real weight_ratio[string];
  string alias_name[string];
  delay_config sub_cfg;
  lane_config lanes[$];
  lane_config precreated_lanes[$];

  function new(string param_path = "");
    lane_config initial_lane;
    super.new(param_path);
    run_num = 0;
    start_ms = 10;
    end_ms = 20;
    mode = "default";
    enabled = 0;
    ratio = 0.25;
    sat_type = GLO_L1F;
    sub_cfg = new();
    initial_lane = new();
    precreated_lanes.push_back(initial_lane);
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  function bit parse_sat_type(string text, output sat_type_e parsed);
    case (text)
      "GLO_L1F": begin parsed = GLO_L1F; return 1; end
      "GLO_L10F": begin parsed = GLO_L10F; return 1; end
      default: begin parsed = GLO_L10F; return 0; end
    endcase
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
    `arc_param_queue_int(int_queue)
    `arc_param_queue_real(real_queue)
    `arc_param_queue_string(string_queue)
    `arc_param_array_int(int_array)
    `arc_param_array_real(real_array)
    `arc_param_array_string(string_array)
    `arc_param_assoc_int(weight)
    `arc_param_assoc_real(weight_ratio)
    `arc_param_assoc_string(alias_name)
    `arc_param_sub_config(sub_cfg)
    `arc_param_sub_config_queue_new(lanes, lane_config)
    `arc_param_sub_config_queue(precreated_lanes)
  `arc_param_end
endclass
