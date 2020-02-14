#-------------------------------------------------------------------------------
#-- This is free and unencumbered software released into the public domain.
#--
#-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
#-- this software, either in source code form or as a compiled bitstream, for 
#-- any purpose, commercial or non-commercial, and by any means.
#--
#-- In jurisdictions that recognize copyright laws, the author or authors of 
#-- this software dedicate any and all copyright interest in the software to 
#-- the public domain. We make this dedication for the benefit of the public at
#-- large and to the detriment of our heirs and successors. We intend this 
#-- dedication to be an overt act of relinquishment in perpetuity of all present
#-- and future rights to this software under copyright law.
#--
#-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
#-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#--
#-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
#-------------------------------------------------------------------------------

############## I/O Affectation ##############

# -------------- Inputs -------------- #
#### Center Pushbutton
set_property PACKAGE_PIN AV39 [get_ports rst]
set_property IOSTANDARD LVCMOS18 [get_ports rst]

#### South Pushbutton
set_property PACKAGE_PIN AP40 [get_ports sync_in]
set_property IOSTANDARD LVCMOS18 [get_ports sync_in]

#### SYSCLK
set_property PACKAGE_PIN H19 [get_ports sysclk_p]
set_property PACKAGE_PIN G18 [get_ports sysclk_n]

set_property IOSTANDARD DIFF_SSTL15_DCI [get_ports sysclk_p]
set_property IOSTANDARD DIFF_SSTL15_DCI [get_ports sysclk_n]

#### DIPSWITCH
set_property PACKAGE_PIN AV30 [get_ports {dipswitch[0]}]
set_property PACKAGE_PIN AY33 [get_ports {dipswitch[1]}]
set_property PACKAGE_PIN BA31 [get_ports {dipswitch[2]}]
set_property PACKAGE_PIN BA32 [get_ports {dipswitch[3]}]
set_property PACKAGE_PIN AW30 [get_ports {dipswitch[4]}]
set_property PACKAGE_PIN AY30 [get_ports {dipswitch[5]}]
set_property PACKAGE_PIN BA30 [get_ports {dipswitch[6]}]
set_property PACKAGE_PIN BB31 [get_ports {dipswitch[7]}]

set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dipswitch[7]}]

#### SFP
set_property PACKAGE_PIN Y38 [get_ports {SFP0_in[2]}]
set_property PACKAGE_PIN AB42 [get_ports {SFP0_in[1]}]
set_property PACKAGE_PIN Y39 [get_ports {SFP0_in[0]}]
set_property PACKAGE_PIN AA39 [get_ports {SFP1_in[2]}]
set_property PACKAGE_PIN AA42 [get_ports {SFP1_in[1]}]
set_property PACKAGE_PIN AA40 [get_ports {SFP1_in[0]}]
set_property PACKAGE_PIN AA41 [get_ports {SFP2_in[2]}]
set_property PACKAGE_PIN AC39 [get_ports {SFP2_in[1]}]
set_property PACKAGE_PIN AD38 [get_ports {SFP2_in[0]}]
set_property PACKAGE_PIN AE38 [get_ports {SFP3_in[2]}]
set_property PACKAGE_PIN AC41 [get_ports {SFP3_in[1]}]
set_property PACKAGE_PIN AD40 [get_ports {SFP3_in[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_in[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_in[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_in[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_in[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_in[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_in[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_in[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_in[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_in[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_in[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_in[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_in[0]}]

# ------------------------------------ #

# -------------- Outputs -------------- #

#### USER_SMA_CLOCK_P
set_property PACKAGE_PIN AJ32 [get_ports sync_out]
set_property IOSTANDARD LVCMOS18 [get_ports sync_out]

#### LEDs
set_property PACKAGE_PIN AM39 [get_ports {led[0]}]
set_property PACKAGE_PIN AN39 [get_ports {led[1]}]
set_property PACKAGE_PIN AR37 [get_ports {led[2]}]
set_property PACKAGE_PIN AT37 [get_ports {led[3]}]
set_property PACKAGE_PIN AR35 [get_ports {led[4]}]
set_property PACKAGE_PIN AP41 [get_ports {led[5]}]
set_property PACKAGE_PIN AP42 [get_ports {led[6]}]
set_property PACKAGE_PIN AU39 [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[7]}]

#### SFP
set_property PACKAGE_PIN W40 [get_ports {SFP0_out[2]}]
set_property PACKAGE_PIN Y40 [get_ports {SFP0_out[1]}]
set_property PACKAGE_PIN AB41 [get_ports {SFP0_out[0]}]
set_property PACKAGE_PIN AB38 [get_ports {SFP1_out[2]}]
set_property PACKAGE_PIN AB39 [get_ports {SFP1_out[1]}]
set_property PACKAGE_PIN Y42 [get_ports {SFP1_out[0]}]
set_property PACKAGE_PIN AD42 [get_ports {SFP2_out[2]}]
set_property PACKAGE_PIN AE42 [get_ports {SFP2_out[1]}]
set_property PACKAGE_PIN AC38 [get_ports {SFP2_out[0]}]
set_property PACKAGE_PIN AE39 [get_ports {SFP3_out[2]}]
set_property PACKAGE_PIN AE40 [get_ports {SFP3_out[1]}]
set_property PACKAGE_PIN AC40 [get_ports {SFP3_out[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_out[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_out[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP0_out[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_out[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_out[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP1_out[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_out[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_out[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP2_out[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_out[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_out[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {SFP3_out[0]}]

# ------------------------------------ #

############## GTH constraints ##############

#### GTH Quad 113
set_property PACKAGE_PIN AK8 [get_ports mgtrefclk_p]
set_property PACKAGE_PIN AK7 [get_ports mgtrefclk_n]

set_property LOC GTHE2_CHANNEL_X1Y15 [get_cells -hier -filter name=~*gth_inst/*gt3_gth_rx_sfp_i/gthe2_i]
set_property PACKAGE_PIN AJ5 [get_ports {rxn[3]}]
set_property PACKAGE_PIN AJ6 [get_ports {rxp[3]}]

set_property LOC GTHE2_CHANNEL_X1Y14 [get_cells -hier -filter name=~*gth_inst/*gt2_gth_rx_sfp_i/gthe2_i]
set_property PACKAGE_PIN AL5 [get_ports {rxn[2]}]
set_property PACKAGE_PIN AL6 [get_ports {rxp[2]}]

set_property LOC GTHE2_CHANNEL_X1Y13 [get_cells -hier -filter name=~*gth_inst/*gt1_gth_rx_sfp_i/gthe2_i]
set_property PACKAGE_PIN AM7 [get_ports {rxn[1]}]
set_property PACKAGE_PIN AM8 [get_ports {rxp[1]}]

set_property LOC GTHE2_CHANNEL_X1Y12 [get_cells -hier -filter name=~*gth_inst/*gt0_gth_rx_sfp_i/gthe2_i]
set_property PACKAGE_PIN AN5 [get_ports {rxn[0]}]
set_property PACKAGE_PIN AN6 [get_ports {rxp[0]}]

############## Timing constraints ##############

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets rst]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sync_in]

#### CLK OUT
create_clock -period 2.500 -name clk_out -waveform {0.000 1.250} [get_nets -filter name=~*clk_out]

#### RX_USRCLK
create_clock -period 2.500 -name rx_usrclk0 -waveform {0.000 1.250} -add [get_nets rx_esistream_top_inst/rx_esistream_inst/rx_usrclk_0]
create_clock -period 2.500 -name rx_usrclk1 -waveform {0.000 1.250} -add [get_nets rx_esistream_top_inst/rx_esistream_inst/rx_usrclk_1]
create_clock -period 2.500 -name rx_usrclk2 -waveform {0.000 1.250} -add [get_nets rx_esistream_top_inst/rx_esistream_inst/rx_usrclk_2]
#create_clock -period 2.500 -name rx_usrclk3 -waveform {0.000 1.250} -add [get_nets rx_esistream_top_inst/rx_esistream_inst/rx_usrclk_3]

#### GTH REFCLK
create_clock -period 5.000 -name GT1_GTREFCLK0_IN [get_pins -hier -filter name=~*gthe2_i*GTREFCLK1]

#### SYSCLK
create_clock -period 10.000 -name sysclk -waveform {0.000 5.000} [get_ports sysclk_p]

#### FALSE PATH
set_false_path -from clk_out -to sysclk
set_false_path -from clk_out -to rx_usrclk0
set_false_path -from clk_out -to rx_usrclk1
set_false_path -from clk_out -to rx_usrclk2
#set_false_path -from clk_out -to rx_usrclk3

set_false_path -from sysclk -to clk_out
set_false_path -from sysclk -to rx_usrclk0
set_false_path -from sysclk -to rx_usrclk1
set_false_path -from sysclk -to rx_usrclk2
#set_false_path -from sysclk -to rx_usrclk3

set_false_path -from rx_usrclk0 -to clk_out
set_false_path -from rx_usrclk0 -to sysclk
set_false_path -from rx_usrclk0 -to rx_usrclk1
set_false_path -from rx_usrclk0 -to rx_usrclk2
#set_false_path -from rx_usrclk0 -to rx_usrclk3

set_false_path -from rx_usrclk1 -to clk_out
set_false_path -from rx_usrclk1 -to sysclk
set_false_path -from rx_usrclk1 -to rx_usrclk0
set_false_path -from rx_usrclk1 -to rx_usrclk2
#set_false_path -from rx_usrclk1 -to rx_usrclk3

set_false_path -from rx_usrclk2 -to clk_out
set_false_path -from rx_usrclk2 -to sysclk
set_false_path -from rx_usrclk2 -to rx_usrclk0
set_false_path -from rx_usrclk2 -to rx_usrclk1
#set_false_path -from rx_usrclk2 -to rx_usrclk3

#set_false_path -from rx_usrclk3 -to clk_out
#set_false_path -from rx_usrclk3 -to sysclk
#set_false_path -from rx_usrclk3 -to rx_usrclk0
#set_false_path -from rx_usrclk3 -to rx_usrclk1
#set_false_path -from rx_usrclk3 -to rx_usrclk2