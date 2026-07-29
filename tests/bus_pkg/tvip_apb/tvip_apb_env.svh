// =============================================================================
// tvip-apb Test Environment
// =============================================================================
// Description: Assembles tvip-apb master agent, slave memory model, and
//              bus handle. Registers handle with BUS facade.
// =============================================================================

`ifndef TVIP_APB_ENV_SVH
`define TVIP_APB_ENV_SVH

class tvip_apb_env extends uvm_env;

  // Configuration
  tvip_apb_configuration  cfg;
  tvip_apb_vif            vif;
  int                     address_width;
  int                     data_width;
  string                  master_name;

  // Components
  tvip_apb_master_agent   master_agent;
  tvip_apb_slave_mem      slave_mem;
  tvip_apb_bus_handle     bus_handle;

  `uvm_component_utils(tvip_apb_env)

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get virtual interface from config_db
    if (!uvm_config_db #(tvip_apb_vif)::get(this, "", "vif", vif)) begin
      `uvm_fatal("TVIP_APB_ENV", "Failed to get vif from config_db")
    end

    // Create and configure tvip-apb configuration
    cfg = tvip_apb_configuration::type_id::create("cfg");
    cfg.vif           = vif;
    cfg.address_width = address_width;
    cfg.data_width    = data_width;

    // Set configuration for master agent
    uvm_config_db #(tvip_apb_configuration)::set(this, "master_agent*", "configuration", cfg);

    // Create components
    master_agent  = tvip_apb_master_agent::type_id::create("master_agent", this);
    slave_mem     = tvip_apb_slave_mem::type_id::create("slave_mem", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Create bus handle and register with BUS facade
    bus_handle = new(
      .name  (master_name),
      .sqr   (master_agent.sequencer)
    );
    BUS::register(master_name, bus_handle);

    // Connect slave_mem to vif
    slave_mem.vif         = vif;
    slave_mem.data_width  = data_width;
  endfunction

endclass

`endif // TVIP_APB_ENV_SVH
