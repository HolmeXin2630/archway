// =============================================================================
// Test: CRG public validation diagnostics
// =============================================================================

module test_crg_pkg_validation;

  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import crg_pkg::*;

  arc_clk_if u_clk_if();
  arc_rst_if u_rst_if();

  class crg_expected_error_catcher extends uvm_report_catcher;

    int unsigned matched_error_count;

    virtual function action_e catch();
      case (get_id())
        "ARC_CLK_CONFIG", "ARC_RST_CONFIG": begin
          matched_error_count++;
          return CAUGHT;
        end
        default: return THROW;
      endcase
    endfunction

  endclass

  class test_crg_pkg_validation extends uvm_test;

    `uvm_component_utils(test_crg_pkg_validation)

    function new(string name = "test_crg_pkg_validation", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      arc_clk_source bad_clock;
      arc_rst_source missing_assert_event;
      arc_rst_source inverted_reset_schedule;
      crg_expected_error_catcher catcher;

      phase.raise_objection(this);
      catcher = new;
      uvm_report_cb::add(null, catcher);

      bad_clock = new("bad_clock");
      bad_clock.vif            = u_clk_if;
      bad_clock.duty_cycle_pct = 0.0;
      assert (!bad_clock.validate_and_freeze())
        else $fatal(1, "Invalid duty cycle was accepted");

      missing_assert_event = new("missing_assert_event");
      missing_assert_event.vif               = u_rst_if;
      missing_assert_event.initial_asserted  = 1'b0;
      missing_assert_event.deassert_delay    = "50ns";
      assert (!missing_assert_event.validate_and_freeze())
        else $fatal(1, "Inactive reset without assert delay was accepted");

      inverted_reset_schedule = new("inverted_reset_schedule");
      inverted_reset_schedule.vif               = u_rst_if;
      inverted_reset_schedule.initial_asserted  = 1'b0;
      inverted_reset_schedule.assert_delay      = "50ns";
      inverted_reset_schedule.deassert_delay    = "50ns";
      assert (!inverted_reset_schedule.validate_and_freeze())
        else $fatal(1, "Non-increasing reset schedule was accepted");

      uvm_report_cb::delete(null, catcher);
      assert (catcher.matched_error_count == 3)
        else $fatal(1, "Expected three CRG validation diagnostics, saw %0d",
          catcher.matched_error_count);

      $display("PASS: invalid CRG timing configurations rejected");
      phase.drop_objection(this);
    endtask

  endclass

  initial run_test("test_crg_pkg_validation");

endmodule
