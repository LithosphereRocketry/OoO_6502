# Disable default .c rules
.SUFFIXES:

# Source directories
TOOLS_DIR = tools

RTL_DIR = rtl
RTL_SUPPORT_DIR = $(RTL_DIR)/system

EXT_DIR = external
EXT_V6502_DIR = $(EXT_DIR)/verilog-6502

TEST_DIR = tests
VL_TEST_DIR = $(TEST_DIR)/verilog
ASM_TEST_DIR = $(TEST_DIR)/assembly

# Output directories
ROM_DIR = rom
VVP_DIR = vvp
WAVE_DIR = waveforms

DIRS = $(ROM_DIR) $(VVP_DIR) $(WAVE_DIR)

# Verilog common source files
VL_SOURCE_SUPPORT = $(wildcard $(RTL_SUPPORT_DIR)/*.v)

# Source files for 

# Verilog module unit tests
VL_TEST_SRCS = $(wildcard $(VL_TEST_DIR)/*.v)
VL_TEST_TGTS = $(VL_TEST_SRCS:$(VL_TEST_DIR)/%.v=vl_test_%)
VL_TEST_ADDL = $(ROM_DIR)/hash.hex

# CPU program tests
CPU_DIRS = $(wildcard $(RTL_DIR)/cpu_*)
CPUS = $(CPU_DIRS:$(RTL_DIR)/cpu_%=%)

PROG_DIRS = $(wildcard $(ASM_TEST_DIR)/*)
PROGS = $(PROG_DIRS:$(ASM_TEST_DIR)/%=%)

ASM_TEST_TGTS = $(foreach c,$(CPUS),$(foreach p,$(PROGS),asm_test_$(c)_$(p)))

.PHONY: test test-vl test-asm $(VL_TEST_TGTS) $(ASM_TEST_TGTS)
.DEFAULT_GOAL: test

test: test-vl test-asm

test-vl: $(VL_TEST_TGTS)
test-asm: $(ASM_TEST_TGTS)

$(info $(ASM_TEST_TGTS))

$(VL_TEST_TGTS): vl_test_%: $(VVP_DIR)/vl_%.vvp | $(WAVE_DIR)
	vvp $< -fst
$(ASM_TEST_TGTS): asm_test_%: $(VVP_DIR)/asm_%.vvp | $(WAVE_DIR)
	vvp $< -fst

# There can be multiple rules targeting one target, and the makefile will pick
# the first one that works
$(VVP_DIR)/vl_%.vvp: $(VL_TEST_DIR)/%.v $(VL_SOURCE_SUPPORT) $(VL_TEST_ADDL) | $(VVP_DIR)
	iverilog -pfileline=1 -DROMPATH -DVERIFYPATH -DWAVEPATH=\"$(WAVE_DIR)/vl_$*.fst\" -s $* -o $@ $(filter %.v,$^)

$(ROM_DIR)/hash.hex: $(TOOLS_DIR)/romfuzz.py | $(ROM_DIR)
	python3 $< > $@

# Special case rule for the external example v6502 to include its source files
.SECONDEXPANSION:
$(VVP_DIR)/asm_v6502_%.vvp: $(ROM_DIR)/prog_$$*.hex \
					   $(ROM_DIR)/verify_$$*.hex \
					   $(wildcard $(RTL_DIR)/cpu_v6502/*.v) \
					   $(wildcard $(EXT_V6502_DIR)/*.v) \
					   $(VL_SOURCE_SUPPORT)
	iverilog -pfileline=1  -DROMPATH=\"$<\" -DVERIFYPATH=\"$(word 2,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/asm_v6502_$*.fst\" -s toplevel -o $@ $(filter %.v,$^)

# For tests not running on v6502, the makefile should fall through to here and
# not include the external libraries
.SECONDEXPANSION:
$(VVP_DIR)/asm_%.vvp: $(ROM_DIR)/prog_$$(word 2,$$(subst _, ,$$*)).hex \
					   $(ROM_DIR)/verify_$$(word 2,$$(subst _, ,$$*)).hex \
					   $$(wildcard $(RTL_DIR)/cpu_$$(word 1,$$(subst _, ,$$*))/*.v) \
					   $(VL_SOURCE_SUPPORT)
	iverilog -pfileline=1  -DROMPATH=\"$<\" -DVERIFYPATH=\"$(word 2,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/asm_$*.fst\" -s toplevel -o $@ $(filter %.v,$^)

# How to create hex verification files:
# - from existing hex files:
.PRECIOUS: $(ROM_DIR)/verify_%.hex | ROM_DIR
$(ROM_DIR)/verify_%.hex: $(ASM_TEST_DIR)/%/verify.hex
	cp $< $@

# - from python generator script:
.PRECIOUS: $(ROM_DIR)/verify_%.hex | ROM_DIR
$(ROM_DIR)/verify_%.hex: $(ASM_TEST_DIR)/%/make_verify.py
	python3 $< > $@

.PRECIOUS: %.hex
%.hex: %.bin
	xxd -p -g 1 -c 1 $< > $@

# ca65 assembler rules
.PRECIOUS: $(ROM_DIR)/prog_%.bin
.SECONDEXPANSION:
$(ROM_DIR)/prog_%.bin: basic_layout.cfg $$(subst .a65,.o,$$(wildcard $(ASM_TEST_DIR)/$$*/*.a65)) $$(subst .c,.o,$$(wildcard $(ASM_TEST_DIR)/$$*/*.c)) $$(wildcard $(ASM_TEST_DIR)/$$*/*.lib) | $(ROM_DIR)
	ld65 -o $@ -C $^ -Ln $(ROM_DIR)/symbols_$*.txt

%.o: %.a65
	ca65 -g -o $@ $<

%.a65: %.c
	cc65 -g -o $@ $<

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)