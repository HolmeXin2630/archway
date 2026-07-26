// =============================================================================
// Bus Package
// =============================================================================
// Description: Bus access package for Archway framework.
//              Provides BUS Facade and bus_master_handle for bus access.
// =============================================================================

package bus_pkg;

  // Import UVM and dependencies
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include bus types and classes
  `include "bus_types.svh"
  `include "bus_master_handle.svh"
  `include "bus_facade.svh"

endpackage
