// =============================================================================
// Test: archway_pkg
// =============================================================================
// Description: Test bench to verify archway_pkg functionality.
// =============================================================================

module test_archway_pkg;

  // Import UVM and Archway Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import archway_pkg::*;
  import bus_pkg::*;
  import map_pkg::*;

  // -------------------------------------------------------------------------
  // Test Project Environment
  // -------------------------------------------------------------------------

  // A test project env that extends archway_env
  class test_env extends archway_env;

    // Constructor
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    // Override configure_archway to set up components
    virtual function void configure_archway();
      `uvm_info("TEST_ENV", "configure_archway() called", UVM_MEDIUM)

      // Enable bus and map components
      enable_bus("cfg/bus.yaml", "test_bus");
      enable_map("cfg/map.yaml", "test_map");
    endfunction

  endclass

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    test_env env;
    archway_env base_env;
    string names[$];

    $display("=== Testing archway_pkg ===");

    // Test 1: Create test environment
    $display("\n--- Test 1: Create test environment ---");
    env = new("test_env", null);
    assert (env != null) else $fatal("Failed to create test_env");
    $display("PASS: Test environment created");

    // Test 2: Verify build_phase executes
    $display("\n--- Test 2: Verify build_phase executes ---");
    // Note: In a real UVM test, build_phase would be called automatically
    // Here we call it manually for testing
    env.build_phase(null);
    assert (env.is_bus_enabled()) else $fatal("Bus should be enabled");
    assert (env.is_map_enabled()) else $fatal("Map should be enabled");
    $display("PASS: build_phase executed correctly");

    // Test 3: Verify component status
    $display("\n--- Test 3: Verify component status ---");
    assert (env.get_bus_yaml_path() == "cfg/bus.yaml") else $fatal("Wrong bus YAML path");
    assert (env.get_map_yaml_path() == "cfg/map.yaml") else $fatal("Wrong map YAML path");
    $display("PASS: Component status verified");

    // Test 4: Register env with ARCHWAY Facade
    $display("\n--- Test 4: Register env with ARCHWAY Facade ---");
    ARCHWAY::register_env("default", env);
    assert (ARCHWAY::has_env("default")) else $fatal("default env not registered");
    assert (!ARCHWAY::has_env("test")) else $fatal("test env should not exist");
    $display("PASS: Env registered with ARCHWAY Facade");

    // Test 5: Get env from ARCHWAY Facade
    $display("\n--- Test 5: Get env from ARCHWAY Facade ---");
    base_env = ARCHWAY::get_env("default");
    assert (base_env == env) else $fatal("Wrong env returned");
    $display("PASS: Env retrieved from ARCHWAY Facade");

    // Test 6: Get env names
    $display("\n--- Test 6: Get env names ---");
    ARCHWAY::get_env_names(names);
    assert (names.size() == 1) else $fatal("Expected 1 env, got %0d", names.size());
    assert (names[0] == "default") else $fatal("Wrong env name");
    $display("PASS: Env names retrieved");

    // Test 7: Register multiple envs
    $display("\n--- Test 7: Register multiple envs ---");
    begin
      test_env env2 = new("test_env2", null);
      ARCHWAY::register_env("chip0", env);
      ARCHWAY::register_env("chip1", env2);
      assert (ARCHWAY::has_env("chip0")) else $fatal("chip0 not registered");
      assert (ARCHWAY::has_env("chip1")) else $fatal("chip1 not registered");
      ARCHWAY::get_env_names(names);
      assert (names.size() == 3) else $fatal("Expected 3 envs, got %0d", names.size());
    end
    $display("PASS: Multiple envs registered");

    // Test 8: Remove env
    $display("\n--- Test 8: Remove env ---");
    ARCHWAY::remove_env("chip0");
    assert (!ARCHWAY::has_env("chip0")) else $fatal("chip0 should be removed");
    assert (ARCHWAY::has_env("chip1")) else $fatal("chip1 should still exist");
    ARCHWAY::get_env_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 envs, got %0d", names.size());
    $display("PASS: Env removed");

    // Test 9: Verify connect_phase validation
    $display("\n--- Test 9: Verify connect_phase validation ---");
    env.connect_phase(null);
    $display("PASS: connect_phase validation passed");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
