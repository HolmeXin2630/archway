`define arc_param_begin \
  virtual function arc_param_apply_result_e apply_arc_param(string path, string value);

`define arc_param_end \
    return ARC_PARAM_NOT_MATCHED; \
  endfunction

`define arc_param_int(VAR) \
  if (path == `"VAR`") begin \
    int arc_param_value__; \
    if (!arc_param_utils::arc_param_try_to_int(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
    VAR = arc_param_value__; \
    return ARC_PARAM_APPLIED; \
  end

`define arc_param_bit(VAR) \
  if (path == `"VAR`") begin \
    int arc_param_value__; \
    if (!arc_param_utils::arc_param_try_to_int(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
    VAR = (arc_param_value__ != 0); \
    return ARC_PARAM_APPLIED; \
  end

`define arc_param_string(VAR) \
  if (path == `"VAR`") begin \
    VAR = arc_param_utils::arc_param_unquote(value); \
    return ARC_PARAM_APPLIED; \
  end

`define arc_param_real(VAR) \
  if (path == `"VAR`") begin \
    real arc_param_value__; \
    if (!arc_param_utils::arc_param_try_to_real(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
    VAR = arc_param_value__; \
    return ARC_PARAM_APPLIED; \
  end

`define arc_param_enum(VAR, PARSE_FUNC) \
  if (path == `"VAR`") begin \
    int arc_param_saved_value__; \
    arc_param_saved_value__ = VAR; \
    if (!PARSE_FUNC(value, VAR)) begin \
      if (!$cast(VAR, arc_param_saved_value__)) return ARC_PARAM_INVALID_VALUE; \
      return ARC_PARAM_INVALID_VALUE; \
    end \
    return ARC_PARAM_APPLIED; \
  end

`define arc_param_queue_int(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_queue_int(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; int arc_param_value__; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0 || !arc_param_utils::arc_param_try_to_int(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      while (VAR.size() <= arc_param_index__) VAR.push_back(0); \
      VAR[arc_param_index__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_queue_real(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_queue_real(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; real arc_param_value__; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0 || !arc_param_utils::arc_param_try_to_real(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      while (VAR.size() <= arc_param_index__) VAR.push_back(0.0); \
      VAR[arc_param_index__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_queue_string(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_queue_string(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0) return ARC_PARAM_INVALID_VALUE; \
      while (VAR.size() <= arc_param_index__) VAR.push_back(""); \
      VAR[arc_param_index__] = arc_param_utils::arc_param_unquote(value); \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_array_int(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_array_int(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; int arc_param_value__; int arc_param_old[]; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0 || !arc_param_utils::arc_param_try_to_int(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
      VAR[arc_param_index__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_array_real(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_array_real(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; real arc_param_value__; real arc_param_old[]; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0 || !arc_param_utils::arc_param_try_to_real(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
      VAR[arc_param_index__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_array_string(VAR) \
  if (path == `"VAR`") begin \
    if (!arc_param_utils::arc_param_assign_array_string(VAR, value)) return ARC_PARAM_INVALID_VALUE; \
    return ARC_PARAM_APPLIED; \
  end else begin \
    int arc_param_index__; string arc_param_old[]; \
    if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
      if (arc_param_index__ < 0) return ARC_PARAM_INVALID_VALUE; \
      if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
      VAR[arc_param_index__] = arc_param_utils::arc_param_unquote(value); \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_assoc_int(VAR) \
  begin \
    string arc_param_key__; int arc_param_value__; \
    if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin \
      if (!arc_param_utils::arc_param_try_to_int(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      VAR[arc_param_key__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_assoc_real(VAR) \
  begin \
    string arc_param_key__; real arc_param_value__; \
    if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin \
      if (!arc_param_utils::arc_param_try_to_real(value, arc_param_value__)) return ARC_PARAM_INVALID_VALUE; \
      VAR[arc_param_key__] = arc_param_value__; \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_assoc_string(VAR) \
  begin \
    string arc_param_key__; \
    if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin \
      VAR[arc_param_key__] = arc_param_utils::arc_param_unquote(value); \
      return ARC_PARAM_APPLIED; \
    end \
  end

`define arc_param_sub_config(VAR) \
  `arc_param_sub_config_as(`"VAR`", VAR)

`define arc_param_sub_config_as(PATH_NAME, HANDLE) \
  if (path == PATH_NAME) begin \
    return ARC_PARAM_INVALID_VALUE; \
  end else if (arc_param_utils::arc_param_starts_with(path, {PATH_NAME, "."})) begin \
    string arc_param_tail__; string arc_param_name__; \
    if (HANDLE == null) return ARC_PARAM_INVALID_VALUE; \
    arc_param_name__ = PATH_NAME; \
    HANDLE.bind_param_path({get_param_path(), ".", arc_param_name__}); \
    if (HANDLE.get_param_path() != {get_param_path(), ".", arc_param_name__}) return ARC_PARAM_APPLIED; \
    arc_param_tail__ = path.substr(arc_param_name__.len() + 1, path.len() - 1); \
    return HANDLE.apply_arc_param(arc_param_tail__, value); \
  end

`define arc_param_sub_config_queue(VAR) \
  `arc_param_sub_config_queue_as(`"VAR`", VAR)

`define arc_param_sub_config_queue_as(PATH_NAME, HANDLE_Q) \
  begin \
    int arc_param_index__; string arc_param_tail__; string arc_param_child_path__; string arc_param_name__; \
    arc_param_name__ = PATH_NAME; \
    if (arc_param_utils::arc_param_match_index_tail(path, arc_param_name__, arc_param_index__, arc_param_tail__)) begin \
      if (arc_param_index__ < 0 || arc_param_tail__.len() == 0 || arc_param_index__ >= HANDLE_Q.size() || HANDLE_Q[arc_param_index__] == null) return ARC_PARAM_INVALID_VALUE; \
      arc_param_child_path__ = {get_param_path(), ".", arc_param_name__, "[", $sformatf("%0d", arc_param_index__), "]"}; \
      HANDLE_Q[arc_param_index__].bind_param_path(arc_param_child_path__); \
      if (HANDLE_Q[arc_param_index__].get_param_path() != arc_param_child_path__) return ARC_PARAM_APPLIED; \
      return HANDLE_Q[arc_param_index__].apply_arc_param(arc_param_tail__, value); \
    end \
  end

`define arc_param_sub_config_queue_new(VAR, TYPE) \
  `arc_param_sub_config_queue_new_as(`"VAR`", VAR, TYPE)

`define arc_param_sub_config_queue_new_as(PATH_NAME, HANDLE_Q, TYPE) \
  begin \
    int arc_param_index__; string arc_param_tail__; string arc_param_child_path__; string arc_param_name__; \
    arc_param_name__ = PATH_NAME; \
    if (arc_param_utils::arc_param_match_index_tail(path, arc_param_name__, arc_param_index__, arc_param_tail__)) begin \
      if (arc_param_index__ < 0 || arc_param_tail__.len() == 0) return ARC_PARAM_INVALID_VALUE; \
      while (HANDLE_Q.size() <= arc_param_index__) begin TYPE arc_param_new_item__; arc_param_new_item__ = new(); HANDLE_Q.push_back(arc_param_new_item__); end \
      arc_param_child_path__ = {get_param_path(), ".", arc_param_name__, "[", $sformatf("%0d", arc_param_index__), "]"}; \
      HANDLE_Q[arc_param_index__].bind_param_path(arc_param_child_path__); \
      if (HANDLE_Q[arc_param_index__].get_param_path() != arc_param_child_path__) return ARC_PARAM_APPLIED; \
      return HANDLE_Q[arc_param_index__].apply_arc_param(arc_param_tail__, value); \
    end \
  end
