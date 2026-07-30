class arc_param_db;
  protected static arc_param_db m_instance;
  arc_param_item items[$];
  bit strict_unknown;
  bit strict_unused;
  int total_count;
  int used_count;
  int unused_count;
  int unknown_count;
  int error_count;
  int warning_count;
  bit m_duplicate_reported[string];

  local function new();
  endfunction

  static function arc_param_db get();
    if (m_instance == null) m_instance = new();
    return m_instance;
  endfunction

  function void clear();
    items.delete(); strict_unknown = 0; strict_unused = 0;
    total_count = 0; used_count = 0; unused_count = 0; unknown_count = 0;
    error_count = 0; warning_count = 0;
    m_duplicate_reported.delete();
  endfunction

  function void set_strict(bit strict_unknown_en = 1, bit strict_unused_en = 1);
    strict_unknown = strict_unknown_en;
    strict_unused = strict_unused_en;
  endfunction

  function string item_full_path(arc_param_item item);
    return {item.param_name, ".", item.path};
  endfunction

  function void parse_line(string line, string file = "", int line_no = 0);
    string text; string body; string full_path; int dot; int equal; int previous_index; arc_param_item item;
    text = arc_param_utils::arc_param_trim(line);
    if (text.len() == 0 || text.getc(0) == "#" || !arc_param_utils::arc_param_starts_with(text, "-ARC_PARAM:")) return;
    body = text.substr(11, text.len() - 1);
    dot = arc_param_utils::arc_param_find_char(body, ".");
    equal = arc_param_utils::arc_param_find_char(body, "=");
    if (dot <= 0 || equal <= dot + 1 || equal == body.len() - 1) begin
      $error("ARC_PARAM bad line %s:%0d: %s", file, line_no, text); error_count++; return;
    end
    item = new();
    item.param_name = arc_param_utils::arc_param_trim(body.substr(0, dot - 1));
    item.path = arc_param_utils::arc_param_trim(body.substr(dot + 1, equal - 1));
    item.value = arc_param_utils::arc_param_trim(body.substr(equal + 1, body.len() - 1));
    item.file = file; item.line_no = line_no;
    if (item.param_name.len() == 0 || item.path.len() == 0) begin
      $error("ARC_PARAM bad line %s:%0d: %s", file, line_no, text); error_count++; return;
    end
    full_path = item_full_path(item);
    previous_index = -1;
    foreach (items[index]) begin
      if (item_full_path(items[index]) == full_path) previous_index = index;
    end
    if (previous_index >= 0 && !m_duplicate_reported.exists(full_path)) begin
      $warning("ARC_PARAM duplicate %s: %s:%0d overridden by %s:%0d",
               full_path, items[previous_index].file, items[previous_index].line_no,
               item.file, item.line_no);
      warning_count++;
      m_duplicate_reported[full_path] = 1;
    end
    items.push_back(item); total_count++;
  endfunction

  function void parse_file(string file);
    int fd; int line_no = 0; string line;
    fd = $fopen(file, "r");
    if (fd == 0) begin $error("ARC_PARAM cannot open %s", file); error_count++; return; end
    while ($fgets(line, fd)) begin line_no++; parse_line(line, file, line_no); end
    $fclose(fd);
  endfunction

  function void load_tc_param(arc_param_config config);
    string config_path;
    string full_path;
    string relative_path;
    arc_param_apply_result_e result;

    if (config == null) begin
      report_error("load_tc_param received null config");
      return;
    end
    config_path = config.get_param_path();
    if (config_path.len() == 0) return;

    foreach (items[index]) begin
      full_path = item_full_path(items[index]);
      if (!arc_param_utils::arc_param_starts_with(full_path, {config_path, "."})) continue;
      relative_path = full_path.substr(config_path.len() + 1, full_path.len() - 1);
      items[index].matched = 1;
      result = config.apply_arc_param(relative_path, items[index].value);
      case (result)
        ARC_PARAM_APPLIED: begin
          if (items[index].unknown_reported) begin
            items[index].unknown_reported = 0;
            unknown_count--;
            if (strict_unknown) error_count--; else warning_count--;
          end
          if (items[index].invalid_reported) begin
            items[index].invalid_reported = 0;
            error_count--;
          end
          if (!items[index].used) begin items[index].used = 1; used_count++; end
        end
        ARC_PARAM_NOT_MATCHED: begin
          if (!items[index].used && !items[index].invalid_reported && !items[index].unknown_reported) begin
            if (strict_unknown) begin
              $error("ARC_PARAM unknown field %s at %s:%0d", full_path, items[index].file, items[index].line_no);
              error_count++;
            end else begin
              $warning("ARC_PARAM unknown field %s at %s:%0d", full_path, items[index].file, items[index].line_no);
              warning_count++;
            end
            items[index].unknown_reported = 1;
            unknown_count++;
          end
        end
        ARC_PARAM_INVALID_VALUE: begin
          if (!items[index].used && !items[index].unknown_reported && !items[index].invalid_reported) begin
            $error("ARC_PARAM invalid value '%s' for %s at %s:%0d",
                   items[index].value, full_path, items[index].file, items[index].line_no);
            items[index].invalid_reported = 1;
            error_count++;
          end
        end
      endcase
    end
  endfunction

  function void check_unused();
    foreach (items[index]) begin
      if (items[index].matched || items[index].unused_reported) continue;
      if (strict_unused) begin
        $error("ARC_PARAM unused %s at %s:%0d", item_full_path(items[index]), items[index].file, items[index].line_no);
        error_count++;
      end else begin
        $warning("ARC_PARAM unused %s at %s:%0d", item_full_path(items[index]), items[index].file, items[index].line_no);
        warning_count++;
      end
      items[index].unused_reported = 1;
      unused_count++;
    end
  endfunction

  function void summary();
    $display("ARC_PARAM summary: total=%0d used=%0d unused=%0d unknown=%0d warnings=%0d errors=%0d", total_count, used_count, unused_count, unknown_count, warning_count, error_count);
  endfunction

  function void report_error(string message);
    $error("ARC_PARAM %s", message);
    error_count++;
  endfunction
endclass
