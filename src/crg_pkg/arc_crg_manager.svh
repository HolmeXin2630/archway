`ifndef ARC_CRG_MANAGER_SVH
`define ARC_CRG_MANAGER_SVH

class arc_crg_manager extends uvm_component;

  `uvm_component_utils(arc_crg_manager)

  protected static arc_crg_manager m_instance;

  function new(string name = "arc_crg_manager", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  static function arc_crg_manager get_or_create(uvm_component parent);
    if (m_instance == null)
      m_instance = arc_crg_manager::type_id::create("crg_manager", parent);
    return m_instance;
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      ARC_CLKS::run_all();
      ARC_RSTS::run_all();
    join
  endtask

endclass

`endif // ARC_CRG_MANAGER_SVH
