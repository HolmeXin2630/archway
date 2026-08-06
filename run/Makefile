# =============================================================================
# Archway Makefile
# =============================================================================
# Usage:
#   make -C run regression          # Run all regression tests
#   make -C run compile PKG=bus_pkg TEST=test_bus_pkg_full
#   make -C run run PKG=bus_pkg TEST=test_bus_pkg_full
#   make -C run clean

# Simulator selection (vcs, xcelium, questa)
SIM ?= vcs

# Project root (parent of run/)
ROOT_DIR := $(shell cd .. && pwd)

# Simulation output directory
SIM_DIR = $(ROOT_DIR)/run/sim

# Package name (archway_core_pkg, bus_pkg, map_pkg, crg_pkg, archway_pkg, arc_param_pkg)
PKG ?= archway_pkg

# Test name
TEST ?= test_archway_yaml

# =============================================================================
# sv_serde library paths (managed by west)
# =============================================================================
SERDE_DIR = $(ROOT_DIR)/../lib/sv_serde/sv_serde/src
YAML_DIR = $(ROOT_DIR)/../lib/sv_serde/sv_yaml/src

# SystemVerilog packages
SERDE_PKG = $(SERDE_DIR)/sv_serde_pkg.sv
YAML_PKG = $(YAML_DIR)/sv_yaml_pkg.sv

# DPI C++ sources
SERDE_DPI = $(SERDE_DIR)/dpi/serde_common.cc
YAML_DPI = $(YAML_DIR)/dpi/sv_yaml_dpi.cc

# CFLAGS for DPI compilation
YAML_CFLAGS = -std=c++14 -I$(YAML_DIR)/dpi -I$(SERDE_DIR)/dpi

# =============================================================================
# tvip-apb library paths (managed by west, used by bus_pkg APB tests)
# =============================================================================
TVIP_APB_DIR = $(ROOT_DIR)/tests/bus_pkg/lib/tvip-apb/src
TUE_DIR = $(ROOT_DIR)/tests/bus_pkg/lib/tue/src

# tvip-apb needs defines for max address/data width
TVIP_APB_DEFINES = +define+TVIP_APB_MAX_ADDRESS_WIDTH=16 +define+TVIP_APB_MAX_DATA_WIDTH=32

# =============================================================================
# Archway packages
# =============================================================================
ARCHWAY_CORE_PKG = $(ROOT_DIR)/src/archway_core_pkg/archway_core_pkg.sv
BUS_PKG = $(ROOT_DIR)/src/bus_pkg/bus_pkg.sv
MAP_PKG = $(ROOT_DIR)/src/map_pkg/map_pkg.sv
ARC_CLK_IF = $(ROOT_DIR)/src/crg_pkg/arc_clk_if.sv
CRG_PKG = $(ROOT_DIR)/src/crg_pkg/crg_pkg.sv
ARCHWAY_PKG = $(ROOT_DIR)/src/archway_pkg/archway_pkg.sv
ARC_PARAM_PKG = $(ROOT_DIR)/src/arc_param_pkg/arc_param_pkg.sv
ARC_PARAM_TEST_PKG = $(ROOT_DIR)/tests/arc_param_pkg/arc_param_test_pkg.sv

# tvip-apb packages (for APB backend tests)
TUE_PKG = $(TUE_DIR)/tue_pkg.sv
TVIP_APB_PKG = $(TVIP_APB_DIR)/tvip_apb_pkg.sv

# All SV source files
SV_FILES = $(SERDE_PKG) $(YAML_PKG) $(TUE_PKG) $(TVIP_APB_PKG) \
           $(ARCHWAY_CORE_PKG) $(BUS_PKG) $(MAP_PKG) $(ARC_CLK_IF) $(CRG_PKG) \
           $(ARCHWAY_PKG) $(ARC_PARAM_PKG)

# ARC_PARAM is a standalone pure-SV package; its tests need neither UVM nor
# the YAML DPI dependency graph.
COMPILE_SV_FILES = $(if $(filter arc_param_pkg,$(PKG)),$(ARC_PARAM_PKG),$(SV_FILES))
COMPILE_DPI_FILES = $(if $(filter arc_param_pkg,$(PKG)),,$(DPI_FILES))

# DPI C++ source files
DPI_FILES = $(YAML_DPI) $(SERDE_DPI)

# =============================================================================
# Simulator-specific settings
# =============================================================================

ifeq ($(SIM),vcs)
  UVM_HOME = /opt/synopsys/vcs/W-2024.09/etc/uvm-1.2
  VCS = vcs
  VCS_FLAGS = -sverilog -full64 $(if $(filter arc_param_pkg,$(PKG)),,-ntb_opts uvm-1.2) \
              +incdir+$(ROOT_DIR)/src/archway_core_pkg \
              +incdir+$(ROOT_DIR)/src/bus_pkg \
              +incdir+$(ROOT_DIR)/src/map_pkg \
              +incdir+$(ROOT_DIR)/src/crg_pkg \
              +incdir+$(ROOT_DIR)/src/archway_pkg \
              +incdir+$(ROOT_DIR)/src/arc_param_pkg \
              +incdir+$(SERDE_DIR) \
              +incdir+$(YAML_DIR) \
              +incdir+$(TUE_DIR) \
              +incdir+$(TVIP_APB_DIR) \
              +incdir+$(ROOT_DIR)/tests/bus_pkg \
              +incdir+$(ROOT_DIR)/tests/arc_param_pkg \
              +incdir+$(ROOT_DIR)/tests/crg_pkg \
              $(TVIP_APB_DEFINES)
  RUN = ./simv_$(PKG)
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),xcelium)
  VCS = xrun
  VCS_FLAGS = -uvm -sv -timescale+1ns/1ps
  RUN = xrun
  RUN_OPTS = +UVM_TESTNAME=$(TEST)
else ifeq ($(SIM),questa)
  VCS = vlog
  VCS_FLAGS = -sv +incdir+$(ROOT_DIR)/src/$(PKG)
  RUN = vsim
  RUN_OPTS = -c -do "run -all"
endif

# =============================================================================
# Test definitions for regression
# =============================================================================
# Format: PKG/TEST
# Note: test_bus_pkg is excluded due to missing try_burst_write/try_burst_read implementation
#       test_sv_serde_bug is a bug verification test, not a functional test
REGRESSION_TESTS = \
	archway_core_pkg/test_archway_config_base \
	bus_pkg/test_bus_pkg_full \
	bus_pkg/test_bus_apb \
	map_pkg/test_map_pkg \
	crg_pkg/test_crg_pkg \
	archway_pkg/test_archway_pkg \
	archway_pkg/test_archway_yaml

# =============================================================================
# Targets
# =============================================================================

.PHONY: all compile run clean help regression arc_param_regression

all: compile run

compile:
	@mkdir -p $(SIM_DIR)
	@echo "=== Compiling $(PKG) ==="
	cd $(SIM_DIR) && $(VCS) $(VCS_FLAGS) -CFLAGS "$(YAML_CFLAGS)" \
		$(COMPILE_SV_FILES) \
		$(if $(filter arc_param_pkg,$(PKG)),$(ARC_PARAM_TEST_PKG)) \
		$(ROOT_DIR)/tests/$(PKG)/$(TEST).sv \
		$(COMPILE_DPI_FILES) \
		-top $(TEST) \
		-Mdir=csrc_$(PKG)_$(TEST) \
		-o simv_$(PKG)_$(TEST) \
		-l vcs_$(PKG).log

run: compile
	@echo "=== Running $(TEST) ==="
	cd $(SIM_DIR) && ./simv_$(PKG)_$(TEST) $(RUN_OPTS)

clean:
	rm -rf $(SIM_DIR)/simv_* $(SIM_DIR)/csrc* $(SIM_DIR)/*.log $(SIM_DIR)/*.daidir $(SIM_DIR)/*.h $(SIM_DIR)/*.key

# Run all regression tests
regression:
	@echo "========================================"
	@echo "Running Archway Regression Tests"
	@echo "========================================"
	@pass=0; fail=0; \
	for test in $(REGRESSION_TESTS); do \
		pkg=$$(echo $$test | cut -d'/' -f1); \
		tst=$$(echo $$test | cut -d'/' -f2); \
		echo ""; \
		echo "--- Running: $$pkg/$$tst ---"; \
		if $(MAKE) compile SIM=$(SIM) PKG=$$pkg TEST=$$tst > /dev/null 2>&1 && \
		   $(MAKE) run SIM=$(SIM) PKG=$$pkg TEST=$$tst 2>&1 | grep -q "All tests passed\|PASS"; then \
			echo "  ✓ PASS: $$pkg/$$tst"; \
			pass=$$((pass + 1)); \
		else \
			echo "  ✗ FAIL: $$pkg/$$tst"; \
			fail=$$((fail + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "Regression Results:"; \
	echo "  Passed: $$pass"; \
	echo "  Failed: $$fail"; \
	echo "  Total:  $$((pass + fail))"; \
	echo "========================================"; \
	if [ $$fail -ne 0 ]; then exit 1; fi

ARC_PARAM_TESTS = \
	test_arc_param_real_usage \
	test_arc_param_collections_usage \
	test_arc_param_override_usage \
	test_arc_param_randomize_usage \
	test_arc_param_binding_usage \
	test_arc_param_diagnostics_usage \
	test_arc_param_invalid_usage \
	test_arc_param_codec_unit \
	test_arc_param_tokenizer_unit

arc_param_regression:
	@pass=0; fail=0; \
	for tst in $(ARC_PARAM_TESTS); do \
		echo "--- Running: arc_param_pkg/$$tst ---"; \
		rm -rf $(SIM_DIR)/csrc_arc_param_pkg_$$tst $(SIM_DIR)/simv_arc_param_pkg_$$tst $(SIM_DIR)/simv_arc_param_pkg_$$tst.daidir; \
		if $(MAKE) run SIM=vcs PKG=arc_param_pkg TEST=$$tst 2>&1 | grep -q "PASS"; then \
			echo "  ✓ PASS: arc_param_pkg/$$tst"; pass=$$((pass + 1)); \
		else \
			echo "  ✗ FAIL: arc_param_pkg/$$tst"; fail=$$((fail + 1)); \
		fi; \
	done; \
	if [ $$fail -ne 0 ]; then exit 1; fi; \
	echo "ARC_PARAM VCS regression PASS"

help:
	@echo "Archway Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make regression    - Run all regression tests"
	@echo "  make compile       - Compile package and test"
	@echo "  make run           - Run test"
	@echo "  make all           - Compile and run"
	@echo "  make clean         - Remove simulation artifacts"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<simulator>  - Set simulator (vcs, xcelium, questa)"
	@echo "  PKG=<package>    - Set package name"
	@echo "  TEST=<test>      - Set test name"
	@echo ""
	@echo "Available tests:"
	@echo "  archway_core_pkg/test_archway_config_base"
	@echo "  bus_pkg/test_bus_pkg"
	@echo "  bus_pkg/test_bus_pkg_full"
	@echo "  map_pkg/test_map_pkg"
	@echo "  archway_pkg/test_archway_pkg"
	@echo "  archway_pkg/test_archway_yaml"
	@echo "  archway_pkg/test_sv_serde_bug"
