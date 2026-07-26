// =============================================================================
// Map Package - Region
// =============================================================================
// Description: Represents a memory region with target, base, and size.
// =============================================================================

`ifndef MAP_REGION_SVH
`define MAP_REGION_SVH

class map_region extends uvm_object;

  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  // Target name (e.g., "uart0", "spi0")
  string target;

  // Base address
  map_addr_t base;

  // Region size
  map_addr_t size;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "");
    super.new(name);
    target = "";
    base = '0;
    size = '0;
  endfunction

  // -------------------------------------------------------------------------
  // Utility Methods
  // -------------------------------------------------------------------------

  // Get end address (base + size)
  function map_addr_t get_end();
    return base + size;
  endfunction

  // Check if address is within region
  function bit is_in_region(map_addr_t addr);
    return (addr >= base) && (addr < get_end());
  endfunction

endclass

`endif // MAP_REGION_SVH
