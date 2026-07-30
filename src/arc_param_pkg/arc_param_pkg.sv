package arc_param_pkg;
  typedef class arc_param_db;
  `include "arc_param/arc_param_item.svh"
  `include "arc_param/arc_param_object.svh"
  `include "arc_param/arc_param_utils.svh"
  `include "arc_param/arc_param_db.svh"
  arc_param_db ARC_PARAM_DB = arc_param_db::get();
  `include "arc_param/arc_param_macros.svh"
endpackage
