// =============================================================================
// Bus Package - BUS Facade
// =============================================================================
// Description: Static facade for bus master registration and access.
//              Provides resource index, not current selection state.
// =============================================================================

`ifndef BUS_FACADE_SVH
`define BUS_FACADE_SVH

class BUS;

  // -------------------------------------------------------------------------
  // Internal Storage
  // -------------------------------------------------------------------------

  // Master handle registry
  protected static bus_master_handle m_masters[string];

  // -------------------------------------------------------------------------
  // Master Registration
  // -------------------------------------------------------------------------

  // Register a master handle
  // Duplicate registration: uvm_error and reject
  static function void register(string name, bus_master_handle h);
    if (m_masters.exists(name)) begin
      `uvm_error("BUS_REGISTER",
        $sformatf("Master '%s' already registered - duplicate registration rejected", name))
      return;
    end
    m_masters[name] = h;
    `uvm_info("BUS_REGISTER",
      $sformatf("Master '%s' registered", name), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Master Access
  // -------------------------------------------------------------------------

  // Check if master exists (no error if not found)
  static function bit has_master(string name);
    return m_masters.exists(name);
  endfunction

  // Get master handle
  // Fatal if not found
  static function bus_master_handle master(string name = "default");
    if (!m_masters.exists(name)) begin
      `uvm_fatal("BUS_MASTER",
        $sformatf("Master '%s' not found - has it been registered?", name))
      return null;
    end
    return m_masters[name];
  endfunction

  // -------------------------------------------------------------------------
  // Enumeration
  // -------------------------------------------------------------------------

  // Get all registered master names
  static function void get_master_names(ref string names[$]);
    string name;
    names.delete();
    if (m_masters.first(name)) begin
      do begin
        names.push_back(name);
      end while (m_masters.next(name));
    end
  endfunction

endclass

`endif // BUS_FACADE_SVH
