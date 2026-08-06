`ifndef ARC_RSTS_FACADE_SVH
`define ARC_RSTS_FACADE_SVH

class ARC_RSTS;

  protected static arc_rst_source m_rsts[string];
  protected static bit m_locked;
  protected static bit m_run_started;

  static function void add_new_rst(
    input string name,
    input virtual arc_rst_if vif,
    input string deassert_delay
  );
    arc_rst_source source;

    if (m_locked) begin
      `uvm_error("ARC_RSTS_REGISTER",
        $sformatf("Reset '%s' cannot be registered after runtime start", name))
      return;
    end
    source                 = new(name);
    source.vif             = vif;
    source.deassert_delay  = deassert_delay;
    add_rst_source(name, source);
  endfunction

  static function void add_rst_source(
    input string name,
    input arc_rst_source source
  );
    if (m_locked) begin
      `uvm_error("ARC_RSTS_REGISTER",
        $sformatf("Reset '%s' cannot be registered after runtime start", name))
      return;
    end
    if (m_rsts.exists(name)) begin
      `uvm_error("ARC_RSTS_REGISTER",
        $sformatf("Reset '%s' is already registered", name))
      return;
    end
    if (source == null) begin
      `uvm_error("ARC_RSTS_REGISTER",
        $sformatf("Reset '%s' has a null source", name))
      return;
    end
    if (!source.validate_and_freeze())
      return;

    m_rsts[name] = source;
    `uvm_info("ARC_RSTS_REGISTER",
      $sformatf("Reset '%s' registered with deassert delay %s",
        name, source.deassert_delay), UVM_MEDIUM)
  endfunction

  static function bit has_rst(string name);
    return m_rsts.exists(name);
  endfunction

  static function arc_rst_source rst(string name);
    if (!m_rsts.exists(name)) begin
      `uvm_fatal("ARC_RSTS_GET",
        $sformatf("Reset '%s' is not registered", name))
      return null;
    end
    return m_rsts[name];
  endfunction

  static function void get_rst_names(output string names[$]);
    string name;
    int status;

    names.delete();
    status = m_rsts.first(name);
    if (status != 0) begin
      do begin
        names.push_back(name);
        status = m_rsts.next(name);
      end while (status != 0);
    end
  endfunction

  static task assert_rst(string name);
    rst(name).assert_rst();
  endtask

  static task deassert_rst(string name);
    rst(name).deassert_rst();
  endtask

  static task wait_all_deasserted();
    string name;
    int status;

    status = m_rsts.first(name);
    if (status != 0) begin
      do begin
        m_rsts[name].wait_until_deasserted();
        status = m_rsts.next(name);
      end while (status != 0);
    end
  endtask

  static task run_all();
    string name;
    int status;

    if (m_run_started) begin
      `uvm_error("ARC_RSTS_RUN", "Reset registry was already started")
      return;
    end
    m_locked      = 1;
    m_run_started = 1;

    status = m_rsts.first(name);
    if (status != 0) begin
      do begin
        automatic arc_rst_source source = m_rsts[name];
        fork
          source.run();
        join_none
        status = m_rsts.next(name);
      end while (status != 0);
    end

    wait fork;
  endtask

endclass

`endif // ARC_RSTS_FACADE_SVH
