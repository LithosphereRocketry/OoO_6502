# Source directories
TOOLS_DIR = tools

RTL_DIR = rtl
RTL_CPU_DIR = $(RTL_DIR)/cpu
RTL_SUPPORT_DIR = $(RTL_DIR)/support

TEST_DIR = tests
VL_TEST_DIR = $(TEST_DIR)/verilog

# Output directories
ROM_DIR = rom
VVP_DIR = vvp
WAVE_DIR = waveforms

DIRS = $(ROM_DIR) $(VVP_DIR) $(WAVE_DIR)

# Verilog common source files
VL_SOURCE_CPU = $(wildcard $(RTL_CPU_DIR)/*.v)
VL_SOURCE_SUPPORT = $(wildcard $(RTL_SUPPORT_DIR)/*.v)
VL_SOURCE_MAIN = $(VL_SOURCE_CPU) $(VL_SOURCE_SUPPORT)

# Verilog module unit tests
VL_TEST_SRCS = $(wildcard $(VL_TEST_DIR)/*.v)
VL_TEST_TGTS = $(VL_TEST_SRCS:$(VL_TEST_DIR)/%.v=vl_test_%)
VL_TEST_ADDL = $(ROM_DIR)/hash.hex

.PHONY: test test-vl $(VL_TEST_TGTS)
.DEFAULT_GOAL: test

test: test-vl

test-vl: $(VL_TEST_TGTS)

$(VL_TEST_TGTS): vl_test_%: $(VVP_DIR)/%.vvp | $(WAVE_DIR)
	vvp $< -fst

# There can be multiple rules targeting one target, and the makefile will pick
# the first one that works
$(VVP_DIR)/%.vvp: $(VL_TEST_DIR)/%.v $(VL_SOURCE_MAIN) $(VL_TEST_ADDL) | $(VVP_DIR)
	iverilog -DWAVEPATH=\"$(WAVE_DIR)/$*.fst\" -s $* -o $@ $< $(VL_SOURCE_MAIN) 

$(ROM_DIR)/hash.hex: $(TOOLS_DIR)/romfuzz.py | $(ROM_DIR)
	python3 $< > $@

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)