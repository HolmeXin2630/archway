# =============================================================================
# Archway Framework Makefile
# =============================================================================

# Simulator selection (vcs, xcelium, questa)
SIM ?= vcs

# Source directories
SRC_DIR = src
TB_DIR = tb

# Package name (archway_core_pkg, bus_pkg, map_pkg, archway_pkg)
PKG ?= archway_pkg

# Test name (test_archway_config_base, test_bus_pkg, test_map_pkg, test_archway_pkg, test_archway_yaml)
TEST ?= test_archway_yaml

# =============================================================================
# sv_serde library paths (managed by west)
# =============================================================================
# West workspace root is parent directory, so use ../lib
SERDE_DIR = ../lib/sv_serde/sv_serde/src
YAML_DIR = ../lib/sv_serde/sv_yaml/src

# SystemVerilog packages
SERDE_PKG = $(SERDE_DIR)/sv_serde_pkg.sv
YAML_PKG = $(YAML_DIR)/sv_yaml_pkg.sv

# DPI C++ sources
SERDE_DPI = $(SERDE_DIR)/dpi/serde_common.cc
YAML_DPI = $(YAML_DIR)/dpi/sv_yaml_dpi.cc

# CFLAGS for DPI compilation
YAML_CFLAGS = -std=c++14 -I$(abspath $(YAML_DIR)/dpi) -I$(abspath $(SERDE_DIR)/dpi)

# =============================================================================
# Archway packages
# =============================================================================
ARCHWAY_CORE_PKG = $(SRC_DIR)/archway_core_pkg/archway_core_pkg.sv
BUS_PKG = $(SRC_DIR)/bus_pkg/bus_pkg.sv
MAP_PKG = $(SRC_DIR)/map_pkg/map_pkg.sv
ARCHWAY_PKG = $(SRC_DIR)/archway_pkg/archway_pkg.sv

# All SV source files
SV_FILES = $(SERDE_PKG) $(YAML_PKG) $(ARCHWAY_CORE_PKG) $(BUS_PKG) $(MAP_PKG) $(ARCHWAY_PKG)

# DPI C++ source files
DPI_FILES = $(YAML_DPI) $(SERDE_DPI)

# =============================================================================
# Simulator-specific settings
# =============================================================================

ifeq ($(SIM),vcs)
  UVM_HOME = /opt/synopsys/vcs/W-2024.09/etc/uvm-1.2
  VCS = vcs
  VCS_FLAGS = -sverilog -full64 -ntb_opts uvm-1.2 \
              +incdir+$(abspath $(SRC_DIR)/archway_core_pkg) \
              +incdir+$(abspath $(SRC_DIR)/bus_pkg) \
              +incdir+$(abspath $(SRC_DIR)/map_pkg) \
              +incdir+$(abspath $(SRC_DIR)/archway_pkg) \
              +incdir+$(abspath $(SERDE_DIR)) \
              +incdir+$(abspath $(YAML_DIR))
  RUN = ./simv_$(PKG)
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),xcelium)
  VCS = xrun
  VCS_FLAGS = -uvm -sv -timescale+1ns/1ps
  RUN = xrun
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),questa)
  VCS = vlog
  VCS_FLAGS = -sv +incdir+$(SRC_DIR)/$(PKG)
  RUN = vsim
  RUN_OPTS = -c -do "run -all"
endif

# =============================================================================
# Targets
# =============================================================================

.PHONY: all compile run clean help

all: compile run

compile:
	@echo "=== Compiling $(PKG) ==="
	$(VCS) $(VCS_FLAGS) -CFLAGS "$(YAML_CFLAGS)" \
		$(SV_FILES) \
		$(TB_DIR)/$(PKG)/$(TEST).sv \
		$(DPI_FILES) \
		-top $(TEST) \
		-o simv_$(PKG) \
		-l vcs_$(PKG).log

run: compile
	@echo "=== Running $(TEST) ==="
	./simv_$(PKG) $(RUN_OPTS)

clean:
	rm -rf simv_* csrc *.vpd *.fsdb *.trn *.dsn *.log *.history *.daidir DVEfiles AN.DB

help:
	@echo "Usage:"
	@echo "  make compile  - Compile the package and test"
	@echo "  make run      - Run the test"
	@echo "  make all      - Compile and run"
	@echo "  make clean    - Remove generated files"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<simulator>  - Set simulator (vcs, xcelium, questa)"
	@echo "  PKG=<package>    - Set package name"
	@echo "  TEST=<test>      - Set test name"
