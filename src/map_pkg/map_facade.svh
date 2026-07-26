// =============================================================================
// Map Package - MAP Facade
// =============================================================================
// Description: Static facade for memory map view registration and access.
//              Provides resource index, not current selection state.
// =============================================================================

`ifndef MAP_FACADE_SVH
`define MAP_FACADE_SVH

class MAP;

  // -------------------------------------------------------------------------
  // Internal Storage
  // -------------------------------------------------------------------------

  // View registry
  protected static map_view m_views[string];

  // -------------------------------------------------------------------------
  // View Registration
  // -------------------------------------------------------------------------

  // Register a view
  // Duplicate registration: uvm_error and reject
  static function void register_view(string name, map_view v);
    if (m_views.exists(name)) begin
      `uvm_error("MAP_REGISTER",
        $sformatf("View '%s' already registered - duplicate registration rejected", name))
      return;
    end
    m_views[name] = v;
    `uvm_info("MAP_REGISTER",
      $sformatf("View '%s' registered", name), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // View Access
  // -------------------------------------------------------------------------

  // Check if view exists (no error if not found)
  static function bit has_view(string name);
    return m_views.exists(name);
  endfunction

  // Get view
  // Fatal if not found
  static function map_view view(string name);
    if (!m_views.exists(name)) begin
      `uvm_fatal("MAP_VIEW",
        $sformatf("View '%s' not found - has it been registered?", name))
      return null;
    end
    return m_views[name];
  endfunction

  // -------------------------------------------------------------------------
  // Enumeration
  // -------------------------------------------------------------------------

  // Get all registered view names
  static function void get_view_names(ref string names[$]);
    string name;
    names.delete();
    if (m_views.first(name)) begin
      do begin
        names.push_back(name);
      end while (m_views.next(name));
    end
  endfunction

endclass

`endif // MAP_FACADE_SVH
