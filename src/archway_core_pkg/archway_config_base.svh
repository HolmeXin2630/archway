// =============================================================================
// Archway Core Package - Config Base Class
// =============================================================================
// Description: Base class for all Archway config objects.
//              Provides validate/freeze semantics.
// =============================================================================

`ifndef ARCHWAY_CONFIG_BASE_SVH
`define ARCHWAY_CONFIG_BASE_SVH

virtual class archway_config_base extends uvm_object;

  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  // Freeze flag - set to 1 after freeze() is called
  protected bit m_frozen = 0;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------

  function new(string name = "");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // Pure Virtual Methods
  // -------------------------------------------------------------------------

  // Validate config and append errors to the queue
  // Subclasses MUST implement this method
  pure virtual function void validate(ref string errors[$]);

  // -------------------------------------------------------------------------
  // Freeze Control
  // -------------------------------------------------------------------------

  // Freeze config - prevents further modifications
  // Subclasses can override but MUST call super.freeze()
  virtual function void freeze();
    m_frozen = 1;
  endfunction

  // Check if config is frozen
  function bit is_frozen();
    return m_frozen;
  endfunction

  // -------------------------------------------------------------------------
  // Helper Methods
  // -------------------------------------------------------------------------

  // Check if config is not frozen, fatal if it is
  // Use this in setter methods to prevent modification after freeze
  // Example:
  //   function void set_name(string name);
  //     check_not_frozen("name");
  //     m_name = name;
  //   endfunction
  function void check_not_frozen(string field_name);
    if (m_frozen) begin
      `uvm_fatal("ARCHWAY_CONFIG",
        $sformatf("Cannot modify field '%s' - config is frozen", field_name))
    end
  endfunction

endclass

`endif // ARCHWAY_CONFIG_BASE_SVH
