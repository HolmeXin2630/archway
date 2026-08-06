// =============================================================================
// Test: CRG high-precision waveform behavior
// =============================================================================

module test_crg_pkg_high_precision;

  timeunit 1ps;
  timeprecision 1fs;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import crg_pkg::*;

  arc_clk_if u_clk_if();

  initial begin
    arc_clk_source source;
    realtime rising_edge;
    realtime falling_edge;
    realtime period;

    source = new("high_precision");
    source.vif         = u_clk_if;
    source.freq        = "3GHz";
    source.start_delay = "100fs";
    assert (source.validate_and_freeze())
      else $fatal(1, "High-precision source configuration was rejected");

    fork
      source.run();
      begin
        @(posedge u_clk_if.clk);
        rising_edge = $realtime;
        @(negedge u_clk_if.clk);
        falling_edge = $realtime;
        @(posedge u_clk_if.clk);
        period = $realtime - rising_edge;

        assert (period > 333.332 && period < 333.335)
          else $fatal(1, "High-precision period was %0.6fps", period);
        assert (falling_edge - rising_edge > 166.665 &&
                falling_edge - rising_edge < 166.668)
          else $fatal(1, "High-precision duty split was not preserved");
        $display("PASS: high-precision CRG timing");
        $finish;
      end
    join
  end

endmodule
