`ifndef ARC_CLKS_FACADE_SVH
`define ARC_CLKS_FACADE_SVH

class ARC_CLKS;

  protected static arc_clk_source m_clks[string];
  protected static bit m_locked;
  protected static bit m_run_started;

  static function void add_new_clk(
    input string name,
    input virtual arc_clk_if vif,
    input string freq
  );
    arc_clk_source source;

    if (m_locked) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' cannot be registered after runtime start", name))
      return;
    end
    if (m_clks.exists(name)) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' is already registered", name))
      return;
    end

    source      = new(name);
    source.vif  = vif;
    source.freq = freq;

    add_clk_source(name, source);
  endfunction

  static function void add_clk_source(
    input string name,
    input arc_clk_source source
  );
    if (m_locked) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' cannot be registered after runtime start", name))
      return;
    end
    if (m_clks.exists(name)) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' is already registered", name))
      return;
    end

    if (source == null) begin
      `uvm_error("ARC_CLKS_REGISTER",
        $sformatf("Clock '%s' has a null source", name))
      return;
    end

    if (!source.validate_and_freeze())
      return;

    m_clks[name] = source;
    `uvm_info("ARC_CLKS_REGISTER",
      $sformatf("Clock '%s' registered at %s", name, source.freq), UVM_MEDIUM)
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

  static function void get_clk_names(output string names[$]);
    string name;
    int status;

    names.delete();
    status = m_clks.first(name);
    if (status != 0) begin
      do begin
        names.push_back(name);
        status = m_clks.next(name);
      end while (status != 0);
    end
  endfunction

  static function void enable_clk(string name);
    clk(name).enable_clk();
  endfunction

  static task disable_clk(string name);
    clk(name).disable_clk();
  endtask

  static task change_freq(string name, string freq);
    clk(name).change_freq(freq);
  endtask

  static task change_duty_cycle(string name, real duty_cycle_pct);
    clk(name).change_duty_cycle(duty_cycle_pct);
  endtask

  static task change_jitter(string name, real cycle_jitter_ppm);
    clk(name).change_jitter(cycle_jitter_ppm);
  endtask

  static task run_all();
    string name;
    int status;

    if (m_run_started) begin
      `uvm_error("ARC_CLKS_RUN", "Clock registry was already started")
      return;
    end
    m_locked      = 1;
    m_run_started = 1;

    status = m_clks.first(name);
    if (status != 0) begin
      do begin
        automatic arc_clk_source source = m_clks[name];
        fork
          source.run();
        join_none
        status = m_clks.next(name);
      end while (status != 0);
    end

    wait fork;
  endtask

endclass

`endif // ARC_CLKS_FACADE_SVH
