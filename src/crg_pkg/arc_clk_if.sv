// =============================================================================
// CRG Package - Clock Interface
// =============================================================================

interface arc_clk_if;

  logic free_run_clk = 1'b0;
  logic sw_clk_en    = 1'b1;
  wand  clk_en;
  logic clk          = 1'b0;

  assign clk_en = sw_clk_en;

  // Sample enable only when the free-running clock changes so that gate
  // updates cannot create a partial output pulse.
  always @(free_run_clk) begin
    if (clk_en)
      clk <= free_run_clk;
    else
      clk <= 1'b0;
  end

endinterface
