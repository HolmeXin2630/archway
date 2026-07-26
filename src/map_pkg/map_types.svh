// =============================================================================
// Map Package - Type Definitions
// =============================================================================
// Description: Common types for memory map access.
// =============================================================================

`ifndef MAP_TYPES_SVH
`define MAP_TYPES_SVH

// Address type - 64-bit wide
typedef bit [63:0] map_addr_t;

// Status enumeration
typedef enum {
  MAP_OK,          // Operation successful
  MAP_NO_VIEW,     // View not found
  MAP_NO_TARGET,   // Target not found in view
  MAP_OVERLAP,     // Region overlap detected
  MAP_ERROR        // General error
} map_status_e;

`endif // MAP_TYPES_SVH
