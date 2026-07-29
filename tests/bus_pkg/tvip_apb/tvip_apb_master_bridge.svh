// =============================================================================
// tvip-apb Master Bridge
// =============================================================================
// Description: Concrete implementation of bus_master_handle that delegates
//              bus access to a tvip-apb master sequencer.
// =============================================================================

`ifndef TVIP_APB_MASTER_BRIDGE_SVH
`define TVIP_APB_MASTER_BRIDGE_SVH

// Internal sequence to send a single APB transaction
class tvip_apb_bridge_seq extends uvm_sequence #(tvip_apb_master_item);

  tvip_apb_master_item  item;

  `uvm_object_utils(tvip_apb_bridge_seq)

  function new(string name = "");
    super.new(name);
  endfunction

  task body();
    start_item(item);
    finish_item(item);
  endtask

endclass

// Bridge class
class tvip_apb_master_bridge extends bus_master_handle;

  protected tvip_apb_master_sequencer  m_sequencer;

  `uvm_object_utils(tvip_apb_master_bridge)

  function new(
    string                        name = "",
    tvip_apb_master_sequencer     sqr  = null
  );
    super.new(name);
    m_sequencer  = sqr;
  endfunction

  // -------------------------------------------------------------------------
  // Check Interface
  // -------------------------------------------------------------------------

  virtual task try_write(
    output bus_status_e   status,
    input  bus_addr_t     addr,
    input  bus_data_t     data,
    input  int unsigned   n_bytes = 0
  );
    tvip_apb_bridge_seq  seq;
    tvip_apb_master_item item;

    item            = tvip_apb_master_item::type_id::create("item");
    item.direction  = TVIP_APB_WRITE;
    item.address    = tvip_apb_address'(addr);
    item.data       = tvip_apb_data'(data);
    item.strobe     = '1;

    seq       = tvip_apb_bridge_seq::type_id::create("seq");
    seq.item  = item;
    seq.start(m_sequencer);

    if (item.slave_error) begin
      status = BUS_ERROR;
    end else begin
      status = BUS_OK;
    end
  endtask

  virtual task try_read(
    output bus_status_e   status,
    input  bus_addr_t     addr,
    output bus_data_t     data,
    input  int unsigned   n_bytes = 0
  );
    tvip_apb_bridge_seq  seq;
    tvip_apb_master_item item;

    item            = tvip_apb_master_item::type_id::create("item");
    item.direction  = TVIP_APB_READ;
    item.address    = tvip_apb_address'(addr);

    seq       = tvip_apb_bridge_seq::type_id::create("seq");
    seq.item  = item;
    seq.start(m_sequencer);

    data = '0;
    data = bus_data_t'(item.data);

    if (item.slave_error) begin
      status = BUS_ERROR;
    end else begin
      status = BUS_OK;
    end
  endtask

  // -------------------------------------------------------------------------
  // Burst Interface - not supported by APB
  // -------------------------------------------------------------------------

  virtual task try_burst_write(
    output bus_status_e         status,
    input  bus_addr_t           addr,
    input  bus_data_t           data[],
    input  int unsigned         beat_bytes = 0,
    input  bus_burst_kind_e     burst_kind = BUS_BURST_INCR
  );
    status = BUS_UNSUPPORTED;
    `uvm_warning("TVIP_APB_BRIDGE",
      "Burst write not supported by APB backend")
  endtask

  virtual task try_burst_read(
    output bus_status_e         status,
    input  bus_addr_t           addr,
    output bus_data_t           data[],
    input  int unsigned         num_beats,
    input  int unsigned         beat_bytes = 0,
    input  bus_burst_kind_e     burst_kind = BUS_BURST_INCR
  );
    data   = new[num_beats];
    status = BUS_UNSUPPORTED;
    `uvm_warning("TVIP_APB_BRIDGE",
      "Burst read not supported by APB backend")
  endtask

endclass

`endif // TVIP_APB_MASTER_BRIDGE_SVH
