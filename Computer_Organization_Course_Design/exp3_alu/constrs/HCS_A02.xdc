## HCS-A02 board constraints for Experiment 3 ALU.
## SW[2:0]  -> ALU_OP[2:0]
## SW[5:3]  -> AB_SW[2:0]
## SW[8:6]  -> F_LED_SW[2:0]
## LD[7:0]  -> selected result byte or flags
## LD[8]    -> ZF
## LD[9]    -> OF
## AN[7:0]  -> 7-segment digit enables, active low
## SEG[7:0] -> {DP, CG, CF, CE, CD, CC, CB, CA}, active low

set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports CLK100MHZ]
create_clock -period 10.000 -name clk100mhz [get_ports CLK100MHZ]

set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports { SW[0] }]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { SW[1] }]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { SW[2] }]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { SW[3] }]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { SW[4] }]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { SW[5] }]
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { SW[6] }]
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { SW[7] }]
set_property -dict { PACKAGE_PIN U9  IOSTANDARD LVCMOS33 } [get_ports { SW[8] }]

set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { LD[0] }]
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { LD[1] }]
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports { LD[2] }]
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { LD[3] }]
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { LD[4] }]
set_property -dict { PACKAGE_PIN M16 IOSTANDARD LVCMOS33 } [get_ports { LD[5] }]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { LD[6] }]
set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports { LD[7] }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { LD[8] }]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { LD[9] }]

set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS33 } [get_ports { AN[0] }]
set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports { AN[1] }]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports { AN[2] }]
set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports { AN[3] }]
set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports { AN[4] }]
set_property -dict { PACKAGE_PIN A1 IOSTANDARD LVCMOS33 } [get_ports { AN[5] }]
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports { AN[6] }]
set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS33 } [get_ports { AN[7] }]

set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 } [get_ports { SEG[0] }]
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports { SEG[1] }]
set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports { SEG[2] }]
set_property -dict { PACKAGE_PIN E1 IOSTANDARD LVCMOS33 } [get_ports { SEG[3] }]
set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS33 } [get_ports { SEG[4] }]
set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33 } [get_ports { SEG[5] }]
set_property -dict { PACKAGE_PIN B3 IOSTANDARD LVCMOS33 } [get_ports { SEG[6] }]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports { SEG[7] }]
