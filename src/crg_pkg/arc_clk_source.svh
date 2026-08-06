`ifndef ARC_CLK_SOURCE_SVH
`define ARC_CLK_SOURCE_SVH

class arc_clk_source extends uvm_object;

  `uvm_object_utils(arc_clk_source)

  virtual arc_clk_if vif;
  string freq;
  real duty_cycle_pct;
  real cycle_jitter_ppm;
  string start_delay;
  int unsigned random_seed;

  protected realtime m_period;
  protected real m_duty_cycle_pct;
  protected real m_cycle_jitter_ppm;
  protected realtime m_start_delay;
  protected bit m_frozen;
  protected bit m_running;
  protected bit m_run_started;
  protected rand int unsigned m_random_word;
  protected semaphore m_timing_lock;
  protected event m_timing_applied;
  protected bit m_has_pending_timing;
  protected realtime m_pending_period;
  protected real m_pending_duty_cycle_pct;
  protected real m_pending_cycle_jitter_ppm;

  function new(string name = "");
    super.new(name);
    freq             = "100MHz";
    duty_cycle_pct   = 50.0;
    cycle_jitter_ppm = 0.0;
    start_delay      = "random";
    m_timing_lock    = new(1);
  endfunction

  protected function realtime random_unit_interval();
    if (randomize(m_random_word) == 0) begin
      `uvm_fatal("ARC_CLK_RANDOM",
        $sformatf("Clock '%s' could not generate a random value", get_name()))
      return 0.0;
    end
    return real'(m_random_word) / 4_294_967_296.0;
  endfunction

  protected function bit timing_is_representable(
    input realtime period,
    input real duty_pct,
    input real jitter_ppm
  );
    realtime minimum_period;
    realtime minimum_delay;

    if (period <= 0.0 || duty_pct <= 0.0 || duty_pct >= 100.0 ||
        jitter_ppm < 0.0 || jitter_ppm >= 1.0e6)
      return 0;

    minimum_delay  = 1.0e-3;
    minimum_period = period * (1.0 - jitter_ppm * 1.0e-6);
    return minimum_period * duty_pct / 100.0 >= minimum_delay &&
           minimum_period * (100.0 - duty_pct) / 100.0 >= minimum_delay;
  endfunction

  function bit validate_and_freeze();
    if (m_frozen) begin
      `uvm_error("ARC_CLK_CONFIG",
        $sformatf("Clock '%s' startup configuration is already frozen", get_name()))
      return 0;
    end

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

    if (!timing_is_representable(m_period, duty_cycle_pct, cycle_jitter_ppm)) begin
      `uvm_error("ARC_CLK_CONFIG",
        $sformatf("Clock '%s' has invalid duty cycle or jitter", get_name()))
      return 0;
    end

    if (random_seed != 0)
      srandom(random_seed);
    else if (uvm_object::use_uvm_seeding)
      srandom(uvm_create_random_seed(get_type_name(), get_full_name()));

    if (start_delay.tolower() == "random")
      m_start_delay = random_unit_interval() * m_period;
    else if (!arc_crg_time_utils::try_time_to_delay(start_delay, m_start_delay)) begin
      `uvm_error("ARC_CLK_CONFIG",
        $sformatf("Clock '%s' has invalid start delay '%s'", get_name(), start_delay))
      return 0;
    end

    m_duty_cycle_pct   = duty_cycle_pct;
    m_cycle_jitter_ppm = cycle_jitter_ppm;
    m_frozen = 1;
    `uvm_info("ARC_CLK_CONFIG",
      $sformatf("Clock '%s' start delay resolved to %0.6f at %s precision",
        get_name(), m_start_delay, arc_crg_time_utils::precision_name()),
      UVM_MEDIUM)
    return 1;
  endfunction

  protected function void apply_pending_timing();
    if (!m_has_pending_timing)
      return;

    m_period                 = m_pending_period;
    m_duty_cycle_pct         = m_pending_duty_cycle_pct;
    m_cycle_jitter_ppm       = m_pending_cycle_jitter_ppm;
    m_has_pending_timing     = 0;
    ->m_timing_applied;
  endfunction

  protected task request_timing_locked(
    input realtime period,
    input real duty_pct,
    input real jitter_ppm
  );
    m_pending_period           = period;
    m_pending_duty_cycle_pct   = duty_pct;
    m_pending_cycle_jitter_ppm = jitter_ppm;
    m_has_pending_timing       = 1;
    @m_timing_applied;
  endtask

  task change_freq(input string new_freq);
    realtime new_period;

    if (!arc_crg_time_utils::try_frequency_to_period(new_freq, new_period)) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' has invalid runtime frequency '%s'", get_name(), new_freq))
      return;
    end
    m_timing_lock.get(1);
    if (!m_running) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' is not running", get_name()))
      m_timing_lock.put(1);
      return;
    end
    if (!timing_is_representable(new_period, m_duty_cycle_pct, m_cycle_jitter_ppm)) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' cannot represent runtime frequency '%s'", get_name(), new_freq))
      m_timing_lock.put(1);
      return;
    end
    request_timing_locked(new_period, m_duty_cycle_pct, m_cycle_jitter_ppm);
    m_timing_lock.put(1);
  endtask

  task change_duty_cycle(input real new_duty_cycle_pct);
    m_timing_lock.get(1);
    if (!m_running) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' is not running", get_name()))
      m_timing_lock.put(1);
      return;
    end
    if (!timing_is_representable(m_period, new_duty_cycle_pct, m_cycle_jitter_ppm)) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' has invalid runtime duty cycle %0.6f",
          get_name(), new_duty_cycle_pct))
      m_timing_lock.put(1);
      return;
    end
    request_timing_locked(m_period, new_duty_cycle_pct, m_cycle_jitter_ppm);
    m_timing_lock.put(1);
  endtask

  task change_jitter(input real new_cycle_jitter_ppm);
    m_timing_lock.get(1);
    if (!m_running) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' is not running", get_name()))
      m_timing_lock.put(1);
      return;
    end
    if (!timing_is_representable(m_period, m_duty_cycle_pct, new_cycle_jitter_ppm)) begin
      `uvm_error("ARC_CLK_CONTROL",
        $sformatf("Clock '%s' has invalid runtime jitter %0.6fppm",
          get_name(), new_cycle_jitter_ppm))
      m_timing_lock.put(1);
      return;
    end
    request_timing_locked(m_period, m_duty_cycle_pct, new_cycle_jitter_ppm);
    m_timing_lock.put(1);
  endtask

  function void enable_clk();
    vif.sw_clk_en = 1'b1;
  endfunction

  task disable_clk();
    vif.sw_clk_en = 1'b0;
    if (vif.clk === 1'b1)
      @(negedge vif.clk);
  endtask

  task run();
    if (!m_frozen) begin
      `uvm_fatal("ARC_CLK_RUN",
        $sformatf("Clock '%s' was not validated before run", get_name()))
      return;
    end
    if (m_run_started) begin
      `uvm_error("ARC_CLK_RUN",
        $sformatf("Clock '%s' was already started", get_name()))
      return;
    end

    m_run_started      = 1;
    vif.free_run_clk = 1'b0;
    m_running        = 1;

    #(m_start_delay);

    forever begin
      realtime actual_period;
      realtime high_time;
      realtime low_time;
      real jitter_fraction;

      apply_pending_timing();
      jitter_fraction = (2.0 * random_unit_interval() - 1.0) *
                        m_cycle_jitter_ppm * 1.0e-6;
      actual_period = m_period * (1.0 + jitter_fraction);
      high_time     = actual_period * m_duty_cycle_pct / 100.0;
      low_time      = actual_period - high_time;

      vif.free_run_clk <= 1'b1;
      #(high_time);
      vif.free_run_clk <= 1'b0;
      #(low_time);
    end
  endtask

endclass

`endif // ARC_CLK_SOURCE_SVH
