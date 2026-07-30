virtual class arc_param_config;
  protected string m_param_path;

  function new(string param_path = "");
    m_param_path = param_path;
  endfunction

  function string get_param_path();
    return m_param_path;
  endfunction

  function void bind_param_path(string param_path);
    if (m_param_path.len() == 0) begin
      m_param_path = param_path;
    end else if (m_param_path != param_path) begin
      ARC_PARAM_DB.report_error($sformatf(
        "config path rebind rejected: '%s' -> '%s'", m_param_path, param_path
      ));
    end
  endfunction

  function void post_randomize();
    ARC_PARAM_DB.load_tc_param(this);
  endfunction

  virtual function arc_param_apply_result_e apply_arc_param(string path, string value);
    return ARC_PARAM_NOT_MATCHED;
  endfunction
endclass
