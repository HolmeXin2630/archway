// =============================================================================
// Test: map_pkg
// =============================================================================
// Description: Test bench to verify map_pkg functionality.
// =============================================================================

module test_map_pkg;

  // Import UVM and Map Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import map_pkg::*;

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    map_view core0_map, core1_map;
    map_region region;
    map_addr_t base;
    string names[$];

    $display("=== Testing map_pkg ===");

    // Test 1: Create views
    $display("\n--- Test 1: Create views ---");
    core0_map = new("core0");
    core1_map = new("core1");
    assert (core0_map != null) else $fatal("Failed to create core0_map");
    assert (core1_map != null) else $fatal("Failed to create core1_map");
    $display("PASS: Views created");

    // Test 2: Add regions
    $display("\n--- Test 2: Add regions ---");
    core0_map.add_region("uart0", 64'h8000_0000, 64'h1000);
    core0_map.add_region("spi0", 64'h8000_1000, 64'h1000);
    core1_map.add_region("uart0", 64'h4000_0000, 64'h1000);
    core1_map.add_region("uart1", 64'h4000_1000, 64'h1000);
    assert (core0_map.has_region("uart0")) else $fatal("uart0 not in core0");
    assert (core0_map.has_region("spi0")) else $fatal("spi0 not in core0");
    assert (core1_map.has_region("uart0")) else $fatal("uart0 not in core1");
    assert (core1_map.has_region("uart1")) else $fatal("uart1 not in core1");
    assert (!core0_map.has_region("uart1")) else $fatal("uart1 should not be in core0");
    $display("PASS: Regions added");

    // Test 3: Get regions
    $display("\n--- Test 3: Get regions ---");
    core0_map.get_region("uart0", region);
    assert (region.base == 64'h8000_0000) else $fatal("Wrong base for core0.uart0");
    assert (region.size == 64'h1000) else $fatal("Wrong size for core0.uart0");
    core1_map.get_region("uart0", region);
    assert (region.base == 64'h4000_0000) else $fatal("Wrong base for core1.uart0");
    assert (region.size == 64'h1000) else $fatal("Wrong size for core1.uart0");
    $display("PASS: Regions retrieved");

    // Test 4: Get base address
    $display("\n--- Test 4: Get base address ---");
    assert (core0_map.get_base("uart0", base)) else $fatal("Failed to get base for core0.uart0");
    assert (base == 64'h8000_0000) else $fatal("Wrong base for core0.uart0");
    assert (core1_map.get_base("uart0", base)) else $fatal("Failed to get base for core1.uart0");
    assert (base == 64'h4000_0000) else $fatal("Wrong base for core1.uart0");
    assert (!core0_map.get_base("uart1", base)) else $fatal("uart1 should not exist in core0");
    $display("PASS: Base addresses retrieved");

    // Test 5: Get target names
    $display("\n--- Test 5: Get target names ---");
    core0_map.get_target_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 targets in core0, got %0d", names.size());
    core1_map.get_target_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 targets in core1, got %0d", names.size());
    $display("PASS: Target names retrieved");

    // Test 6: Register views with MAP Facade
    $display("\n--- Test 6: Register views with MAP Facade ---");
    MAP::register_view("core0", core0_map);
    MAP::register_view("core1", core1_map);
    assert (MAP::has_view("core0")) else $fatal("core0 not registered");
    assert (MAP::has_view("core1")) else $fatal("core1 not registered");
    assert (!MAP::has_view("core2")) else $fatal("core2 should not exist");
    $display("PASS: Views registered with MAP Facade");

    // Test 7: Get views from MAP Facade
    $display("\n--- Test 7: Get views from MAP Facade ---");
    assert (MAP::view("core0") == core0_map) else $fatal("Wrong view returned for core0");
    assert (MAP::view("core1") == core1_map) else $fatal("Wrong view returned for core1");
    $display("PASS: Views retrieved from MAP Facade");

    // Test 8: Get view names
    $display("\n--- Test 8: Get view names ---");
    MAP::get_view_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 views, got %0d", names.size());
    $display("PASS: View names retrieved");

    // Test 9: Use MAP Facade with view and region
    $display("\n--- Test 9: Use MAP Facade with view and region ---");
    void'(MAP::view("core0").get_region("uart0", region));
    assert (region.base == 64'h8000_0000) else $fatal("Wrong base via MAP Facade");
    assert (region.size == 64'h1000) else $fatal("Wrong size via MAP Facade");
    void'(MAP::view("core1").get_region("uart0", region));
    assert (region.base == 64'h4000_0000) else $fatal("Wrong base via MAP Facade");
    assert (region.size == 64'h1000) else $fatal("Wrong size via MAP Facade");
    $display("PASS: MAP Facade with view and region works");

    // Test 10: Check region properties
    $display("\n--- Test 10: Check region properties ---");
    void'(MAP::view("core0").get_region("uart0", region));
    assert (region.get_end() == 64'h8000_1000) else $fatal("Wrong end address");
    assert (region.is_in_region(64'h8000_0000)) else $fatal("Base should be in region");
    assert (region.is_in_region(64'h8000_0FFF)) else $fatal("Last byte should be in region");
    assert (!region.is_in_region(64'h8000_1000)) else $fatal("End should not be in region");
    assert (!region.is_in_region(64'h7FFF_FFFF)) else $fatal("Before region should not be in region");
    $display("PASS: Region properties verified");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
