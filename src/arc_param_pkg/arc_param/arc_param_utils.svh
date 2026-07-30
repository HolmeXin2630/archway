class arc_param_utils;
static function automatic string arc_param_trim(string value);
  int first = 0;
  int last = value.len() - 1;
  while (first <= last && (value.getc(first) == " " || value.getc(first) == 8'h09 || value.getc(first) == 8'h0a || value.getc(first) == 8'h0d)) first++;
  while (last >= first && (value.getc(last) == " " || value.getc(last) == 8'h09 || value.getc(last) == 8'h0a || value.getc(last) == 8'h0d)) last--;
  return first > last ? "" : value.substr(first, last);
endfunction

static function automatic string arc_param_unquote(string value);
  string text = arc_param_trim(value);
  return (text.len() >= 2 && text.getc(0) == "\"" && text.getc(text.len() - 1) == "\"") ?
         text.substr(1, text.len() - 2) : text;
endfunction

static function automatic string arc_param_lower(string value);
  string result = "";
  byte ch;
  for (int index = 0; index < value.len(); index++) begin
    ch = value.getc(index);
    if (ch >= "A" && ch <= "Z") ch = ch + 8'd32;
    result = {result, ch};
  end
  return result;
endfunction

static function automatic string arc_param_strip_underscores(string value);
  string result = "";
  for (int index = 0; index < value.len(); index++) if (value.getc(index) != "_") result = {result, value.getc(index)};
  return result;
endfunction

static function automatic int arc_param_find_char(string value, byte needle);
  for (int index = 0; index < value.len(); index++) if (value.getc(index) == needle) return index;
  return -1;
endfunction

static function automatic bit arc_param_starts_with(string value, string prefix);
  return value.len() >= prefix.len() && value.substr(0, prefix.len() - 1) == prefix;
endfunction
typedef longint unsigned arc_param_u64_t;

static function automatic bit arc_param_char_is_base_digit(byte ch, int base);
  int digit = arc_param_base_digit_value(ch);
  return digit >= 0 && digit < base;
endfunction

static function automatic int arc_param_base_digit_value(byte ch);
  case (ch)
    "0": return 0; "1": return 1; "2": return 2; "3": return 3; "4": return 4;
    "5": return 5; "6": return 6; "7": return 7; "8": return 8; "9": return 9;
    "a", "A": return 10; "b", "B": return 11; "c", "C": return 12;
    "d", "D": return 13; "e", "E": return 14; "f", "F": return 15;
    default: return -1;
  endcase
endfunction

static function automatic longint unsigned arc_param_parse_based_digits(string digits, int base);
  longint unsigned result = 0;
  int digit;
  if (digits.len() == 0) return 64'hffff_ffff_ffff_ffff;
  for (int index = 0; index < digits.len(); index++) begin
    digit = arc_param_base_digit_value(digits.getc(index));
    if (digit < 0 || digit >= base) return 64'hffff_ffff_ffff_ffff;
    result = result * arc_param_u64_t'(base) + arc_param_u64_t'(digit);
  end
  return result;
endfunction

static function automatic longint unsigned arc_param_to_longint_unsigned(string value);
  string text = arc_param_lower(arc_param_strip_underscores(arc_param_trim(value)));
  int base = 10;
  int start = 0;
  int quote = -1;
  if (text.len() == 0 || text.getc(0) == "-" || text.getc(0) == "+") return 64'hffff_ffff_ffff_ffff;
  if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "x") begin base = 16; start = 2; end
  else if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "b") begin base = 2; start = 2; end
  else if (text.len() >= 3 && text.getc(0) == "0" && text.getc(1) == "o") begin base = 8; start = 2; end
  else begin
    for (int index = 0; index < text.len(); index++) begin
      if (text.getc(index) == "'") quote = index;
    end
    if (quote >= 0) begin
      start = quote + 1;
      if (start >= text.len()) return 64'hffff_ffff_ffff_ffff;
      case (text.getc(start))
        "b": base = 2; "o": base = 8; "d": base = 10; "h": base = 16;
        default: return 64'hffff_ffff_ffff_ffff;
      endcase
      start++;
    end
  end
  return start >= text.len() ? 64'hffff_ffff_ffff_ffff : arc_param_parse_based_digits(text.substr(start, text.len() - 1), base);
endfunction

static function automatic longint arc_param_to_longint(string value);
  string text = arc_param_trim(value);
  bit negative = text.len() > 0 && text.getc(0) == "-";
  longint unsigned parsed;
  if (negative || (text.len() > 0 && text.getc(0) == "+")) text = text.substr(1, text.len() - 1);
  parsed = arc_param_to_longint_unsigned(text);
  return parsed == 64'hffff_ffff_ffff_ffff ? -1 : (negative ? -longint'(parsed) : longint'(parsed));
endfunction

static function automatic int arc_param_to_int(string value);
  return int'(arc_param_to_longint(value));
endfunction

static function automatic real arc_param_to_real(string value);
  string text = arc_param_strip_underscores(arc_param_trim(value));
  real result = 0.0;
  real scale = 0.1;
  bit negative = text.len() > 0 && text.getc(0) == "-";
  bit fraction = 0;
  int digit;
  if (negative || (text.len() > 0 && text.getc(0) == "+")) text = text.substr(1, text.len() - 1);
  for (int index = 0; index < text.len(); index++) begin
    if (text.getc(index) == ".") begin if (fraction) return 0.0; fraction = 1; end
    else begin
      digit = arc_param_base_digit_value(text.getc(index));
      if (digit < 0 || digit > 9) return 0.0;
      if (fraction) begin result += digit * scale; scale *= 0.1; end else result = result * 10.0 + digit;
    end
  end
  return negative ? -result : result;
endfunction
static function automatic int arc_param_find_top_level_char(string value, byte needle);
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

static function automatic void arc_param_split_top_level(string value, byte delimiter, ref string items[$]);
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

static function automatic string arc_param_strip_outer_braces(string value);
  string text = arc_param_trim(value);
  if (text.len() >= 2 && text.getc(0) == "{" && text.getc(text.len() - 1) == "}")
    return text.substr(1, text.len() - 2);
  return text;
endfunction

static function automatic void arc_param_parse_list_items(string value, ref string items[$]);
  string contents = arc_param_trim(arc_param_strip_outer_braces(value));
  items.delete();
  if (contents.len() != 0) arc_param_split_top_level(contents, ",", items);
endfunction

static function automatic void arc_param_assign_queue_int(ref int target[$], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target.delete();
  foreach (items[index]) target.push_back(arc_param_to_int(items[index]));
endfunction

static function automatic void arc_param_assign_queue_real(ref real target[$], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target.delete();
  foreach (items[index]) target.push_back(arc_param_to_real(items[index]));
endfunction

static function automatic void arc_param_assign_queue_string(ref string target[$], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target.delete();
  foreach (items[index]) target.push_back(arc_param_unquote(items[index]));
endfunction

static function automatic void arc_param_assign_array_int(ref int target[], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target = new[items.size()];
  foreach (items[index]) target[index] = arc_param_to_int(items[index]);
endfunction

static function automatic void arc_param_assign_array_real(ref real target[], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target = new[items.size()];
  foreach (items[index]) target[index] = arc_param_to_real(items[index]);
endfunction

static function automatic void arc_param_assign_array_string(ref string target[], input string value);
  string items[$];
  arc_param_parse_list_items(value, items);
  target = new[items.size()];
  foreach (items[index]) target[index] = arc_param_unquote(items[index]);
endfunction
static function automatic bit arc_param_match_index(string path, string name, ref int index);
  int left; int right; string index_text;
  if (!arc_param_starts_with(path, {name, "["})) return 0;
  left = name.len();
  right = arc_param_find_char(path.substr(left, path.len() - 1), "]");
  if (right < 1 || left + right != path.len() - 1) return 0;
  index_text = path.substr(left + 1, left + right - 1);
  index = arc_param_to_int(index_text);
  return 1;
endfunction

static function automatic bit arc_param_match_index_tail(string path, string name, ref int index, ref string tail);
  int left; int right; string index_text;
  tail = "";
  if (!arc_param_starts_with(path, {name, "["})) return 0;
  left = name.len();
  right = arc_param_find_char(path.substr(left, path.len() - 1), "]");
  if (right < 1) return 0;
  index_text = path.substr(left + 1, left + right - 1);
  index = arc_param_to_int(index_text);
  if (left + right + 1 < path.len()) begin
    if (path.getc(left + right + 1) != ".") return 0;
    tail = path.substr(left + right + 2, path.len() - 1);
  end
  return 1;
endfunction

static function automatic bit arc_param_match_string_key(string path, string name, ref string key);
  int left; int right;
  if (!arc_param_starts_with(path, {name, "[\""})) return 0;
  left = name.len() + 2;
  right = arc_param_find_char(path.substr(left, path.len() - 1), "\"");
  if (right < 0 || left + right + 1 != path.len() - 1 || path.getc(path.len() - 1) != "]") return 0;
  key = path.substr(left, left + right - 1);
  return 1;
endfunction

endclass
