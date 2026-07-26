// =============================================================================
// Test: bus_pkg (Full - with slave and burst)
// =============================================================================
// Description: Test bench to verify full bus_pkg functionality.
// =============================================================================

module test_bus_pkg_full;

  // Import UVM and Bus Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import bus_pkg::*;

  // -------------------------------------------------------------------------
  // Test Master Handle
  // -------------------------------------------------------------------------

  // A simple test master that implements try_write/try_read and burst variants
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

    // Try burst write implementation
    virtual task try_burst_write(
      output bus_status_e status,
      input  bus_addr_t addr,
      input  bus_data_t data[],
      input  int unsigned beat_bytes = 0,
      input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
    );
      bus_addr_t cur_addr = addr;
      foreach (data[i]) begin
        m_memory[cur_addr] = data[i];
        cur_addr += beat_bytes;
      end
      status = BUS_OK;
      `uvm_info("TEST_MASTER",
        $sformatf("Burst write: addr=0x%16h, beats=%0d", addr, data.size()), UVM_HIGH)
    endtask

    // Try burst read implementation
    virtual task try_burst_read(
      output bus_status_e status,
      input  bus_addr_t addr,
      output bus_data_t data[],
      input  int unsigned num_beats,
      input  int unsigned beat_bytes = 0,
      input  bus_burst_kind_e burst_kind = BUS_BURST_INCR
    );
      bus_addr_t cur_addr = addr;
      data = new[num_beats];
      for (int i = 0; i < num_beats; i++) begin
        if (m_memory.exists(cur_addr)) begin
          data[i] = m_memory[cur_addr];
        end else begin
          data[i] = '0;
        end
        cur_addr += beat_bytes;
      end
      status = BUS_OK;
      `uvm_info("TEST_MASTER",
        $sformatf("Burst read: addr=0x%16h, beats=%0d", addr, num_beats), UVM_HIGH)
    endtask

  endclass

  // -------------------------------------------------------------------------
  // Test Slave Handle
  // -------------------------------------------------------------------------

  // A simple test slave handle
  class test_slave_handle extends bus_slave_handle;

    // Constructor
    function new(string name = "");
      super.new(name);
    endfunction

  endclass

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    test_master_handle master0;
    test_slave_handle slave0, slave1;
    bus_master_handle mh;
    bus_slave_handle sh;
    bus_data_t data;
    bus_data_t burst_data[];
    bus_status_e status;
    string names[$];

    $display("=== Testing bus_pkg (Full) ===");

    // Test 1: Create and register master
    $display("\n--- Test 1: Create and register master ---");
    master0 = new("core0");
    BUS::register("core0", master0);
    assert (BUS::has_master("core0")) else $fatal("core0 not registered");
    $display("PASS: Master registered");

    // Test 2: Create and register slaves
    $display("\n--- Test 2: Create and register slaves ---");
    slave0 = new("uart0");
    slave1 = new("uart1");
    BUS::register_slave("uart0", slave0);
    BUS::register_slave("uart1", slave1);
    assert (BUS::has_slave("uart0")) else $fatal("uart0 not registered");
    assert (BUS::has_slave("uart1")) else $fatal("uart1 not registered");
    $display("PASS: Slaves registered");

    // Test 3: Get slave handles
    $display("\n--- Test 3: Get slave handles ---");
    sh = BUS::slave("uart0");
    assert (sh == slave0) else $fatal("Wrong slave returned for uart0");
    sh = BUS::slave("uart1");
    assert (sh == slave1) else $fatal("Wrong slave returned for uart1");
    $display("PASS: Slave handles retrieved");

    // Test 4: Get slave names
    $display("\n--- Test 4: Get slave names ---");
    BUS::get_slave_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 slaves, got %0d", names.size());
    $display("PASS: Slave names retrieved: %0d slaves", names.size());

    // Test 5: Get all master and slave names
    $display("\n--- Test 5: Get all names ---");
    BUS::get_master_names(names);
    assert (names.size() == 1) else $fatal("Expected 1 master, got %0d", names.size());
    BUS::get_slave_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 slaves, got %0d", names.size());
    $display("PASS: All names retrieved");

    // Test 6: Burst write and read
    $display("\n--- Test 6: Burst write and read ---");
    mh = BUS::master("core0");
    burst_data = new[4];
    burst_data[0] = 64'hAAAA_BBBB_CCCC_DDDD;
    burst_data[1] = 64'h1111_2222_3333_4444;
    burst_data[2] = 64'hEEEE_FFFF_0000_1111;
    burst_data[3] = 64'h5555_6666_7777_8888;
    mh.burst_write(64'h0000_0000_9000_0000, burst_data, 8, BUS_BURST_INCR);
    burst_data = new[4];
    mh.burst_read(64'h0000_0000_9000_0000, burst_data, 4, 8, BUS_BURST_INCR);
    assert (burst_data[0] == 64'hAAAA_BBBB_CCCC_DDDD) else $fatal("Burst read data[0] mismatch");
    assert (burst_data[1] == 64'h1111_2222_3333_4444) else $fatal("Burst read data[1] mismatch");
    assert (burst_data[2] == 64'hEEEE_FFFF_0000_1111) else $fatal("Burst read data[2] mismatch");
    assert (burst_data[3] == 64'h5555_6666_7777_8888) else $fatal("Burst read data[3] mismatch");
    $display("PASS: Burst write and read successful");

    // Test 7: Try burst write and try burst read
    $display("\n--- Test 7: Try burst write and try burst read ---");
    burst_data = new[2];
    burst_data[0] = 64'h1234_5678_9ABC_DEF0;
    burst_data[1] = 64'hFEDC_BA98_7654_3210;
    mh.try_burst_write(status, 64'h0000_0000_A000_0000, burst_data, 8, BUS_BURST_INCR);
    assert (status == BUS_OK) else $fatal("Try burst write failed");
    burst_data = new[2];
    mh.try_burst_read(status, 64'h0000_0000_A000_0000, burst_data, 2, 8, BUS_BURST_INCR);
    assert (status == BUS_OK) else $fatal("Try burst read failed");
    assert (burst_data[0] == 64'h1234_5678_9ABC_DEF0) else $fatal("Try burst read data[0] mismatch");
    assert (burst_data[1] == 64'hFEDC_BA98_7654_3210) else $fatal("Try burst read data[1] mismatch");
    $display("PASS: Try burst write and try burst read successful");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
