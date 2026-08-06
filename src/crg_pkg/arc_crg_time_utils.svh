`ifndef ARC_CRG_TIME_UTILS_SVH
`define ARC_CRG_TIME_UTILS_SVH

class arc_crg_time_utils;

  static function string precision_name();
`ifdef ARC_CRG_HIGH_PRECISION
    return "1ps/1fs";
`else
    return "1ns/1ps";
`endif
  endfunction

  static function realtime timeunits_per_second();
`ifdef ARC_CRG_HIGH_PRECISION
    return 1.0e12;
`else
    return 1.0e9;
`endif
  endfunction

  static function bit try_time_to_delay(
    input  string   text,
    output realtime delay
  );
    real magnitude;
    real multiplier;
    string suffix;
    int fields;

    delay = 0.0;
    fields = $sscanf(text, "%f%s", magnitude, suffix);
    if (fields != 2 || magnitude < 0.0)
      return 0;

    suffix = suffix.tolower();
    case (suffix)
      "fs": multiplier = 1.0e-15;
      "ps": multiplier = 1.0e-12;
      "ns": multiplier = 1.0e-9;
      "us": multiplier = 1.0e-6;
      "ms": multiplier = 1.0e-3;
      "s":  multiplier = 1.0;
      default: return 0;
    endcase

    delay = magnitude * multiplier * timeunits_per_second();
    return 1;
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
