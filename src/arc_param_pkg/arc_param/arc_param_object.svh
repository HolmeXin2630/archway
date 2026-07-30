class arc_param_object;
  protected string m_name;

  function new(string name = "");
    m_name = name;
  endfunction

  function string get_name();
    return m_name;
  endfunction

  virtual function bit apply_arc_param(string path, string value);
    return 0;
  endfunction

  extern function void load_arc_param();
endclass
