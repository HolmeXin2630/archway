function void arc_param_object::load_arc_param();
  ARC_PARAM_DB.load(this);
endfunction

`define arc_param_begin \
  virtual function bit apply_arc_param(string path, string value);

`define arc_param_end \
    return 0; \
  endfunction

`define arc_param_int(VAR) \
  if (path == `"VAR`") begin VAR = arc_param_utils::arc_param_to_int(value); return 1; end

`define arc_param_bit(VAR) \
  if (path == `"VAR`") begin VAR = (arc_param_utils::arc_param_to_int(value) != 0); return 1; end

`define arc_param_string(VAR) \
  if (path == `"VAR`") begin VAR = arc_param_utils::arc_param_unquote(value); return 1; end

`define arc_param_real(VAR) \
  if (path == `"VAR`") begin VAR = arc_param_utils::arc_param_to_real(value); return 1; end

`define arc_param_enum(VAR, PARSE_FUNC) \
  if (path == `"VAR`") begin VAR = PARSE_FUNC(value); return 1; end

`define arc_param_queue_int(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_queue_int(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative queue index"); return 1; end while (VAR.size() <= arc_param_index__) VAR.push_back(0); \
    VAR[arc_param_index__] = arc_param_utils::arc_param_to_int(value); return 1; end end

`define arc_param_queue_real(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_queue_real(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative queue index"); return 1; end while (VAR.size() <= arc_param_index__) VAR.push_back(0.0); \
    VAR[arc_param_index__] = arc_param_utils::arc_param_to_real(value); return 1; end end

`define arc_param_queue_string(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_queue_string(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative queue index"); return 1; end while (VAR.size() <= arc_param_index__) VAR.push_back(""); \
    VAR[arc_param_index__] = arc_param_utils::arc_param_unquote(value); return 1; end end

`define arc_param_array_int(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_array_int(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin int arc_param_old[]; \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative array index"); return 1; end \
    if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
    VAR[arc_param_index__] = arc_param_utils::arc_param_to_int(value); return 1; end end

`define arc_param_array_real(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_array_real(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin real arc_param_old[]; \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative array index"); return 1; end \
    if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
    VAR[arc_param_index__] = arc_param_utils::arc_param_to_real(value); return 1; end end

`define arc_param_array_string(VAR) \
  if (path == `"VAR`") begin arc_param_utils::arc_param_assign_array_string(VAR, value); return 1; end \
  else begin int arc_param_index__; if (arc_param_utils::arc_param_match_index(path, `"VAR`", arc_param_index__)) begin string arc_param_old[]; \
    if (arc_param_index__ < 0) begin ARC_PARAM_DB.report_error("negative array index"); return 1; end \
    if (VAR.size() <= arc_param_index__) begin arc_param_old = VAR; VAR = new[arc_param_index__ + 1]; foreach (arc_param_old[i]) VAR[i] = arc_param_old[i]; end \
    VAR[arc_param_index__] = arc_param_utils::arc_param_unquote(value); return 1; end end

`define arc_param_assoc_int(VAR) \
  begin string arc_param_key__; if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin VAR[arc_param_key__] = arc_param_utils::arc_param_to_int(value); return 1; end end

`define arc_param_assoc_real(VAR) \
  begin string arc_param_key__; if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin VAR[arc_param_key__] = arc_param_utils::arc_param_to_real(value); return 1; end end

`define arc_param_assoc_string(VAR) \
  begin string arc_param_key__; if (arc_param_utils::arc_param_match_string_key(path, `"VAR`", arc_param_key__)) begin VAR[arc_param_key__] = arc_param_utils::arc_param_unquote(value); return 1; end end

`define arc_param_queue_object(PATH_NAME, HANDLE_Q) \
  begin int arc_param_index__; string arc_param_tail__; if (arc_param_utils::arc_param_match_index_tail(path, `"PATH_NAME`", arc_param_index__, arc_param_tail__)) begin \
    if (arc_param_index__ < 0 || arc_param_tail__.len() == 0 || arc_param_index__ >= HANDLE_Q.size() || HANDLE_Q[arc_param_index__] == null) return 0; \
    return HANDLE_Q[arc_param_index__].apply_arc_param(arc_param_tail__, value); end end

`define arc_param_queue_object_new(PATH_NAME, HANDLE_Q, TYPE) \
  begin int arc_param_index__; string arc_param_tail__; if (arc_param_utils::arc_param_match_index_tail(path, `"PATH_NAME`", arc_param_index__, arc_param_tail__)) begin \
    if (arc_param_index__ < 0 || arc_param_tail__.len() == 0) return 0; \
    while (HANDLE_Q.size() <= arc_param_index__) begin TYPE arc_param_new_item__; arc_param_new_item__ = new(); HANDLE_Q.push_back(arc_param_new_item__); end \
    return HANDLE_Q[arc_param_index__].apply_arc_param(arc_param_tail__, value); end end

`define arc_param_object(PATH_NAME, HANDLE) \
  if (arc_param_utils::arc_param_starts_with(path, `"PATH_NAME.`") && HANDLE != null) \
    return HANDLE.apply_arc_param(path.substr(arc_param_utils::arc_param_find_char(path, ".") + 1, path.len() - 1), value);


