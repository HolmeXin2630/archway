// =============================================================================
// Test: crg_pkg minimal named clock path
// =============================================================================

module test_crg_pkg;

  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import crg_pkg::*;
  import archway_pkg::*;

  arc_clk_if u_core_clk_if();

  class crg_clock_test extends uvm_test;

    `uvm_component_utils(crg_clock_test)

    archway_env m_env0;
    archway_env m_env1;

    function new(string name = "crg_clock_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_env0 = new("env0", this);
      m_env1 = new("env1", this);
    endfunction

    virtual task main_phase(uvm_phase phase);
      arc_clk_source source;
      realtime first_edge;
      realtime second_edge;
      realtime falling_edge;
      realtime expected_period;
      realtime measured_period;
      realtime measured_high_time;
      uvm_component managers[$];

      phase.raise_objection(this);

      assert (ARC_CLKS::has_clk("soc.core_clk"))
        else $fatal(1, "Registered clock was not discoverable");

      source = ARC_CLKS::clk("soc.core_clk");
      assert (source != null)
        else $fatal(1, "Registered clock source was null");

      uvm_root::get().find_all("*.crg_manager", managers);
      assert (managers.size() == 1)
        else $fatal(1,
          "Expected one simulation-wide CRG manager, found %0d",
          managers.size());

      @(posedge source.vif.clk);
      first_edge = $realtime;
      assert (source.vif.free_run_clk === 1'b1)
        else $fatal(1, "Output clock rose without the free-running clock");

      @(negedge source.vif.clk);
      falling_edge = $realtime;

      @(posedge source.vif.clk);
      second_edge = $realtime;

      expected_period   = 1000.0 / 50.5;
      measured_period   = second_edge - first_edge;
      measured_high_time = falling_edge - first_edge;

      assert (measured_period >= expected_period - 0.002 &&
              measured_period <= expected_period + 0.002)
        else $fatal(1,
          "Expected period %.6fns, measured %.6fns",
          expected_period, measured_period);

      assert (measured_high_time >= expected_period / 2.0 - 0.002 &&
              measured_high_time <= expected_period / 2.0 + 0.002)
        else $fatal(1,
          "Expected high time %.6fns, measured %.6fns",
          expected_period / 2.0, measured_high_time);

      $display("PASS: named clock registered and ran at 50.5MHz");
      phase.drop_objection(this);
    endtask

  endclass

  initial begin
    ARC_CLKS::add_new_clk("soc.core_clk", u_core_clk_if, "50.5M");
    run_test("crg_clock_test");
  end

endmodule
