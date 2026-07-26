// =============================================================================
// Bus Package - Master Handle
// =============================================================================
// Description: Proxy handle for bus master access.
//              Provides two interfaces:
//              - Main interface: write/read (uvm_error on failure)
//              - Check interface: try_write/try_read (returns status)
// =============================================================================

`ifndef BUS_MASTER_HANDLE_SVH
`define BUS_MASTER_HANDLE_SVH

virtual class bus_master_handle extends uvm_object;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // Main Interface - for positive testing
  // -------------------------------------------------------------------------

  // Write data to address
  // n_bytes = 0: use endpoint default width
  // On failure: uvm_error with error type
  virtual task write(
    input  bus_addr_t addr,
    input  bus_data_t data,
    input  int unsigned n_bytes = 0
  );
    bus_status_e status;
    try_write(status, addr, data, n_bytes);
    if (status != BUS_OK) begin
      `uvm_error("BUS_WRITE",
        $sformatf("Write failed at addr 0x%16h with status %s", addr, status.name()))
    end
  endtask

  // Read data from address
  // n_bytes = 0: use endpoint default width
  // On failure: uvm_error with error type
  virtual task read(
    input  bus_addr_t addr,
    output bus_data_t data,
    input  int unsigned n_bytes = 0
  );
    bus_status_e status;
    try_read(status, addr, data, n_bytes);
    if (status != BUS_OK) begin
      `uvm_error("BUS_READ",
        $sformatf("Read failed at addr 0x%16h with status %s", addr, status.name()))
    end
  endtask

  // -------------------------------------------------------------------------
  // Check Interface - for negative testing and explicit result checking
  // -------------------------------------------------------------------------

  // Try to write data to address
  // Returns status in output argument
  pure virtual task try_write(
    output bus_status_e status,
    input  bus_addr_t addr,
    input  bus_data_t data,
    input  int unsigned n_bytes = 0
  );

  // Try to read data from address
  // Returns status in output argument
  pure virtual task try_read(
    output bus_status_e status,
    input  bus_addr_t addr,
    output bus_data_t data,
    input  int unsigned n_bytes = 0
  );

endclass

`endif // BUS_MASTER_HANDLE_SVH
