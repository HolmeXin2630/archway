// =============================================================================
// Map Package - View
// =============================================================================
// Description: Represents a memory map view (e.g., core0, core1, debug).
//              Contains regions for different targets.
// =============================================================================

`ifndef MAP_VIEW_SVH
`define MAP_VIEW_SVH

class map_view extends uvm_object;

  // -------------------------------------------------------------------------
  // Internal Storage
  // -------------------------------------------------------------------------

  // Region registry (target name -> region)
  protected map_region m_regions[string];

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // Region Management
  // -------------------------------------------------------------------------

  // Add a region to the view
  // Duplicate target: uvm_error and reject
  function void add_region(
    input string target,
    input map_addr_t base,
    input map_addr_t size
  );
    map_region region;

    if (m_regions.exists(target)) begin
      `uvm_error("MAP_VIEW",
        $sformatf("Target '%s' already exists in view '%s' - duplicate registration rejected", target, get_name()))
      return;
    end

    region = new(target);
    region.target = target;
    region.base = base;
    region.size = size;
    m_regions[target] = region;

    `uvm_info("MAP_VIEW",
      $sformatf("Region added: target='%s', base=0x%16h, size=0x%16h", target, base, size), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Region Access
  // -------------------------------------------------------------------------

  // Get region for target
  // Fatal if not found
  function void get_region(
    input  string target,
    output map_region region
  );
    if (!m_regions.exists(target)) begin
      `uvm_fatal("MAP_VIEW",
        $sformatf("Target '%s' not found in view '%s'", target, get_name()))
      region = null;
      return;
    end
    region = m_regions[target];
  endfunction

  // Check if target exists (no error if not found)
  function bit has_region(input string target);
    return m_regions.exists(target);
  endfunction

  // Get base address for target
  // Returns 0 if not found (use has_region() to check first)
  function bit get_base(
    input  string target,
    output map_addr_t base
  );
    if (!m_regions.exists(target)) begin
      base = '0;
      return 0;
    end
    base = m_regions[target].base;
    return 1;
  endfunction

  // -------------------------------------------------------------------------
  // Enumeration
  // -------------------------------------------------------------------------

  // Get all target names in this view
  function void get_target_names(ref string names[$]);
    string name;
    names.delete();
    if (m_regions.first(name)) begin
      do begin
        names.push_back(name);
      end while (m_regions.next(name));
    end
  endfunction

endclass

`endif // MAP_VIEW_SVH
