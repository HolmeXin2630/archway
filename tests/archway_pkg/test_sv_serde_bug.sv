// =============================================================================
// Test: sv_serde Address Parsing Bug
// =============================================================================
// Description: Test to demonstrate sv_serde's as_int() sign extension issue
//              when parsing addresses > 0x7FFFFFFF.
// =============================================================================

module test_sv_serde_bug;

  // Import UVM and sv_yaml Package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sv_yaml_pkg::*;

  // -------------------------------------------------------------------------
  // Test Cases
  // -------------------------------------------------------------------------

  initial begin
    sv_yaml yaml;
    int val32;
    bit [63:0] val64;

    $display("=== Testing sv_serde Address Parsing Bug ===");

    // Test 1: Parse address 0x80000000 (2147483648)
    $display("\n--- Test 1: Parse address 0x80000000 ---");
    yaml = sv_yaml::parse("base: 2147483648");
    assert (yaml != null) else $fatal("Failed to parse YAML");
    val32 = yaml.get("base").as_int();
    val64 = val32;  // Implicit sign extension
    $display("  as_int() result: %0d (0x%08h)", val32, val32);
    $display("  Sign-extended to 64-bit: 0x%16h", val64);
    $display("  Expected: 0x0000000080000000");
    $display("  Actual:   0x%16h", val64);
    if (val64 == 64'hFFFF_FFFF_8000_0000) begin
      $display("  BUG CONFIRMED: Sign extension occurred!");
    end else if (val64 == 64'h0000_0000_8000_0000) begin
      $display("  No bug: Correct 64-bit value");
    end

    // Test 2: Parse address 0x40000000 (1073741824)
    $display("\n--- Test 2: Parse address 0x40000000 ---");
    yaml = sv_yaml::parse("base: 1073741824");
    assert (yaml != null) else $fatal("Failed to parse YAML");
    val32 = yaml.get("base").as_int();
    val64 = val32;  // No sign extension (positive value)
    $display("  as_int() result: %0d (0x%08h)", val32, val32);
    $display("  Sign-extended to 64-bit: 0x%16h", val64);
    $display("  Expected: 0x0000000040000000");
    $display("  Actual:   0x%16h", val64);
    if (val64 == 64'h0000_0000_4000_0000) begin
      $display("  No bug: Correct 64-bit value");
    end

    // Test 3: Parse address 0x7FFFFFFF (2147483647 - max positive)
    $display("\n--- Test 3: Parse address 0x7FFFFFFF ---");
    yaml = sv_yaml::parse("base: 2147483647");
    assert (yaml != null) else $fatal("Failed to parse YAML");
    val32 = yaml.get("base").as_int();
    val64 = val32;  // No sign extension (positive value)
    $display("  as_int() result: %0d (0x%08h)", val32, val32);
    $display("  Sign-extended to 64-bit: 0x%16h", val64);
    $display("  Expected: 0x000000007FFFFFFF");
    $display("  Actual:   0x%16h", val64);
    if (val64 == 64'h0000_0000_7FFF_FFFF) begin
      $display("  No bug: Correct 64-bit value");
    end

    // Test 4: Parse address 0x80000001 (2147483649)
    $display("\n--- Test 4: Parse address 0x80000001 ---");
    yaml = sv_yaml::parse("base: 2147483649");
    assert (yaml != null) else $fatal("Failed to parse YAML");
    val32 = yaml.get("base").as_int();
    val64 = val32;  // Implicit sign extension
    $display("  as_int() result: %0d (0x%08h)", val32, val32);
    $display("  Sign-extended to 64-bit: 0x%16h", val64);
    $display("  Expected: 0x0000000080000001");
    $display("  Actual:   0x%16h", val64);
    if (val64 == 64'hFFFF_FFFF_8000_0001) begin
      $display("  BUG CONFIRMED: Sign extension occurred!");
    end else if (val64 == 64'h0000_0000_8000_0001) begin
      $display("  No bug: Correct 64-bit value");
    end

    // Test 5: Parse hex address 0x80000000
    $display("\n--- Test 5: Parse hex address 0x80000000 ---");
    yaml = sv_yaml::parse("base: 0x80000000");
    assert (yaml != null) else $fatal("Failed to parse YAML");
    val32 = yaml.get("base").as_int();
    val64 = val32;  // Implicit sign extension
    $display("  as_int() result: %0d (0x%08h)", val32, val32);
    $display("  Sign-extended to 64-bit: 0x%16h", val64);
    $display("  Expected: 0x0000000080000000");
    $display("  Actual:   0x%16h", val64);
    if (val64 == 64'hFFFF_FFFF_8000_0000) begin
      $display("  BUG CONFIRMED: Sign extension occurred!");
    end else if (val64 == 64'h0000_0000_8000_0000) begin
      $display("  No bug: Correct 64-bit value");
    end

    $display("\n=== Bug Summary ===");
    $display("sv_serde's as_int() returns 32-bit signed integer.");
    $display("When value > 0x7FFFFFFF, it's sign-extended to 64-bit.");
    $display("This causes address parsing issues for SoC verification.");
    $display("\nSee docs/known_issues.md for details.");

    $finish;
  end

endmodule
