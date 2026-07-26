// =============================================================================
// Archway Package
// =============================================================================
// Description: Framework top-level assembly package for Archway.
//              Provides archway_env base class and ARCHWAY Facade.
// =============================================================================

package archway_pkg;

  // Import UVM and dependencies
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import dependent packages
  import bus_pkg::*;
  import map_pkg::*;

  // Include archway components
  `include "archway_env.svh"
  `include "archway_facade.svh"

endpackage
