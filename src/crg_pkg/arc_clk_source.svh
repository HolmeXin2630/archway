`ifndef ARC_CLK_SOURCE_SVH
`define ARC_CLK_SOURCE_SVH

class arc_clk_source extends uvm_object;

  `uvm_object_utils(arc_clk_source)

  virtual arc_clk_if vif;
  string freq;

  protected realtime m_period;
  protected bit m_frozen;

  function new(string name = "");
    super.new(name);
    freq = "100MHz";
  endfunction

  function bit validate_and_freeze();
    if (vif == null) begin
      `uvm_error("ARC_CLK_CONFIG",
        $sformatf("Clock '%s' has no virtual interface", get_name()))
      return 0;
    end

    if (!arc_crg_time_utils::try_frequency_to_period(freq, m_period)) begin
      `uvm_error("ARC_CLK_CONFIG",
        $sformatf("Clock '%s' has invalid frequency '%s'", get_name(), freq))
      return 0;
    end

    m_frozen = 1;
    return 1;
  endfunction

  task run();
    if (!m_frozen) begin
      `uvm_fatal("ARC_CLK_RUN",
        $sformatf("Clock '%s' was not validated before run", get_name()))
      return;
    end

    vif.free_run_clk = 1'b0;
    vif.clk          = 1'b0;

    forever begin
      #(m_period / 2.0);
      vif.free_run_clk <= ~vif.free_run_clk;
      vif.clk          <= ~vif.clk;
    end
  endtask

endclass

`endif // ARC_CLK_SOURCE_SVH
