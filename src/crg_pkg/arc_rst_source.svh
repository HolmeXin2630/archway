`ifndef ARC_RST_SOURCE_SVH
`define ARC_RST_SOURCE_SVH

class arc_rst_source extends uvm_object;

  `uvm_object_utils(arc_rst_source)

  virtual arc_rst_if vif;
  bit active_high;
  bit initial_asserted;
  string assert_delay;
  string deassert_delay;

  protected realtime m_assert_delay;
  protected realtime m_deassert_delay;
  protected bit m_frozen;
  protected bit m_started;
  protected bit m_run_started;
  protected bit m_deasserted;
  protected bit m_schedule_complete;
  protected bit m_manual_control;
  protected event m_state_changed;

  function new(string name = "");
    super.new(name);
    active_high      = 1'b0;
    initial_asserted = 1'b1;
    assert_delay     = "";
    deassert_delay   = "";
  endfunction

  protected function bit asserted_level();
    return active_high;
  endfunction

  protected function bit deasserted_level();
    return !active_high;
  endfunction

  protected function void drive_asserted();
    vif.rst       = asserted_level();
    m_deasserted  = 0;
    ->m_state_changed;
  endfunction

  protected function void drive_deasserted();
    vif.rst       = deasserted_level();
    m_deasserted  = 1;
    ->m_state_changed;
  endfunction

  protected function void complete_startup_schedule();
    m_schedule_complete = 1;
    ->m_state_changed;
  endfunction

  function bit validate_and_freeze();
    if (m_frozen) begin
      `uvm_error("ARC_RST_CONFIG",
        $sformatf("Reset '%s' startup configuration is already frozen", get_name()))
      return 0;
    end

    if (vif == null) begin
      `uvm_error("ARC_RST_CONFIG",
        $sformatf("Reset '%s' has no virtual interface", get_name()))
      return 0;
    end

    if (!arc_crg_time_utils::try_time_to_delay(deassert_delay, m_deassert_delay)) begin
      `uvm_error("ARC_RST_CONFIG",
        $sformatf("Reset '%s' has invalid deassert delay '%s'",
          get_name(), deassert_delay))
      return 0;
    end

    if (initial_asserted) begin
      if (assert_delay != "") begin
        `uvm_error("ARC_RST_CONFIG",
          $sformatf("Reset '%s' is initially asserted and cannot have assert_delay '%s'",
            get_name(), assert_delay))
        return 0;
      end
      m_assert_delay = 0.0;
    end
    else begin
      if (!arc_crg_time_utils::try_time_to_delay(assert_delay, m_assert_delay)) begin
        `uvm_error("ARC_RST_CONFIG",
          $sformatf("Reset '%s' starts inactive and requires assert_delay", get_name()))
        return 0;
      end
      if (m_assert_delay >= m_deassert_delay) begin
        `uvm_error("ARC_RST_CONFIG",
          $sformatf("Reset '%s' assert delay (%0.6f) must precede deassert delay (%0.6f)",
            get_name(), m_assert_delay, m_deassert_delay))
        return 0;
      end
    end

    m_frozen = 1;
    return 1;
  endfunction

  function bit is_deasserted();
    return m_started && m_schedule_complete && m_deasserted;
  endfunction

  task wait_until_deasserted();
    wait (m_started);
    wait (m_schedule_complete && m_deasserted);
  endtask

  task assert_rst();
    wait (m_started);
    m_manual_control = 1;
    drive_asserted();
    complete_startup_schedule();
  endtask

  task deassert_rst();
    wait (m_started);
    m_manual_control = 1;
    drive_deasserted();
    complete_startup_schedule();
  endtask

  task run();
    if (!m_frozen) begin
      `uvm_fatal("ARC_RST_RUN",
        $sformatf("Reset '%s' was not validated before run", get_name()))
      return;
    end
    if (m_run_started) begin
      `uvm_error("ARC_RST_RUN",
        $sformatf("Reset '%s' was already started", get_name()))
      return;
    end

    m_run_started = 1;
    m_started = 1;
    if (initial_asserted) begin
      drive_asserted();
      #(m_deassert_delay);
      if (!m_manual_control) begin
        drive_deasserted();
        complete_startup_schedule();
      end
    end
    else begin
      drive_deasserted();
      #(m_assert_delay);
      if (!m_manual_control)
        drive_asserted();
      #(m_deassert_delay - m_assert_delay);
      if (!m_manual_control) begin
        drive_deasserted();
        complete_startup_schedule();
      end
    end
  endtask

endclass

`endif // ARC_RST_SOURCE_SVH
