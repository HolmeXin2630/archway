module test_arc_param_tokenizer_unit;
  import arc_param_pkg::*;

  initial begin
    string items[$];
    if (arc_param_utils::arc_param_strip_outer_braces("{1,2,3}") != "1,2,3") $fatal(1, "outer brace stripping failed");
    arc_param_utils::arc_param_parse_list_items("{1,2,3}", items);
    if (items.size() != 3 || items[1] != "2") $fatal(1, "simple split failed");
    arc_param_utils::arc_param_parse_list_items("{\"a,b\",c}", items);
    if (items.size() != 2 || items[0] != "\"a,b\"") $fatal(1, "quoted comma split failed");
    arc_param_utils::arc_param_parse_list_items("{{1,2},3}", items);
    if (items.size() != 2 || items[0] != "{1,2}") $fatal(1, "nested brace split failed");
    arc_param_utils::arc_param_parse_list_items("{}", items);
    if (items.size() != 0) $fatal(1, "empty list failed");
    $display("test_arc_param_tokenizer_unit PASS");
    $finish;
  end
endmodule
