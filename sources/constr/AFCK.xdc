set_property IOSTANDARD LVCMOS15 [get_ports boot_clk]
 

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets design_1_i/clk_wiz_0/inst/clk_in1_design_1_clk_wiz_0_1]


set_property PACKAGE_PIN AF6 [get_ports boot_clk]


set_property PACKAGE_PIN AE16 [get_ports dummy_pin]
set_property IOSTANDARD LVCMOS18 [get_ports dummy_pin]
set_property PULLUP true [get_ports dummy_pin]



#set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells {design_1_i/axi_pcie_0/U0/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AA4 [get_ports {pcie_7x_mgt_rxp[0]}]
set_property PACKAGE_PIN Y2 [get_ports {pcie_7x_mgt_txp[0]}]
#set_property LOC GTXE2_CHANNEL_X0Y1 [get_cells {design_1_i/axi_pcie_0/U0/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN Y6 [get_ports {pcie_7x_mgt_rxp[1]}]
set_property PACKAGE_PIN V2 [get_ports {pcie_7x_mgt_txp[1]}]
#set_property LOC GTXE2_CHANNEL_X0Y2 [get_cells {design_1_i/axi_pcie_0/U0/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN W4 [get_ports {pcie_7x_mgt_rxp[2]}]
set_property PACKAGE_PIN U4 [get_ports {pcie_7x_mgt_txp[2]}]
#set_property LOC GTXE2_CHANNEL_X0Y3 [get_cells {design_1_i/axi_pcie_0/U0/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN V6 [get_ports {pcie_7x_mgt_rxp[3]}]
set_property PACKAGE_PIN T2 [get_ports {pcie_7x_mgt_txp[3]}]
#set_property PACKAGE_PIN U8 [get_ports {CLK_IN_D_clk_p}]


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets boot_clk_IBUF_BUFG]


### Timing constraints
#create_clock -name pci_sys_clk -period 10 [get_ports pci_sys_clk_p]
create_clock -name pci_sys_clk -period 8 [get_ports mgt_fp2_clk0_clk_p]
create_clock -name boot_clk -period 20 [get_ports boot_clk]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]