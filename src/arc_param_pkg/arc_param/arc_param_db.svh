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
  endfunction

  function void set_strict(bit strict_unknown_en = 1, bit strict_unused_en = 1);
    strict_unknown = strict_unknown_en;
    strict_unused = strict_unused_en;
  endfunction

  function void parse_line(string line, string file = "", int line_no = 0);
    string text; string body; int dot; int equal; arc_param_item item;
    text = arc_param_utils::arc_param_trim(line);
    if (text.len() == 0 || text.getc(0) == "#" || !arc_param_utils::arc_param_starts_with(text, "-ARC_PARAM:")) return;
    body = text.substr(11, text.len() - 1);
    dot = arc_param_utils::arc_param_find_char(body, ".");
    equal = arc_param_utils::arc_param_find_char(body, "=");
    if (dot <= 0 || equal <= dot + 1 || equal == body.len() - 1) begin
      $error("ARC_PARAM bad line %s:%0d: %s", file, line_no, text); error_count++; return;
    end
    item = new();
    item.obj_name = arc_param_utils::arc_param_trim(body.substr(0, dot - 1));
    item.path = arc_param_utils::arc_param_trim(body.substr(dot + 1, equal - 1));
    item.value = arc_param_utils::arc_param_trim(body.substr(equal + 1, body.len() - 1));
    item.file = file; item.line_no = line_no;
    if (item.obj_name.len() == 0 || item.path.len() == 0) begin
      $error("ARC_PARAM bad line %s:%0d: %s", file, line_no, text); error_count++; return;
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

  function void load(arc_param_object obj);
    foreach (items[index]) begin
      if (items[index].obj_name != obj.get_name()) continue;
      if (obj.apply_arc_param(items[index].path, items[index].value)) begin
        items[index].matched = 1;
        if (!items[index].used) begin items[index].used = 1; used_count++; end
      end else begin
        items[index].matched = 0;
        if (!items[index].unknown_reported) begin
          $warning("ARC_PARAM unknown field %s.%s at %s:%0d", items[index].obj_name, items[index].path, items[index].file, items[index].line_no);
          items[index].unknown_reported = 1; unknown_count++; warning_count++;
          if (strict_unknown) error_count++;
        end
      end
    end
  endfunction

  function void check_unused();
    foreach (items[index]) begin
      if (items[index].used || items[index].unused_reported) continue;
      $warning("ARC_PARAM unused %s.%s at %s:%0d", items[index].obj_name, items[index].path, items[index].file, items[index].line_no);
      items[index].unused_reported = 1;
      unused_count++;
      warning_count++;
      if (strict_unused) error_count++;
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
