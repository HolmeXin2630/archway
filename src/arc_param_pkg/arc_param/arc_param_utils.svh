class arc_param_utils;
  typedef longint unsigned arc_param_u64_t;

  static function string arc_param_trim(string value);
    int first = 0;
    int last = value.len() - 1;
    while (first <= last && (value.getc(first) == " " || value.getc(first) == 8'h09 || value.getc(first) == 8'h0a || value.getc(first) == 8'h0d)) first++;
    while (last >= first && (value.getc(last) == " " || value.getc(last) == 8'h09 || value.getc(last) == 8'h0a || value.getc(last) == 8'h0d)) last--;
    return first > last ? "" : value.substr(first, last);
  endfunction

  static function string arc_param_unquote(string value);
    string text = arc_param_trim(value);
    return (text.len() >= 2 && text.getc(0) == "\"") && text.getc(text.len() - 1) == "\"" ? text.substr(1, text.len() - 2) : text;
  endfunction

  static function string arc_param_lower(string value);
    string result = "";
    byte ch;
    for (int index = 0; index < value.len(); index++) begin
      ch = value.getc(index);
      if (ch >= "A" && ch <= "Z") ch += 8'd32;
      result = {result, ch};
    end
    return result;
  endfunction

  static function string arc_param_strip_underscores(string value);
    string result = "";
    for (int index = 0; index < value.len(); index++) if (value.getc(index) != "_") result = {result, value.getc(index)};
    return result;
  endfunction

  static function int arc_param_find_char(string value, byte needle);
    for (int index = 0; index < value.len(); index++) if (value.getc(index) == needle) return index;
    return -1;
  endfunction

  static function bit arc_param_starts_with(string value, string prefix);
    return value.len() >= prefix.len() && value.substr(0, prefix.len() - 1) == prefix;
  endfunction

  static function int arc_param_base_digit_value(byte ch);
    case (ch)
      "0": return 0; "1": return 1; "2": return 2; "3": return 3; "4": return 4;
      "5": return 5; "6": return 6; "7": return 7; "8": return 8; "9": return 9;
      "a", "A": return 10; "b", "B": return 11; "c", "C": return 12;
      "d", "D": return 13; "e", "E": return 14; "f", "F": return 15;
      default: return -1;
    endcase
  endfunction

  static function bit arc_param_char_is_base_digit(byte ch, int base);
    int digit = arc_param_base_digit_value(ch);
    return digit >= 0 && digit < base;
  endfunction

  static function bit arc_param_try_parse_based_digits(string digits, int base, output longint unsigned parsed);
    int digit;
    parsed = 0;
    if (digits.len() == 0) return 0;
    for (int index = 0; index < digits.len(); index++) begin
      digit = arc_param_base_digit_value(digits.getc(index));
      if (digit < 0 || digit >= base) return 0;
      parsed = parsed * arc_param_u64_t'(base) + arc_param_u64_t'(digit);
    end
    return 1;
  endfunction

  static function longint unsigned arc_param_parse_based_digits(string digits, int base);
    longint unsigned parsed;
    return arc_param_try_parse_based_digits(digits, base, parsed) ? parsed : 64'hffff_ffff_ffff_ffff;
  endfunction

  static function bit arc_param_try_to_longint_unsigned(string value, output longint unsigned parsed);
    string text;
    int base = 10;
    int start = 0;
    int quote = -1;

    parsed = 0;
    text = arc_param_lower(arc_param_strip_underscores(arc_param_trim(value)));
    if (text.len() == 0 || text.getc(0) == "-" || text.getc(0) == "+") return 0;
    if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "x") begin
      base = 16;
      start = 2;
    end else if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "b") begin
      base = 2;
      start = 2;
    end else if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "o") begin
      base = 8;
      start = 2;
    end else begin
      quote = arc_param_find_char(text, "'");
      if (quote >= 0) begin
        for (int index = 0; index < quote; index++) if (!arc_param_char_is_base_digit(text.getc(index), 10)) return 0;
        start = quote + 1;
        if (start >= text.len()) return 0;
        case (text.getc(start))
          "b": base = 2; "o": base = 8; "d": base = 10; "h": base = 16;
          default: return 0;
        endcase
        start++;
      end
    end
    if (start >= text.len()) return 0;
    return arc_param_try_parse_based_digits(text.substr(start, text.len() - 1), base, parsed);
  endfunction

  static function longint unsigned arc_param_to_longint_unsigned(string value);
    longint unsigned parsed;
    return arc_param_try_to_longint_unsigned(value, parsed) ? parsed : 64'hffff_ffff_ffff_ffff;
  endfunction

  static function bit arc_param_try_to_longint(string value, output longint parsed);
    string text = arc_param_trim(value);
    longint unsigned unsigned_value;
    bit negative = text.len() > 0 && text.getc(0) == "-";
    parsed = 0;
    if (negative || (text.len() > 0 && text.getc(0) == "+")) begin
      if (text.len() == 1) return 0;
      text = text.substr(1, text.len() - 1);
    end
    if (!arc_param_try_to_longint_unsigned(text, unsigned_value)) return 0;
    parsed = negative ? -longint'(unsigned_value) : longint'(unsigned_value);
    return 1;
  endfunction

  static function longint arc_param_to_longint(string value);
    longint parsed;
    return arc_param_try_to_longint(value, parsed) ? parsed : -1;
  endfunction

  static function bit arc_param_try_to_int(string value, output int parsed);
    longint parsed_longint;
    parsed = 0;
    if (!arc_param_try_to_longint(value, parsed_longint)) return 0;
    parsed = int'(parsed_longint);
    return 1;
  endfunction

  static function int arc_param_to_int(string value);
    int parsed;
    return arc_param_try_to_int(value, parsed) ? parsed : -1;
  endfunction

  static function bit arc_param_try_to_real(string value, output real parsed);
    string text = arc_param_strip_underscores(arc_param_trim(value));
    real scale = 0.1;
    bit negative = text.len() > 0 && text.getc(0) == "-";
    bit fraction = 0;
    bit has_digit = 0;
    int digit;

    parsed = 0.0;
    if (negative || (text.len() > 0 && text.getc(0) == "+")) begin
      if (text.len() == 1) return 0;
      text = text.substr(1, text.len() - 1);
    end
    if (text.len() == 0) return 0;
    for (int index = 0; index < text.len(); index++) begin
      if (text.getc(index) == ".") begin
        if (fraction) return 0;
        fraction = 1;
      end else begin
        digit = arc_param_base_digit_value(text.getc(index));
        if (digit < 0 || digit > 9) return 0;
        has_digit = 1;
        if (fraction) begin
          parsed += digit * scale;
          scale *= 0.1;
        end else begin
          parsed = parsed * 10.0 + digit;
        end
      end
    end
    if (!has_digit) return 0;
    if (negative) parsed = -parsed;
    return 1;
  endfunction

  static function real arc_param_to_real(string value);
    real parsed;
    return arc_param_try_to_real(value, parsed) ? parsed : 0.0;
  endfunction

  static function int arc_param_find_top_level_char(string value, byte needle);
    int depth = 0;
    bit quoted = 0;
    for (int index = 0; index < value.len(); index++) begin
      if (value.getc(index) == "\"") quoted = !quoted;
      else if (!quoted && value.getc(index) == "{") depth++;
      else if (!quoted && value.getc(index) == "}" && depth > 0) depth--;
      else if (!quoted && depth == 0 && value.getc(index) == needle) return index;
    end
    return -1;
  endfunction

  static function void arc_param_split_top_level(string value, byte delimiter, ref string items[$]);
    int depth = 0;
    bit quoted = 0;
    int start = 0;
    items.delete();
    for (int index = 0; index < value.len(); index++) begin
      if (value.getc(index) == "\"") quoted = !quoted;
      else if (!quoted && value.getc(index) == "{") depth++;
      else if (!quoted && value.getc(index) == "}" && depth > 0) depth--;
      else if (!quoted && depth == 0 && value.getc(index) == delimiter) begin
        items.push_back(arc_param_trim(value.substr(start, index - 1)));
        start = index + 1;
      end
    end
    if (start < value.len()) items.push_back(arc_param_trim(value.substr(start, value.len() - 1)));
  endfunction

  static function string arc_param_strip_outer_braces(string value);
    string text = arc_param_trim(value);
    if (text.len() >= 2 && text.getc(0) == "{" && text.getc(text.len() - 1) == "}") return text.substr(1, text.len() - 2);
    return text;
  endfunction

  static function void arc_param_parse_list_items(string value, ref string items[$]);
    string contents = arc_param_trim(arc_param_strip_outer_braces(value));
    items.delete();
    if (contents.len() != 0) arc_param_split_top_level(contents, ",", items);
  endfunction

  static function bit arc_param_assign_queue_int(ref int target[$], input string value);
    string items[$];
    int parsed[$];
    int number;
    arc_param_parse_list_items(value, items);
    foreach (items[index]) begin
      if (!arc_param_try_to_int(items[index], number)) return 0;
      parsed.push_back(number);
    end
    target = parsed;
    return 1;
  endfunction

  static function bit arc_param_assign_queue_real(ref real target[$], input string value);
    string items[$];
    real parsed[$];
    real number;
    arc_param_parse_list_items(value, items);
    foreach (items[index]) begin
      if (!arc_param_try_to_real(items[index], number)) return 0;
      parsed.push_back(number);
    end
    target = parsed;
    return 1;
  endfunction

  static function bit arc_param_assign_queue_string(ref string target[$], input string value);
    string items[$];
    string parsed[$];
    arc_param_parse_list_items(value, items);
    foreach (items[index]) parsed.push_back(arc_param_unquote(items[index]));
    target = parsed;
    return 1;
  endfunction

  static function bit arc_param_assign_array_int(ref int target[], input string value);
    string items[$];
    int parsed[];
    int number;
    arc_param_parse_list_items(value, items);
    parsed = new[items.size()];
    foreach (items[index]) begin
      if (!arc_param_try_to_int(items[index], number)) return 0;
      parsed[index] = number;
    end
    target = parsed;
    return 1;
  endfunction

  static function bit arc_param_assign_array_real(ref real target[], input string value);
    string items[$];
    real parsed[];
    real number;
    arc_param_parse_list_items(value, items);
    parsed = new[items.size()];
    foreach (items[index]) begin
      if (!arc_param_try_to_real(items[index], number)) return 0;
      parsed[index] = number;
    end
    target = parsed;
    return 1;
  endfunction

  static function bit arc_param_assign_array_string(ref string target[], input string value);
    string items[$];
    string parsed[];
    arc_param_parse_list_items(value, items);
    parsed = new[items.size()];
    foreach (items[index]) parsed[index] = arc_param_unquote(items[index]);
    target = parsed;
    return 1;
  endfunction

  static function void arc_param_split_path(string path, ref string head, ref string tail);
    int dot = arc_param_find_char(path, ".");
    if (dot < 0) begin
      head = path;
      tail = "";
    end else begin
      head = path.substr(0, dot - 1);
      tail = dot + 1 < path.len() ? path.substr(dot + 1, path.len() - 1) : "";
    end
  endfunction

  static function bit arc_param_match_index(string path, string name, ref int index);
    int left;
    int right;
    int close;
    string index_text;
    index = -1;
    if (!arc_param_starts_with(path, {name, "["})) return 0;
    left = name.len();
    right = arc_param_find_char(path.substr(left, path.len() - 1), "]");
    if (right < 1) return 0;
    close = left + right;
    if (close != path.len() - 1) return 0;
    index_text = path.substr(left + 1, close - 1);
    void'(arc_param_try_to_int(index_text, index));
    return 1;
  endfunction

  static function bit arc_param_match_index_tail(string path, string name, ref int index, ref string tail);
    int left;
    int right;
    int close;
    string index_text;
    index = -1;
    tail = "";
    if (!arc_param_starts_with(path, {name, "["})) return 0;
    left = name.len();
    right = arc_param_find_char(path.substr(left, path.len() - 1), "]");
    if (right < 1) return 0;
    close = left + right;
    index_text = path.substr(left + 1, close - 1);
    void'(arc_param_try_to_int(index_text, index));
    if (close + 1 < path.len()) begin
      if (path.getc(close + 1) != ".") return 0;
      if (close + 2 < path.len()) tail = path.substr(close + 2, path.len() - 1);
    end
    return 1;
  endfunction

  static function bit arc_param_match_string_key(string path, string name, ref string key);
    int left;
    int quote_offset;
    int quote;
    key = "";
    if (!arc_param_starts_with(path, {name, "[\""})) return 0;
    left = name.len() + 2;
    quote_offset = arc_param_find_char(path.substr(left, path.len() - 1), "\"");
    if (quote_offset < 0) return 0;
    quote = left + quote_offset;
    if (quote != path.len() - 2 || path.getc(path.len() - 1) != "]") return 0;
    if (quote > left) key = path.substr(left, quote - 1);
    return 1;
  endfunction
endclass
