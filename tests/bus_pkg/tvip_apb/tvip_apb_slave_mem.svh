// =============================================================================
// tvip-apb Slave Memory Model
// =============================================================================
// Description: Simple APB slave that responds with read/write to memory.
//              Uses slave_cb clocking block from tvip_apb_if.
// =============================================================================

`ifndef TVIP_APB_SLAVE_MEM_SVH
`define TVIP_APB_SLAVE_MEM_SVH

class tvip_apb_slave_mem extends uvm_component;

  tvip_apb_vif  vif;
  int           data_width;

  protected bit [31:0]  m_memory[bit [31:0]];

  `uvm_component_utils(tvip_apb_slave_mem)

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(vif.slave_cb);
      vif.slave_cb.pready  <= '0;
      vif.slave_cb.prdata  <= '0;
      vif.slave_cb.pslverr <= '0;

      if (vif.slave_cb.psel && !vif.slave_cb.penable) begin
        // Setup phase: wait for access phase
        @(vif.slave_cb);
        if (vif.slave_cb.psel && vif.slave_cb.penable) begin
          // Access phase: respond
          vif.slave_cb.pready <= '1;
          if (vif.slave_cb.pwrite) begin
            m_memory[vif.slave_cb.paddr] = vif.slave_cb.pwdata;
          end else begin
            if (m_memory.exists(vif.slave_cb.paddr)) begin
              vif.slave_cb.prdata <= m_memory[vif.slave_cb.paddr];
            end else begin
              vif.slave_cb.prdata <= '0;
            end
          end
        end
      end
    end
  endtask

endclass

`endif // TVIP_APB_SLAVE_MEM_SVH
