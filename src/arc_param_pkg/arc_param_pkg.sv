package arc_param_pkg;
  typedef class arc_param_db;

  typedef enum {
    ARC_PARAM_NOT_MATCHED,
    ARC_PARAM_APPLIED,
    ARC_PARAM_INVALID_VALUE
  } arc_param_apply_result_e;

  `include "arc_param/arc_param_item.svh"
  `include "arc_param/arc_param_config.svh"
  `include "arc_param/arc_param_utils.svh"
  `include "arc_param/arc_param_db.svh"
  arc_param_db ARC_PARAM_DB = arc_param_db::get();
  `include "arc_param/arc_param_macros.svh"
endpackage
