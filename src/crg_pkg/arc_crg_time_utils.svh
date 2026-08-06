`ifndef ARC_CRG_TIME_UTILS_SVH
`define ARC_CRG_TIME_UTILS_SVH

class arc_crg_time_utils;

  protected static function realtime timeunits_per_second();
`ifdef ARC_CRG_HIGH_PRECISION
    return 1.0e12;
`else
    return 1.0e9;
`endif
  endfunction

  static function bit try_frequency_to_period(
    input  string   text,
    output realtime period
  );
    real magnitude;
    real multiplier;
    string suffix;
    int fields;

    period = 0.0;
    fields = $sscanf(text, "%f%s", magnitude, suffix);
    if (fields != 2 || magnitude <= 0.0)
      return 0;

    suffix = suffix.tolower();
    case (suffix)
      "hz":          multiplier = 1.0;
      "k", "khz": multiplier = 1.0e3;
      "m", "mhz": multiplier = 1.0e6;
      "g", "ghz": multiplier = 1.0e9;
      default:       return 0;
    endcase

    period = timeunits_per_second() / (magnitude * multiplier);
    return period > 0.0;
  endfunction

endclass

`endif // ARC_CRG_TIME_UTILS_SVH
