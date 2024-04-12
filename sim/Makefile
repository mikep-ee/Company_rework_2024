XVHDL=xvhdl
XVHDLFLAGS= --2008
XELAB=xelab
XELABFLAGS= -debug typical -top 
XSIM=xsim
XSIMFLAGS= --runall
SRC_PATH=../src/

#GHDLFLAGS= --std=08
#MODULES=\
#	pkg_company_rework_types.vhdl \
#    data_shifter_reg_feeder.vhdl \
#    data_shifter_reg.vhdl \
#    message_receiver.vhdl \
#	output_shift_mux.vhdl \
#	output_shift_mux_wrapper.vhdl \
#	company_rework_2024_top.vhdl

BEHAV_MODULES=\
	$(SRC_PATH)pkg_company_rework_types.vhdl \
    $(SRC_PATH)data_shifter_reg_feeder_behav.vhdl \
    $(SRC_PATH)data_shifter_reg_behav.vhdl \
    $(SRC_PATH)message_receiver.vhdl \
	$(SRC_PATH)output_shift_mux_behav.vhdl \
	$(SRC_PATH)output_shift_mux_wrapper_behav.vhdl \
	$(SRC_PATH)company_rework_2024_top.vhdl \
	$(SRC_PATH)pkg_sink_test_vectors.vhd \
	$(SRC_PATH)tb_message_receiver.vhd

TESTBENCH=tb_message_receiver
TOPMODULE=message_receiver
#GTKWAVE=/C/Users/mpaul/Documents/gtkwave-3.3.100-bin-win32/gtkwave/bin/gtkwave.exe
#WAVEFILE=tb_wave.vcd

# Binary depends on the object file mp
#all: clean behav elaborate run
all: clean behav elab run

# Object file depends on source
compile: $(MODULES)
	@echo "Compiling files..."
	$(XVHDL) $(XVHDLFLAGS) $(MODULES)

# Object file depends on source
behav: $(BEHAV_MODULES)
	@echo "Compiling files..."
	$(XVHDL) $(XVHDLFLAGS) $(BEHAV_MODULES)
#   compile: $(MODULES)
#   	@echo "Compiling files..."
#   	$(GHDL) -a $(GHDLFLAGS) $(MODULES)

#elaborate:
#	@echo "Elaborating Files..."
#	$(GHDL) -e $(GHDLFLAGS) $(TESTBENCH)
#
#elaborate
elab:
	@echo "Elaborating Files..."
	$(XELAB) -$(XELABFLAGS) $(TOPMODULE) -snapshot $(TESTBENCH)


run: 
	@echo "Running testbench..."
	$(XSIM) $(TESTBENCH) -runall

run_wave: 
	@echo "Running testbench with waveforms..."
	$(XSIM) $(TESTBENCH) --tclbatch xsim_cfg.tcl

wave: 
	@echo "Running Wave..."
	$(XSIM) --gui tb_message_receiver.wdb &
#$(XSIM) --gui $(TESTBENCH).wdb &


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

clean:
	@echo "Cleaning up..."
	rm -f *.jou *.dmp *.pb *.log *.wdb ./xsim.dir/work/*.*