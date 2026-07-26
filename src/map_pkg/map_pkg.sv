// =============================================================================
// Map Package
// =============================================================================
// Description: Memory map package for Archway framework.
//              Provides MAP Facade, map_view, and map_region for memory map access.
// =============================================================================

package map_pkg;

  // Import UVM and dependencies
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include map types and classes
  `include "map_types.svh"
  `include "map_region.svh"
  `include "map_view.svh"
  `include "map_facade.svh"

endpackage
