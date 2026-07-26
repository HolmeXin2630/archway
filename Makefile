# =============================================================================
# Archway Framework Makefile
# =============================================================================

# Simulator selection (vcs, xcelium, questa, vlog)
SIM ?= vcs

# Source directories
SRC_DIR = src
TB_DIR = tb

# Package name
PKG = archway_core_pkg

# Test name
TEST = test_archway_config_base

# =============================================================================
# Simulator-specific settings
# =============================================================================

ifeq ($(SIM),vcs)
  UVM_HOME = /opt/synopsys/vcs/W-2024.09/etc/uvm-1.2
  VCS_HOME = /opt/synopsys/vcs/W-2024.09
  COMPILE = vcs
  COMPILE_OPTS = -full64 -sverilog -timescale=1ns/1ps \
                 -ntb_opts uvm-1.2
  RUN = ./simv
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),xcelium)
  COMPILE = xrun
  COMPILE_OPTS = -uvm -sv -timescale+1ns/1ps
  RUN = xrun
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),questa)
  COMPILE = vlog
  COMPILE_OPTS = -sv +incdir+$(SRC_DIR)/$(PKG)
  RUN = vsim
  RUN_OPTS = -c -do "run -all"
else
  # Default to vcs
  COMPILE = vcs
  COMPILE_OPTS = -full64 -sverilog -uvm -timescale=1ns/1ps
  RUN = ./simv
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
endif

# =============================================================================
# Targets
# =============================================================================

.PHONY: all compile run clean help

all: compile run

compile:
	@echo "=== Compiling $(PKG) ==="
	$(COMPILE) $(COMPILE_OPTS) \
		+incdir+$(SRC_DIR)/$(PKG) \
		$(SRC_DIR)/$(PKG)/$(PKG).sv \
		$(TB_DIR)/$(PKG)/$(TEST).sv \
		-o simv_$(PKG)

run: compile
	@echo "=== Running $(TEST) ==="
	./simv_$(PKG) $(RUN_OPTS)

clean:
	rm -rf simv_* csrc *.vpd *.fsdb *.trn *.dsn *.log *.history

help:
	@echo "Usage:"
	@echo "  make compile  - Compile the package and test"
	@echo "  make run      - Run the test"
	@echo "  make all      - Compile and run"
	@echo "  make clean    - Remove generated files"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<simulator>  - Set simulator (vcs, xcelium, questa)"
	@echo "  TEST=<test>      - Set test name"
