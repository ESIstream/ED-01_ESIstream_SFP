# Get current path
set path_file [ dict get [ info frame 0 ] file ]
set path_src [string trimright $path_file "/script.tcl"]
set path_project [concat $path_src/project_1]

# Create project
create_project -name project_1 -dir $path_project
set_property part xc7vx690tffg1761-2 [current_project]
set_property target_language vhdl [current_project]

# Import the IPs
import_ip $path_src/ip/gth_tx_sfp.xci

# Generate the IPs
reset_target {all} [get_ips gth_tx_sfp]
generate_target {all} [get_ips gth_tx_sfp]

# Add vhdl source files
add_files $path_src/src

# Add xdc source file
add_files -fileset constrs_1 $path_src/xdc/tx_esistream_top.xdc

# Add sim source file
add_files -fileset sim_1 $path_src/sim/tb_tx_esistream_top.vhd

# Set top level
set_property top tx_esistream_top [current_fileset]

