// =============================================================================
// Archway Package - Environment Base Class
// =============================================================================
// Description: Base class for Archway unified assembly container.
//              Handles dependency topological sorting, config validation,
//              freeze, and component assembly.
// =============================================================================

`ifndef ARCHWAY_ENV_SVH
`define ARCHWAY_ENV_SVH

class archway_env extends uvm_env;

  // -------------------------------------------------------------------------
  // Internal State
  // -------------------------------------------------------------------------

  // Component enable flags
  protected bit m_bus_enabled = 0;
  protected bit m_map_enabled = 0;

  // YAML paths for components
  protected string m_bus_yaml_path = "";
  protected string m_map_yaml_path = "";

  // Base phase flag - set when base build_phase completes
  protected bit m_base_build_done = 0;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // Template Method: build_phase
  // -------------------------------------------------------------------------

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Call project configuration hook
    configure_archway();

    // Load configs, validate, freeze, and assemble
    // (In v1, this is simplified - YAML loading will be in ticket 06)
    m_base_build_done = 1;

    `uvm_info("ARCHWAY_ENV", "build_phase completed", UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Project Configuration Hook
  // -------------------------------------------------------------------------

  // Override this method to configure Archway components
  // Call enable_bus(), enable_map(), etc. and register component envs
  virtual function void configure_archway();
    // Default: no-op, project overrides this
    `uvm_info("ARCHWAY_ENV", "configure_archway() called (default no-op)", UVM_HIGH)
  endfunction

  // -------------------------------------------------------------------------
  // Component Enable Helpers
  // -------------------------------------------------------------------------

  // Enable bus component with YAML path
  function void enable_bus(string yaml_path = "", string instance_name = "archway_bus");
    m_bus_enabled = 1;
    m_bus_yaml_path = yaml_path;
    `uvm_info("ARCHWAY_ENV",
      $sformatf("Bus enabled: yaml='%s', instance='%s'", yaml_path, instance_name), UVM_MEDIUM)
  endfunction

  // Enable map component with YAML path
  function void enable_map(string yaml_path = "", string instance_name = "archway_map");
    m_map_enabled = 1;
    m_map_yaml_path = yaml_path;
    `uvm_info("ARCHWAY_ENV",
      $sformatf("Map enabled: yaml='%s', instance='%s'", yaml_path, instance_name), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Component Registration
  // -------------------------------------------------------------------------

  // Register a bus env (project creates and registers)
  virtual function void register_bus_env(uvm_component bus_env);
    // In v1, this is a placeholder for future assembly logic
    `uvm_info("ARCHWAY_ENV",
      $sformatf("Bus env registered: %s", bus_env.get_name()), UVM_MEDIUM)
  endfunction

  // Register a map env (project creates and registers)
  virtual function void register_map_env(uvm_component map_env);
    // In v1, this is a placeholder for future assembly logic
    `uvm_info("ARCHWAY_ENV",
      $sformatf("Map env registered: %s", map_env.get_name()), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // connect_phase - Validation
  // -------------------------------------------------------------------------

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Verify base build_phase was executed
    if (!m_base_build_done) begin
      `uvm_fatal("ARCHWAY_ENV",
        "Base build_phase was not executed - did you override build_phase without calling super?")
    end

    `uvm_info("ARCHWAY_ENV", "connect_phase completed", UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Status Queries
  // -------------------------------------------------------------------------

  function bit is_bus_enabled();
    return m_bus_enabled;
  endfunction

  function bit is_map_enabled();
    return m_map_enabled;
  endfunction

  function string get_bus_yaml_path();
    return m_bus_yaml_path;
  endfunction

  function string get_map_yaml_path();
    return m_map_yaml_path;
  endfunction

endclass

`endif // ARCHWAY_ENV_SVH
