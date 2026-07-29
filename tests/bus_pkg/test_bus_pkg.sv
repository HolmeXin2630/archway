// =============================================================================
// Test: bus_pkg
// =============================================================================
// Description: Test bench to verify bus_pkg functionality.
// =============================================================================

module test_bus_pkg;

  // Import UVM and Bus Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import bus_pkg::*;

  // -------------------------------------------------------------------------
  // Test Master Handle
  // -------------------------------------------------------------------------

  // A simple test master that implements try_write/try_read
  class test_master_handle extends bus_master_handle;

    // Simulated memory
    bit [1023:0] m_memory[bit [63:0]];

    // Constructor
    function new(string name = "");
      super.new(name);
    endfunction

    // Try write implementation
    virtual task try_write(
      output bus_status_e status,
      input  bus_addr_t addr,
      input  bus_data_t data,
      input  int unsigned n_bytes = 0
    );
      // Simulate write
      m_memory[addr] = data;
      status = BUS_OK;
      `uvm_info("TEST_MASTER",
        $sformatf("Write: addr=0x%16h, data=0x%16h", addr, data[63:0]), UVM_HIGH)
    endtask

    // Try read implementation
    virtual task try_read(
      output bus_status_e status,
      input  bus_addr_t addr,
      output bus_data_t data,
      input  int unsigned n_bytes = 0
    );
      // Simulate read
      if (m_memory.exists(addr)) begin
        data = m_memory[addr];
        status = BUS_OK;
      end else begin
        data = '0;
        status = BUS_ERROR;
      end
      `uvm_info("TEST_MASTER",
        $sformatf("Read: addr=0x%16h, data=0x%16h, status=%s", addr, data[63:0], status.name()), UVM_HIGH)
    endtask

  endclass

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    test_master_handle master0, master1;
    bus_master_handle h;
    bus_data_t data;
    bus_status_e status;
    string names[$];

    $display("=== Testing bus_pkg ===");

    // Test 1: Create master handles
    $display("\n--- Test 1: Create master handles ---");
    master0 = new("core0");
    master1 = new("core1");
    assert (master0 != null) else $fatal("Failed to create master0");
    assert (master1 != null) else $fatal("Failed to create master1");
    $display("PASS: Master handles created");

    // Test 2: Register masters
    $display("\n--- Test 2: Register masters ---");
    BUS::register("core0", master0);
    BUS::register("core1", master1);
    assert (BUS::has_master("core0")) else $fatal("core0 not registered");
    assert (BUS::has_master("core1")) else $fatal("core1 not registered");
    assert (!BUS::has_master("core2")) else $fatal("core2 should not exist");
    $display("PASS: Masters registered");

    // Test 3: Get master handles
    $display("\n--- Test 3: Get master handles ---");
    h = BUS::master("core0");
    assert (h == master0) else $fatal("Wrong master returned for core0");
    h = BUS::master("core1");
    assert (h == master1) else $fatal("Wrong master returned for core1");
    $display("PASS: Master handles retrieved");

    // Test 4: Get master names
    $display("\n--- Test 4: Get master names ---");
    BUS::get_master_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 masters, got %0d", names.size());
    $display("PASS: Master names retrieved: %0d masters", names.size());

    // Test 5: Write and read
    $display("\n--- Test 5: Write and read ---");
    h = BUS::master("core0");
    h.write(64'h0000_0000_8000_0000, 64'hDEAD_BEEF_CAFE_BABE);
    h.read(64'h0000_0000_8000_0000, data);
    assert (data[63:0] == 64'hDEAD_BEEF_CAFE_BABE) else $fatal("Read data mismatch");
    $display("PASS: Write and read successful");

    // Test 6: Try write and try read
    $display("\n--- Test 6: Try write and try read ---");
    h = BUS::master("core0");
    h.try_write(status, 64'h0000_0000_8000_0010, 64'h1234_5678_9ABC_DEF0);
    assert (status == BUS_OK) else $fatal("Try write failed");
    h.try_read(status, 64'h0000_0000_8000_0010, data);
    assert (status == BUS_OK) else $fatal("Try read failed");
    assert (data[63:0] == 64'h1234_5678_9ABC_DEF0) else $fatal("Try read data mismatch");
    $display("PASS: Try write and try read successful");

    // Test 7: Read non-existent address
    $display("\n--- Test 7: Read non-existent address ---");
    h = BUS::master("core0");
    h.try_read(status, 64'h0000_0000_FFFF_FFFF, data);
    assert (status == BUS_ERROR) else $fatal("Expected BUS_ERROR for non-existent address");
    $display("PASS: Non-existent address read returns BUS_ERROR");

    // Test 8: Multiple masters
    $display("\n--- Test 8: Multiple masters ---");
    h = BUS::master("core0");
    h.write(64'h0000_0000_9000_0000, 64'hAAAA);
    h = BUS::master("core1");
    h.write(64'h0000_0000_9000_0000, 64'hBBBB);
    h = BUS::master("core0");
    h.read(64'h0000_0000_9000_0000, data);
    assert (data[63:0] == 64'hAAAA) else $fatal("core0 data mismatch");
    h = BUS::master("core1");
    h.read(64'h0000_0000_9000_0000, data);
    assert (data[63:0] == 64'hBBBB) else $fatal("core1 data mismatch");
    $display("PASS: Multiple masters work independently");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
