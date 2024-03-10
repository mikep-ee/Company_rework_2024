GHDL=ghdl
GHDLFLAGS= --std=08
MODULES=\
    Types_test_utility.vhd \
	text_util.vhd \
	sink_module_rework_pkg.vhd \
    sink_module_rework.vhd \
    tb_pkg_sink_test_vectors.vhd \
    tb_sink_module.vhd 

TESTBENCH=tb_sink_module
GTKWAVE=/C/Users/mpaul/Documents/gtkwave-3.3.100-bin-win32/gtkwave/bin/gtkwave.exe
WAVEFILE=tb_wave.vcd

# Binary depends on the object file mp
all: clean compile elaborate run

# Object file depends on source
compile: $(MODULES)
	@echo "Compiling files..."
	$(GHDL) -a $(GHDLFLAGS) $(MODULES)

elaborate:
	@echo "Elaborating Files..."
	$(GHDL) -e $(GHDLFLAGS) $(TESTBENCH)

run: 
	@echo "Running testbench..."
	$(GHDL) -r $(GHDLFLAGS) $(TESTBENCH) --vcd=$(WAVEFILE)

wave: 
	@echo "Running GTKWAVE"
	$(GTKWAVE) $(WAVEFILE) &

#run_tb:
#	@echo "Running testbench..."
#	$(GHDL) -r $(GHDLFLAGS) $(TESTBENCH) --vcd=$(WAVEFILE)

clean:
	@echo "Cleaning up..."
	rm -f *.o *.exe work*.cf *.vcd