XVHDL=xvhdl
XVHDLFLAGS= -v
#GHDLFLAGS= --std=08
MODULES=\
	pkg_company_rework_types.vhdl \
    data_shifter_reg_feeder.vhdl \
    data_shifter_reg.vhdl \
    message_receiver.vhdl \
	output_shift_mux.vhdl \
	output_shift_mux_wrapper.vhdl \
	company_rework_2024_top.vhdl

BEHAV_MODULES=\
	pkg_company_rework_types.vhdl \
    data_shifter_reg_feeder_behav.vhdl \
    data_shifter_reg_behav.vhdl \
    message_receiver_behav.vhdl \
	output_shift_mux_behav.vhdl \
	output_shift_mux_wrapper_behav.vhdl \
	company_rework_2024_top.vhdl

#TESTBENCH=tb_sink_module
#GTKWAVE=/C/Users/mpaul/Documents/gtkwave-3.3.100-bin-win32/gtkwave/bin/gtkwave.exe
#WAVEFILE=tb_wave.vcd

# Binary depends on the object file mp
all: clean compile elaborate run

# Object file depends on source
compile: $(MODULES)
	@echo "Compiling files..."
	$(XVHDL) $(MODULES)

# Object file depends on source
behav: $(BEHAV_MODULES)
	@echo "Compiling files..."
	$(XVHDL) $(BEHAV_MODULES)
#   compile: $(MODULES)
#   	@echo "Compiling files..."
#   	$(GHDL) -a $(GHDLFLAGS) $(MODULES)

#elaborate:
#	@echo "Elaborating Files..."
#	$(GHDL) -e $(GHDLFLAGS) $(TESTBENCH)
#
#run: 
#	@echo "Running testbench..."
#	$(GHDL) -r $(GHDLFLAGS) $(TESTBENCH) --vcd=$(WAVEFILE)
#
#wave: 
#	@echo "Running GTKWAVE"
#	$(GTKWAVE) $(WAVEFILE) &
#
#run_tb:
#	@echo "Running testbench..."
#	$(GHDL) -r $(GHDLFLAGS) $(TESTBENCH) --vcd=$(WAVEFILE)

#clean:
#	@echo "Cleaning up..."
#	rm -f *.o *.exe work*.cf *.vcd