// =============================================================================
// Bus Package - Type Definitions
// =============================================================================
// Description: Common types for bus access.
// =============================================================================

`ifndef BUS_TYPES_SVH
`define BUS_TYPES_SVH

// Address type - 64-bit wide
typedef bit [63:0] bus_addr_t;

// Data type - 1024-bit wide (wider than most buses)
// Actual valid bytes determined by n_bytes or beat_bytes
typedef bit [1023:0] bus_data_t;

// Status enumeration
typedef enum {
  BUS_OK,            // Operation successful
  BUS_ERROR,         // General error
  BUS_UNSUPPORTED,   // Operation not supported
  BUS_TIMEOUT,       // Operation timed out
  BUS_DECODE_ERROR,  // Address decode error
  BUS_ALIGN_ERROR    // Alignment error
} bus_status_e;

// Burst kind enumeration
typedef enum {
  BUS_BURST_SINGLE,  // Single transfer
  BUS_BURST_INCR,    // Incrementing burst
  BUS_BURST_WRAP,    // Wrapping burst
  BUS_BURST_FIXED    // Fixed address burst
} bus_burst_kind_e;

`endif // BUS_TYPES_SVH
