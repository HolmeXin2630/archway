// =============================================================================
// Clock and Reset Generation Package
// =============================================================================

package crg_pkg;

`ifdef ARC_CRG_HIGH_PRECISION
  timeunit 1ps;
  timeprecision 1fs;
`else
  timeunit 1ns;
  timeprecision 1ps;
`endif

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "arc_crg_time_utils.svh"
  `include "arc_clk_source.svh"
  `include "arc_clks_facade.svh"
  `include "arc_crg_manager.svh"

endpackage
