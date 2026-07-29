// =============================================================================
// Test: bus_pkg with tvip-apb backend
// =============================================================================
// Description: Verifies bus_master_handle APB backend via tvip-apb VIP.
//              Tests single write and read through the BUS facade.
// =============================================================================

module test_bus_apb;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import bus_pkg::*;
  import tvip_apb_pkg::*;

  // Include test infrastructure
  `include "tvip_apb/tvip_apb_master_bridge.svh"
  `include "tvip_apb/tvip_apb_slave_mem.svh"
  `include "tvip_apb/tvip_apb_env.svh"

  // -------------------------------------------------------------------------
  // Clock and Reset
  // -------------------------------------------------------------------------

  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #25;
    rst_n = 1;
  end

  // -------------------------------------------------------------------------
  // APB Interface
  // -------------------------------------------------------------------------

  tvip_apb_if apb_if (.pclk(clk), .preset_n(rst_n));

  // -------------------------------------------------------------------------
  // Test Sequence
  // -------------------------------------------------------------------------

  class test_bus_apb_seq extends uvm_sequence;

    `uvm_object_utils(test_bus_apb_seq)

    function new(string name = "");
      super.new(name);
    endfunction

    task body();
      bus_master_handle mh;
      bus_data_t        wdata, rdata;
      bus_status_e      status;

      `uvm_info("TEST", "=== bus_pkg APB Backend Test ===", UVM_NONE)

      // Get the registered master handle
      mh = BUS::master("apb0");

      // Test 1: Single write
      `uvm_info("TEST", "--- Test 1: Single Write ---", UVM_NONE)
      wdata = '0;
      wdata[31:0] = 32'hDEAD_BEEF;
      mh.try_write(status, 64'h0000_0000, wdata, 4);
      assert (status == BUS_OK) else $fatal("Write failed: %s", status.name());
      `uvm_info("TEST", "PASS: Single write OK", UVM_NONE)

      // Test 2: Single read back
      `uvm_info("TEST", "--- Test 2: Single Read ---", UVM_NONE)
      mh.try_read(status, 64'h0000_0000, rdata, 4);
      assert (status == BUS_OK) else $fatal("Read failed: %s", status.name());
      assert (rdata[31:0] == 32'hDEAD_BEEF) else
        $fatal("Read data mismatch: expected 0xDEADBEEF, got 0x%h", rdata[31:0]);
      `uvm_info("TEST", "PASS: Single read OK, data=0xDEADBEEF", UVM_NONE)

      // Test 3: Write to different address
      `uvm_info("TEST", "--- Test 3: Write to address 0x10 ---", UVM_NONE)
      wdata = '0;
      wdata[31:0] = 32'hCAFE_BABE;
      mh.try_write(status, 64'h0000_0010, wdata, 4);
      assert (status == BUS_OK) else $fatal("Write failed: %s", status.name());
      `uvm_info("TEST", "PASS: Write to 0x10 OK", UVM_NONE)

      // Test 4: Read back from address 0x10
      `uvm_info("TEST", "--- Test 4: Read from address 0x10 ---", UVM_NONE)
      mh.try_read(status, 64'h0000_0010, rdata, 4);
      assert (status == BUS_OK) else $fatal("Read failed: %s", status.name());
      assert (rdata[31:0] == 32'hCAFE_BABE) else
        $fatal("Read data mismatch: expected 0xCAFE_BABE, got 0x%h", rdata[31:0]);
      `uvm_info("TEST", "PASS: Read from 0x10 OK, data=0xCAFEBABE", UVM_NONE)

      // Test 5: Main interface write (uvm_error on failure)
      `uvm_info("TEST", "--- Test 5: Main interface write ---", UVM_NONE)
      wdata = '0;
      wdata[31:0] = 32'h1234_5678;
      mh.write(64'h0000_0020, wdata, 4);
      `uvm_info("TEST", "PASS: Main interface write OK", UVM_NONE)

      // Test 6: Main interface read
      `uvm_info("TEST", "--- Test 6: Main interface read ---", UVM_NONE)
      mh.read(64'h0000_0020, rdata, 4);
      assert (rdata[31:0] == 32'h1234_5678) else
        $fatal("Read data mismatch: expected 0x12345678, got 0x%h", rdata[31:0]);
      `uvm_info("TEST", "PASS: Main interface read OK, data=0x12345678", UVM_NONE)

      // Test 7: Burst write (unsupported)
      `uvm_info("TEST", "--- Test 7: Burst write (expect UNSUPPORTED) ---", UVM_NONE)
      begin
        bus_data_t burst_data[];
        burst_data = new[2];
        burst_data[0] = 64'hAAAA;
        burst_data[1] = 64'hBBBB;
        mh.try_burst_write(status, 64'h0000_0030, burst_data, 4, BUS_BURST_INCR);
        assert (status == BUS_UNSUPPORTED) else
          $fatal("Expected BUS_UNSUPPORTED, got %s", status.name());
      end
      `uvm_info("TEST", "PASS: Burst write returns BUS_UNSUPPORTED", UVM_NONE)

      `uvm_info("TEST", "=== All tests passed ===", UVM_NONE)
    endtask

  endclass

  // -------------------------------------------------------------------------
  // Top-level Test
  // -------------------------------------------------------------------------

  class test_bus_apb extends uvm_test;

    tvip_apb_env  apb_env;

    `uvm_component_utils(test_bus_apb)

    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Set virtual interface
      uvm_config_db #(tvip_apb_vif)::set(this, "*", "vif", apb_if);

      // Create APB environment
      apb_env               = tvip_apb_env::type_id::create("apb_env", this);
      apb_env.master_name   = "apb0";
      apb_env.address_width = 16;
      apb_env.data_width    = 32;
    endfunction

    task run_phase(uvm_phase phase);
      test_bus_apb_seq seq;

      phase.raise_objection(this);

      seq = test_bus_apb_seq::type_id::create("seq");
      seq.start(null);

      #100;
      phase.drop_objection(this);
    endtask

  endclass

  // -------------------------------------------------------------------------
  // Run Test
  // -------------------------------------------------------------------------

  initial begin
    run_test("test_bus_apb");
  end

endmodule
