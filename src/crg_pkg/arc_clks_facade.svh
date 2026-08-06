`ifndef ARC_CLKS_FACADE_SVH
`define ARC_CLKS_FACADE_SVH

class ARC_CLKS;

  protected static arc_clk_source m_clks[string];

  static function void add_new_clk(
    input string name,
    input virtual arc_clk_if vif,
    input string freq
  );
    arc_clk_source source;

    if (m_clks.exists(name)) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' is already registered", name))
      return;
    end

    source      = new(name);
    source.vif  = vif;
    source.freq = freq;

    if (!source.validate_and_freeze())
      return;

    m_clks[name] = source;
    `uvm_info("ARC_CLKS_REGISTER",
      $sformatf("Clock '%s' registered at %s", name, freq), UVM_MEDIUM)
  endfunction

  static function bit has_clk(string name);
    return m_clks.exists(name);
  endfunction

  static function arc_clk_source clk(string name);
    if (!m_clks.exists(name)) begin
      `uvm_fatal("ARC_CLKS_GET",
        $sformatf("Clock '%s' is not registered", name))
      return null;
    end
    return m_clks[name];
  endfunction

  static task run_all();
    string name;

    if (m_clks.first(name)) begin
      do begin
        automatic arc_clk_source source = m_clks[name];
        fork
          source.run();
        join_none
      end while (m_clks.next(name));
    end

    wait fork;
  endtask

endclass

`endif // ARC_CLKS_FACADE_SVH
