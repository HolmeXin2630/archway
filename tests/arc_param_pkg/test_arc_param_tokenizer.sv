module test_arc_param_tokenizer;
  import arc_param_pkg::*;

  task automatic expect_item(string name, string actual, string expected);
    if (actual != expected) $fatal(1, "%s: expected '%s', got '%s'", name, expected, actual);
  endtask

  initial begin
    string items[$];
    if (arc_param_utils::arc_param_strip_outer_braces("{1,2,3}") != "1,2,3") $fatal(1, "outer brace stripping failed");
    arc_param_utils::arc_param_parse_list_items("{1,2,3}", items);
    if (items.size() != 3) $fatal(1, "simple split item count failed");
    expect_item("simple item", items[1], "2");
    arc_param_utils::arc_param_parse_list_items("{\"a,b\",c}", items);
    if (items.size() != 2) $fatal(1, "quoted comma item count failed");
    expect_item("quoted comma", items[0], "\"a,b\"");
    arc_param_utils::arc_param_parse_list_items("{{1,2},3}", items);
    if (items.size() != 2) $fatal(1, "nested brace item count failed");
    expect_item("nested brace", items[0], "{1,2}");
    arc_param_utils::arc_param_parse_list_items("{}", items);
    if (items.size() != 0) $fatal(1, "empty list failed");
    $display("test_arc_param_tokenizer PASS");
    $finish;
  end
endmodule

