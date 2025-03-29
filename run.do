vlib work
vlog tb.v
vsim apb_testbench
add wave -r apb_testbench/dut/*
run -all