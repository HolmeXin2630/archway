// =============================================================================
// Test: archway_pkg with YAML Configuration
// =============================================================================
// Description: Test bench to verify YAML configuration loading.
// =============================================================================

module test_archway_yaml;

  // Import UVM and Archway Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import archway_pkg::*;
  import bus_pkg::*;
  import map_pkg::*;

  // -------------------------------------------------------------------------
  // Test Project Environment
  // -------------------------------------------------------------------------

  // A test project env that loads configuration from YAML
  class test_env extends archway_env;

    // Constructor
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    // Override configure_archway to set up components
    virtual function void configure_archway();
      `uvm_info("TEST_ENV", "configure_archway() called", UVM_MEDIUM)

      // Enable bus and map components with YAML paths
      enable_bus("cfg/bus.yaml");
      enable_map("cfg/map.yaml");
    endfunction

    // Override build_phase to load YAML configs
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Load map configuration
      if (is_map_enabled()) begin
        load_map_config();
      end

      // Load bus configuration
      if (is_bus_enabled()) begin
        load_bus_config();
      end
    endfunction

    // Load map configuration from YAML
    protected function void load_map_config();
      map_view views[string];
      string view_names[$];

      if (config_loader::load_map_config(get_map_yaml_path(), views)) begin
        // Register views with MAP Facade
        foreach (views[name]) begin
          MAP::register_view(name, views[name]);
        end

        `uvm_info("TEST_ENV",
          $sformatf("Loaded %0d map views from YAML", views.size()), UVM_MEDIUM)
      end else begin
        `uvm_error("TEST_ENV", "Failed to load map configuration")
      end
    endfunction

    // Load bus configuration from YAML
    protected function void load_bus_config();
      string masters[$];
      string slaves[$];

      if (config_loader::load_bus_config(get_bus_yaml_path(), masters, slaves)) begin
        `uvm_info("TEST_ENV",
          $sformatf("Loaded %0d masters, %0d slaves from YAML", masters.size(), slaves.size()), UVM_MEDIUM)
      end else begin
        `uvm_error("TEST_ENV", "Failed to load bus configuration")
      end
    endfunction

  endclass

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    test_env env;
    map_region region;
    string names[$];

    $display("=== Testing archway_pkg with YAML Configuration ===");

    // Test 1: Create test environment
    $display("\n--- Test 1: Create test environment ---");
    env = new("test_env", null);
    assert (env != null) else $fatal("Failed to create test_env");
    $display("PASS: Test environment created");

    // Test 2: Build phase with YAML loading
    $display("\n--- Test 2: Build phase with YAML loading ---");
    env.build_phase(null);
    assert (env.is_bus_enabled()) else $fatal("Bus should be enabled");
    assert (env.is_map_enabled()) else $fatal("Map should be enabled");
    $display("PASS: Build phase completed with YAML loading");

    // Test 3: Verify map views loaded from YAML
    $display("\n--- Test 3: Verify map views loaded from YAML ---");
    assert (MAP::has_view("core0")) else $fatal("core0 view not loaded");
    assert (MAP::has_view("core1")) else $fatal("core1 view not loaded");
    MAP::get_view_names(names);
    assert (names.size() == 2) else $fatal("Expected 2 views, got %0d", names.size());
    $display("PASS: Map views loaded from YAML");

    // Test 4: Verify map regions loaded from YAML
    $display("\n--- Test 4: Verify map regions loaded from YAML ---");
    void'(MAP::view("core0").get_region("uart0", region));
    assert (region.base == 64'h0000_0000_8000_0000) else $fatal("Wrong base for core0.uart0: %h", region.base);
    assert (region.size == 64'h1000) else $fatal("Wrong size for core0.uart0");
    void'(MAP::view("core0").get_region("spi0", region));
    assert (region.base == 64'h0000_0000_8000_1000) else $fatal("Wrong base for core0.spi0: %h", region.base);
    assert (region.size == 64'h1000) else $fatal("Wrong size for core0.spi0");
    void'(MAP::view("core1").get_region("uart0", region));
    assert (region.base == 64'h0000_0000_4000_0000) else $fatal("Wrong base for core1.uart0: %h", region.base);
    assert (region.size == 64'h1000) else $fatal("Wrong size for core1.uart0");
    void'(MAP::view("core1").get_region("uart1", region));
    assert (region.base == 64'h0000_0000_4000_1000) else $fatal("Wrong base for core1.uart1: %h", region.base);
    assert (region.size == 64'h1000) else $fatal("Wrong size for core1.uart1");
    $display("PASS: Map regions loaded from YAML");

    // Test 5: Use MAP Facade with YAML-loaded views
    $display("\n--- Test 5: Use MAP Facade with YAML-loaded views ---");
    void'(MAP::view("core0").get_region("uart0", region));
    assert (region.base == 64'h0000_0000_8000_0000) else $fatal("Wrong base via MAP Facade: %h", region.base);
    assert (region.size == 64'h1000) else $fatal("Wrong size via MAP Facade");
    $display("PASS: MAP Facade works with YAML-loaded views");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
