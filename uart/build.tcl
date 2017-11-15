set outdir [pwd]/output
file mkdir $outdir
read_verilog "uart.v top.v"
read_xdc uart.xdc

synth_design -top top -part xc7a35ticsg324-1L
opt_design
place_design
route_design
write_bitstream -force -bin_file uart.bit
