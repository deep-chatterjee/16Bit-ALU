# 16-bit ALU Build System
# Requires: iverilog, vvp, gtkwave, yosys

.PHONY: sim wave synth stats clean

#--------------------------------------------------------------------------
# Simulation
#--------------------------------------------------------------------------
sim: alu16.v alu16_tb.v
	iverilog -g2012 -Wall -o alu16.vvp alu16.v alu16_tb.v
	vvp alu16.vvp

#--------------------------------------------------------------------------
# View waveforms
#--------------------------------------------------------------------------
wave: sim
	gtkwave alu16.vcd alu16.gtkw &

#--------------------------------------------------------------------------
# Synthesis with Yosys (generates stats and a netlist)
#--------------------------------------------------------------------------
synth: alu16.v
	yosys -p "read_verilog alu16.v; 	          synth -top alu16; 	          stat; 	          write_verilog alu16_synth.v"

#--------------------------------------------------------------------------
# Synthesis + technology mapping to generic cells (for area estimate)
#--------------------------------------------------------------------------
stats: alu16.v
	yosys -p "read_verilog alu16.v; 	          synth -top alu16; 	          stat; 	          abc -g gates; 	          stat"

#--------------------------------------------------------------------------
# Clean
#--------------------------------------------------------------------------
clean:
	rm -f alu16.vvp alu16.vcd alu16_synth.v
