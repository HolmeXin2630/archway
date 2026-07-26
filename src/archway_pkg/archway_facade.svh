// =============================================================================
// Archway Package - ARCHWAY Facade
// =============================================================================
// Description: Static facade for framework-level resource access.
//              Provides registration, query, and access to archway_env instances.
// =============================================================================

`ifndef ARCHWAY_FACADE_SVH
`define ARCHWAY_FACADE_SVH

class ARCHWAY;

  // -------------------------------------------------------------------------
  // Internal Storage
  // -------------------------------------------------------------------------

  // Environment registry (name -> env)
  protected static archway_env m_envs[string];

  // -------------------------------------------------------------------------
  // Environment Registration
  // -------------------------------------------------------------------------

  // Register an environment
  // Duplicate registration: uvm_error and reject
  static function void register_env(string name, archway_env env);
    if (m_envs.exists(name)) begin
      `uvm_error("ARCHWAY_REGISTER",
        $sformatf("Env '%s' already registered - duplicate registration rejected", name))
      return;
    end
    m_envs[name] = env;
    `uvm_info("ARCHWAY_REGISTER",
      $sformatf("Env '%s' registered", name), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Environment Access
  // -------------------------------------------------------------------------

  // Check if env exists (no error if not found)
  static function bit has_env(string name);
    return m_envs.exists(name);
  endfunction

  // Get env
  // Fatal if not found
  static function archway_env get_env(string name);
    if (!m_envs.exists(name)) begin
      `uvm_fatal("ARCHWAY_ENV",
        $sformatf("Env '%s' not found - has it been registered?", name))
      return null;
    end
    return m_envs[name];
  endfunction

  // Remove env registration
  // Does not destroy the object, only removes registration
  static function void remove_env(string name);
    if (!m_envs.exists(name)) begin
      `uvm_warning("ARCHWAY_REMOVE",
        $sformatf("Env '%s' not found - nothing to remove", name))
      return;
    end
    m_envs.delete(name);
    `uvm_info("ARCHWAY_REMOVE",
      $sformatf("Env '%s' removed", name), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  // Enumeration
  // -------------------------------------------------------------------------

  // Get all registered env names
  static function void get_env_names(ref string names[$]);
    string name;
    names.delete();
    if (m_envs.first(name)) begin
      do begin
        names.push_back(name);
      end while (m_envs.next(name));
    end
  endfunction

  // -------------------------------------------------------------------------
  // Resource Queries
  // -------------------------------------------------------------------------

  // Check if a resource exists in any registered env
  // In v1, this is a placeholder for future resource queries
  static function bit has(string resource_name);
    // Simplified implementation for v1
    return 0;
  endfunction

endclass

`endif // ARCHWAY_FACADE_SVH
