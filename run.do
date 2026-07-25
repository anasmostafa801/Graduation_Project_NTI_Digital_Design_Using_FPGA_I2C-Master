vlib work
vlog *.v
vsim -voptargs=+acc dut_tb
add wave *
run -all