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

  // -------------------------------------------------------------------------
  // Burst Main Interface - for positive testing
  // -------------------------------------------------------------------------

  // Burst write data to address
  // beat_bytes = 0: use endpoint default burst beat width
  // burst_kind = BUS_BURST_INCR: default burst mode
  // On failure: uvm_error with error type
  virtual task burst_write(
    input  bus_addr_t addr,
    input  bus_data_t data[],
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );
    bus_status_e status;
    try_burst_write(status, addr, data, beat_bytes, burst_kind);
    if (status != BUS_OK) begin
      `uvm_error("BUS_BURST_WRITE",
        $sformatf("Burst write failed at addr 0x%16h with status %s", addr, status.name()))
    end
  endtask

  // Burst read data from address
  // num_beats: number of beats to read
  // beat_bytes = 0: use endpoint default burst beat width
  // burst_kind = BUS_BURST_INCR: default burst mode
  // On failure: uvm_error with error type
  virtual task burst_read(
    input  bus_addr_t addr,
    output bus_data_t data[],
    input  int unsigned num_beats,
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );
    bus_status_e status;
    try_burst_read(status, addr, data, num_beats, beat_bytes, burst_kind);
    if (status != BUS_OK) begin
      `uvm_error("BUS_BURST_READ",
        $sformatf("Burst read failed at addr 0x%16h with status %s", addr, status.name()))
    end
  endtask

  // -------------------------------------------------------------------------
  // Burst Check Interface - for negative testing and explicit result checking
  // -------------------------------------------------------------------------

  // Try to burst write data to address
  // Returns status in output argument
  pure virtual task try_burst_write(
    output bus_status_e status,
    input  bus_addr_t addr,
    input  bus_data_t data[],
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );

  // Try to burst read data from address
  // Returns status in output argument
  pure virtual task try_burst_read(
    output bus_status_e status,
    input  bus_addr_t addr,
    output bus_data_t data[],
    input  int unsigned num_beats,
    input  int unsigned beat_bytes = 0,
    input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
  );

endclass

`endif // BUS_MASTER_HANDLE_SVH
