// =============================================================================
// Archway Package - Config Loader
// =============================================================================
// Description: YAML configuration loader for Archway framework.
//              Uses sv_serde library for YAML parsing.
// =============================================================================

`ifndef CONFIG_LOADER_SVH
`define CONFIG_LOADER_SVH

class config_loader;

  // -------------------------------------------------------------------------
  // Map Configuration Loading
  // -------------------------------------------------------------------------

  // Load map configuration from YAML file
  // Returns 1 on success, 0 on failure
  static function bit load_map_config(
    input string yaml_path,
    output map_view views[string]
  );
    sv_yaml yaml;
    sv_yaml views_node, view_node, regions_node, region_node;
    string view_name, target_name;
    map_view view;
    map_addr_t base, size;

    `uvm_info("CONFIG_LOADER",
      $sformatf("Loading map config from: %s", yaml_path), UVM_MEDIUM)

    // Parse YAML file
    yaml = sv_yaml::parse_file(yaml_path);
    if (yaml == null || !yaml.is_valid()) begin
      `uvm_error("CONFIG_LOADER",
        $sformatf("Failed to parse YAML file: %s", yaml_path))
      return 0;
    end

    // Check if 'views' key exists
    if (!yaml.contains("views")) begin
      `uvm_error("CONFIG_LOADER",
        $sformatf("YAML file missing 'views' key: %s", yaml_path))
      return 0;
    end

    // Get views node
    views_node = yaml.get("views");
    if (!views_node.is_object()) begin
      `uvm_error("CONFIG_LOADER",
        $sformatf("'views' is not an object in: %s", yaml_path))
      return 0;
    end

    // Iterate through views
    for (int i = 0; i < views_node.size(); i++) begin
      view_name = views_node.key_at(i);
      view_node = views_node.get(view_name);
      view = new(view_name);

      // Get regions for this view
      if (view_node.contains("regions")) begin
        regions_node = view_node.get("regions");
        if (regions_node.is_object()) begin
          // Iterate through regions
          for (int j = 0; j < regions_node.size(); j++) begin
            target_name = regions_node.key_at(j);
            region_node = regions_node.get(target_name);

            // Extract base and size
            if (region_node.contains("base") && region_node.contains("size")) begin
              base = region_node.get("base").as_int();
              size = region_node.get("size").as_int();
              view.add_region(target_name, base, size);
            end else begin
              `uvm_warning("CONFIG_LOADER",
                $sformatf("Region '%s' missing base or size in view '%s'", target_name, view_name))
            end
          end
        end
      end

      views[view_name] = view;
      `uvm_info("CONFIG_LOADER",
        $sformatf("Loaded view '%s'", view_name), UVM_MEDIUM)
    end

    return 1;
  endfunction

  // -------------------------------------------------------------------------
  // Bus Configuration Loading
  // -------------------------------------------------------------------------

  // Load bus configuration from YAML file
  // Returns 1 on success, 0 on failure
  static function bit load_bus_config(
    input string yaml_path,
    output string masters[$],
    output string slaves[$]
  );
    sv_yaml yaml;
    sv_yaml masters_node, slaves_node;

    `uvm_info("CONFIG_LOADER",
      $sformatf("Loading bus config from: %s", yaml_path), UVM_MEDIUM)

    // Parse YAML file
    yaml = sv_yaml::parse_file(yaml_path);
    if (yaml == null || !yaml.is_valid()) begin
      `uvm_error("CONFIG_LOADER",
        $sformatf("Failed to parse YAML file: %s", yaml_path))
      return 0;
    end

    // Load masters
    if (yaml.contains("masters")) begin
      masters_node = yaml.get("masters");
      if (masters_node.is_array()) begin
        for (int i = 0; i < masters_node.size(); i++) begin
          masters.push_back(masters_node.at(i).as_string());
        end
      end
    end

    // Load slaves
    if (yaml.contains("slaves")) begin
      slaves_node = yaml.get("slaves");
      if (slaves_node.is_array()) begin
        for (int i = 0; i < slaves_node.size(); i++) begin
          slaves.push_back(slaves_node.at(i).as_string());
        end
      end
    end

    `uvm_info("CONFIG_LOADER",
      $sformatf("Loaded %0d masters, %0d slaves", masters.size(), slaves.size()), UVM_MEDIUM)

    return 1;
  endfunction

endclass

`endif // CONFIG_LOADER_SVH
