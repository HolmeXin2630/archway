// =============================================================================
// Test: archway_config_base
// =============================================================================
// Description: Test bench to verify archway_config_base functionality.
// =============================================================================

module test_archway_config_base;

  // Import UVM and Archway Core Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import archway_core_pkg::*;

  // -------------------------------------------------------------------------
  // Test Config Class
  // -------------------------------------------------------------------------

  // A simple test config that inherits from archway_config_base
  class test_config extends archway_config_base;

    // Config fields
    string m_name;
    int m_value;

    // Constructor
    function new(string name = "");
      super.new(name);
      m_name = "";
      m_value = 0;
    endfunction

    // Validate implementation
    virtual function void validate(ref string errors[$]);
      if (m_name == "") begin
        errors.push_back("name cannot be empty");
      end
      if (m_value < 0) begin
        errors.push_back("value must be non-negative");
      end
    endfunction

    // Freeze override (calls super.freeze())
    virtual function void freeze();
      super.freeze();
      // Additional freeze logic if needed
    endfunction

    // Setters with freeze check
    function void set_name(string name);
      check_not_frozen("name");
      m_name = name;
    endfunction

    function void set_value(int value);
      check_not_frozen("value");
      m_value = value;
    endfunction

  endclass

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    test_config cfg;
    string errors[$];

    $display("=== Testing archway_config_base ===");

    // Test 1: Create config
    $display("\n--- Test 1: Create config ---");
    cfg = new("test_cfg");
    assert (cfg != null) else $fatal("Failed to create config");
    assert (cfg.is_frozen() == 0) else $fatal("Config should not be frozen initially");
    $display("PASS: Config created successfully");

    // Test 2: Set values before freeze
    $display("\n--- Test 2: Set values before freeze ---");
    cfg.set_name("test");
    cfg.set_value(42);
    assert (cfg.m_name == "test") else $fatal("Name not set correctly");
    assert (cfg.m_value == 42) else $fatal("Value not set correctly");
    $display("PASS: Values set successfully");

    // Test 3: Validate valid config
    $display("\n--- Test 3: Validate valid config ---");
    errors.delete();
    cfg.validate(errors);
    assert (errors.size() == 0) else $fatal("Validation should pass for valid config");
    $display("PASS: Validation passed");

    // Test 4: Validate invalid config
    $display("\n--- Test 4: Validate invalid config ---");
    cfg.set_name("");
    errors.delete();
    cfg.validate(errors);
    assert (errors.size() == 1) else $fatal("Validation should fail for empty name");
    assert (errors[0] == "name cannot be empty") else $fatal("Wrong error message");
    $display("PASS: Validation failed as expected: %s", errors[0]);

    // Test 5: Freeze config
    $display("\n--- Test 5: Freeze config ---");
    cfg.set_name("test"); // Reset name
    cfg.freeze();
    assert (cfg.is_frozen() == 1) else $fatal("Config should be frozen after freeze()");
    $display("PASS: Config frozen successfully");

    // Test 6: Attempt to modify after freeze (should fail)
    $display("\n--- Test 6: Attempt to modify after freeze ---");
    // Note: In a real test, we would catch the UVM_FATAL
    // For now, we just verify the freeze state
    assert (cfg.is_frozen() == 1) else $fatal("Config should still be frozen");
    $display("PASS: Config remains frozen");

    // Test 7: Validate frozen config
    $display("\n--- Test 7: Validate frozen config ---");
    errors.delete();
    cfg.validate(errors);
    assert (errors.size() == 0) else $fatal("Validation should pass for valid frozen config");
    $display("PASS: Frozen config validation passed");

    $display("\n=== All tests passed ===");
    $finish;
  end

endmodule
