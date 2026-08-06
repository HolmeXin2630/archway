// =============================================================================
// Test: CRG reset readiness semantics
// =============================================================================

module test_crg_pkg_reset_readiness;

  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import crg_pkg::*;

  arc_rst_if u_delayed_rst_if();
  arc_rst_if u_manual_rst_if();

  initial begin
    arc_rst_source delayed_source;
    arc_rst_source manual_source;
    realtime ready_time;

    delayed_source = new("delayed");
    delayed_source.vif              = u_delayed_rst_if;
    delayed_source.active_high      = 1'b1;
    delayed_source.initial_asserted = 1'b0;
    delayed_source.assert_delay     = "20ns";
    delayed_source.deassert_delay   = "70ns";
    ARC_RSTS::add_rst_source("delayed", delayed_source);

    manual_source = new("manual");
    manual_source.vif            = u_manual_rst_if;
    manual_source.deassert_delay = "100ns";
    ARC_RSTS::add_rst_source("manual", manual_source);

    fork
      ARC_RSTS::run_all();
    join_none

    // The API must synchronize with the manager's concurrent runtime start.
    ARC_RSTS::deassert_rst("manual");
    assert (u_manual_rst_if.rst === 1'b1)
      else $fatal(1, "Immediate manual reset control did not wait for startup");

    ARC_RSTS::wait_all_deasserted();
    ready_time = $realtime;
    assert (ready_time >= 70.0)
      else $fatal(1,
        "Delayed initially-inactive reset reported ready at %0.6fns", ready_time);
    assert (u_delayed_rst_if.rst === 1'b0)
      else $fatal(1, "Delayed active-high reset was not deasserted");

    $display("PASS: reset readiness and zero-delay manual control");
    $finish;
  end

endmodule
