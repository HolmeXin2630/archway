module test_arc_param_array_assign;
  import arc_param_pkg::*;

  initial begin
    int int_queue[$] = '{99};
    real real_queue[$];
    string string_queue[$];
    int int_array[];
    real real_array[];
    string string_array[];
    arc_param_utils::arc_param_assign_queue_int(int_queue, "{1,2,3}");
    arc_param_utils::arc_param_assign_queue_real(real_queue, "{0.5,1.25}");
    arc_param_utils::arc_param_assign_queue_string(string_queue, "{\"a,b\",c}");
    arc_param_utils::arc_param_assign_array_int(int_array, "{4,5}");
    arc_param_utils::arc_param_assign_array_real(real_array, "{2.5,3.75}");
    arc_param_utils::arc_param_assign_array_string(string_array, "{one,\"two,three\"}");
    if (int_queue.size() != 3 || int_queue[0] != 1 || int_queue[2] != 3) $fatal(1, "int queue assignment failed");
    if (real_queue.size() != 2 || real_queue[1] != 1.25) $fatal(1, "real queue assignment failed");
    if (string_queue.size() != 2 || string_queue[0] != "a,b") $fatal(1, "string queue assignment failed");
    if (int_array.size() != 2 || int_array[1] != 5) $fatal(1, "int array assignment failed");
    if (real_array.size() != 2 || real_array[0] != 2.5) $fatal(1, "real array assignment failed");
    if (string_array.size() != 2 || string_array[1] != "two,three") $fatal(1, "string array assignment failed");
    $display("test_arc_param_array_assign PASS");
    $finish;
  end
endmodule

