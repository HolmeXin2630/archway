// =============================================================================
// Bus Package - Slave Handle
// =============================================================================
// Description: Proxy handle for bus slave access.
//              Used by bus verification sequences to discover slave resources.
// =============================================================================

`ifndef BUS_SLAVE_HANDLE_SVH
`define BUS_SLAVE_HANDLE_SVH

virtual class bus_slave_handle extends uvm_object;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // Slave Interface
  // -------------------------------------------------------------------------

  // Get slave region info (optional, may return default values)
  // Note: In v1, region info is not enforced in slave handle
  // Use MAP::view(...).get_region() for region queries
  virtual function string get_name();
    return get_name();
  endfunction

endclass

`endif // BUS_SLAVE_HANDLE_SVH
