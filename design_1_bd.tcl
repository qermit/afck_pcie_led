
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.4
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7k325tffg900-2
#    set_property BOARD_PART ohwr.org:afck:part0:1.0 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set led_rgb [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_rgb ]
  set mgt_fp2_clk0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_fp2_clk0 ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $mgt_fp2_clk0
  set pcie_7x_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_7x_mgt ]

  # Create ports
  set boot_clk [ create_bd_port -dir I -type clk boot_clk ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {20000000} \
 ] $boot_clk
  set dummy_pin [ create_bd_port -dir O -from 0 -to 0 dummy_pin ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $sys_rst

  # Create instance: afc_reset_0, and set properties
  set afc_reset_0 [ create_bd_cell -type ip -vlnv gsi.de:user:afc_reset:1.0 afc_reset_0 ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [ list \
CONFIG.GPIO_BOARD_INTERFACE {led_rgb} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
CONFIG.NUM_MI {3} \
CONFIG.NUM_SI {2} \
 ] $axi_interconnect_0

  # Create instance: axi_pcie_0, and set properties
  set axi_pcie_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie:2.7 axi_pcie_0 ]
  set_property -dict [ list \
CONFIG.BAR0_SIZE {64} \
CONFIG.BAR1_ENABLED {true} \
CONFIG.BAR1_SCALE {Megabytes} \
CONFIG.BAR1_SIZE {4} \
CONFIG.BAR1_TYPE {Memory} \
CONFIG.BAR_64BIT {true} \
CONFIG.BASE_CLASS_MENU {Device_was_built_before_Class_Code_definitions_were_finalized} \
CONFIG.CLASS_CODE {0x000000} \
CONFIG.DEVICE_ID {0x7022} \
CONFIG.ENABLE_CLASS_CODE {false} \
CONFIG.MAX_LINK_SPEED {5.0_GT/s} \
CONFIG.M_AXI_DATA_WIDTH {128} \
CONFIG.NO_OF_LANES {X4} \
CONFIG.NUM_MSI_REQ {1} \
CONFIG.PCIEBAR2AXIBAR_0 {0x40000000} \
CONFIG.PCIEBAR2AXIBAR_1 {0x0} \
CONFIG.PCIE_BLK_LOCN {X0Y0} \
CONFIG.PCIE_CAP_SLOT_IMPLEMENTED {true} \
CONFIG.REF_CLK_FREQ {125_MHz} \
CONFIG.SUB_CLASS_INTERFACE_MENU {All_currently_implemented_devices_except_VGA-compatible_devices} \
CONFIG.S_AXI_DATA_WIDTH {128} \
CONFIG.XLNX_REF_BOARD {None} \
CONFIG.en_ext_ch_gt_drp {true} \
CONFIG.en_transceiver_status_ports {true} \
 ] $axi_pcie_0

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.0 ila_0 ]

  # Create instance: ila_1, and set properties
  set ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.0 ila_1 ]

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.1 jtag_axi_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
CONFIG.RESET_BOARD_INTERFACE {sys_rst} \
 ] $proc_sys_reset_0

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_0 ]
  set_property -dict [ list \
CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {mgt_fp2_clk0} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf_0

  # Create instance: vio_2, and set properties
  set vio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_2 ]
  set_property -dict [ list \
CONFIG.C_NUM_PROBE_IN {16} \
CONFIG.C_NUM_PROBE_OUT {10} \
CONFIG.C_PROBE_OUT0_WIDTH {4} \
CONFIG.C_PROBE_OUT1_WIDTH {3} \
CONFIG.C_PROBE_OUT3_WIDTH {3} \
CONFIG.C_PROBE_OUT5_WIDTH {3} \
CONFIG.C_PROBE_OUT7_WIDTH {5} \
CONFIG.C_PROBE_OUT9_INIT_VAL {0x1} \
 ] $vio_2

  # Create interface connections
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_rgb] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_pcie_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_pcie_0/S_AXI_CTL]
  connect_bd_intf_net -intf_net axi_pcie_0_M_AXI [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins axi_pcie_0/M_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_pcie_0_M_AXI] [get_bd_intf_pins axi_pcie_0/M_AXI] [get_bd_intf_pins ila_1/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_pcie_0_pcie_7x_mgt [get_bd_intf_ports pcie_7x_mgt] [get_bd_intf_pins axi_pcie_0/pcie_7x_mgt]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets jtag_axi_0_M_AXI] [get_bd_intf_pins ila_0/SLOT_0_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net mgt_fp2_clk0_1 [get_bd_intf_ports mgt_fp2_clk0] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]

  # Create port connections
  connect_bd_net -net M02_ACLK_1 [get_bd_pins afc_reset_0/clk] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_pcie_0/axi_ctl_aclk_out] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net afc_reset_0_aux_reset_out [get_bd_pins afc_reset_0/aux_reset_out] [get_bd_pins proc_sys_reset_0/aux_reset_in]
  connect_bd_net -net axi_pcie_0_INTX_MSI_Grant [get_bd_pins axi_pcie_0/INTX_MSI_Grant] [get_bd_pins vio_2/probe_in10]
  connect_bd_net -net axi_pcie_0_MSI_Vector_Width [get_bd_pins axi_pcie_0/MSI_Vector_Width] [get_bd_pins vio_2/probe_in12]
  connect_bd_net -net axi_pcie_0_MSI_enable [get_bd_pins axi_pcie_0/MSI_enable] [get_bd_pins vio_2/probe_in11]
  connect_bd_net -net axi_pcie_0_axi_aclk_out [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins ila_0/clk] [get_bd_pins ila_1/clk] [get_bd_pins jtag_axi_0/aclk]
  connect_bd_net -net axi_pcie_0_interrupt_out [get_bd_pins axi_pcie_0/interrupt_out] [get_bd_pins vio_2/probe_in9]
  connect_bd_net -net axi_pcie_0_mmcm_lock [get_bd_pins axi_pcie_0/mmcm_lock] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net axi_pcie_0_pipe_qpll_lock [get_bd_pins axi_pcie_0/pipe_qpll_lock] [get_bd_pins vio_2/probe_in8]
  connect_bd_net -net axi_pcie_0_pipe_qrst_idle [get_bd_pins axi_pcie_0/pipe_qrst_idle] [get_bd_pins vio_2/probe_in7]
  connect_bd_net -net axi_pcie_0_pipe_rate_idle [get_bd_pins axi_pcie_0/pipe_rate_idle] [get_bd_pins vio_2/probe_in6]
  connect_bd_net -net axi_pcie_0_pipe_rst_idle [get_bd_pins axi_pcie_0/pipe_rst_idle] [get_bd_pins vio_2/probe_in5]
  connect_bd_net -net axi_pcie_0_pipe_rxprbserr [get_bd_pins axi_pcie_0/pipe_rxprbserr] [get_bd_pins vio_2/probe_in1]
  connect_bd_net -net axi_pcie_0_pipe_rxsyncdone [get_bd_pins axi_pcie_0/pipe_rxsyncdone] [get_bd_pins vio_2/probe_in2]
  connect_bd_net -net axi_pcie_0_pipe_txdlysresetdone [get_bd_pins axi_pcie_0/pipe_txdlysresetdone] [get_bd_pins vio_2/probe_in0]
  connect_bd_net -net axi_pcie_0_pipe_txphaligndone [get_bd_pins axi_pcie_0/pipe_txphaligndone] [get_bd_pins vio_2/probe_in4]
  connect_bd_net -net axi_pcie_0_pipe_txphinitdone [get_bd_pins axi_pcie_0/pipe_txphinitdone] [get_bd_pins vio_2/probe_in3]
  connect_bd_net -net boot_clk_1 [get_bd_ports boot_clk] [get_bd_pins vio_2/clk]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins vio_2/probe_in14]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_pcie_0/axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins vio_2/probe_in15]
  connect_bd_net -net sys_rst_1 [get_bd_ports sys_rst] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins vio_2/probe_in13]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins axi_pcie_0/REFCLK] [get_bd_pins util_ds_buf_0/IBUF_OUT]
  connect_bd_net -net vio_2_probe_out0 [get_bd_pins axi_pcie_0/pipe_txinhibit] [get_bd_pins vio_2/probe_out0]
  connect_bd_net -net vio_2_probe_out1 [get_bd_pins axi_pcie_0/pipe_txprbssel] [get_bd_pins vio_2/probe_out1]
  connect_bd_net -net vio_2_probe_out2 [get_bd_pins axi_pcie_0/pipe_txprbsforceerr] [get_bd_pins vio_2/probe_out2]
  connect_bd_net -net vio_2_probe_out3 [get_bd_pins axi_pcie_0/pipe_rxprbssel] [get_bd_pins vio_2/probe_out3]
  connect_bd_net -net vio_2_probe_out4 [get_bd_pins axi_pcie_0/pipe_rxprbscntreset] [get_bd_pins vio_2/probe_out4]
  connect_bd_net -net vio_2_probe_out5 [get_bd_pins axi_pcie_0/pipe_loopback] [get_bd_pins vio_2/probe_out5]
  connect_bd_net -net vio_2_probe_out6 [get_bd_pins axi_pcie_0/INTX_MSI_Request] [get_bd_pins vio_2/probe_out6]
  connect_bd_net -net vio_2_probe_out7 [get_bd_pins axi_pcie_0/MSI_Vector_Num] [get_bd_pins vio_2/probe_out7]
  connect_bd_net -net vio_2_probe_out9 [get_bd_ports dummy_pin] [get_bd_pins vio_2/probe_out9]

  # Create address segments
  create_bd_addr_seg -range 0x10000 -offset 0x10000 [get_bd_addr_spaces axi_pcie_0/M_AXI] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces axi_pcie_0/M_AXI] [get_bd_addr_segs axi_pcie_0/S_AXI/BAR0] SEG_axi_pcie_0_BAR0
  create_bd_addr_seg -range 0x10000 -offset 0x0 [get_bd_addr_spaces axi_pcie_0/M_AXI] [get_bd_addr_segs axi_pcie_0/S_AXI_CTL/CTL0] SEG_axi_pcie_0_CTL0
  create_bd_addr_seg -range 0x10000 -offset 0x10000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI/BAR0] SEG_axi_pcie_0_BAR0
  create_bd_addr_seg -range 0x10000 -offset 0x0 [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI_CTL/CTL0] SEG_axi_pcie_0_CTL0

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.5  2015-06-26 bk=1.3371 VDI=38 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port sys_rst -pg 1 -y 1200 -defaultsOSRD
preplace port led_rgb -pg 1 -y 1760 -defaultsOSRD
preplace port boot_clk -pg 1 -y 710 -defaultsOSRD
preplace port mgt_fp2_clk0 -pg 1 -y 1180 -defaultsOSRD
preplace port pcie_7x_mgt -pg 1 -y 540 -defaultsOSRD
preplace portBus dummy_pin -pg 1 -y 1150 -defaultsOSRD
preplace inst vio_2 -pg 1 -lvl 2 -y 860 -defaultsOSRD
preplace inst axi_pcie_0 -pg 1 -lvl 3 -y 610 -defaultsOSRD
preplace inst jtag_axi_0 -pg 1 -lvl 3 -y 1700 -defaultsOSRD
preplace inst proc_sys_reset_0 -pg 1 -lvl 1 -y 1380 -defaultsOSRD
preplace inst axi_gpio_0 -pg 1 -lvl 5 -y 1760 -defaultsOSRD
preplace inst ila_0 -pg 1 -lvl 4 -y 1984 -defaultsOSRD
preplace inst ila_1 -pg 1 -lvl 4 -y 380 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 4 -y 1372 -defaultsOSRD
preplace inst afc_reset_0 -pg 1 -lvl 1 -y 1130 -defaultsOSRD
preplace inst util_ds_buf_0 -pg 1 -lvl 2 -y 1180 -defaultsOSRD
preplace netloc sys_rst_1 1 0 2 20 980 NJ
preplace netloc axi_pcie_0_INTX_MSI_Grant 1 1 3 570 300 NJ 300 1570
preplace netloc vio_2_probe_out4 1 2 1 970
preplace netloc axi_pcie_0_pipe_rxprbserr 1 1 2 660 570 N
preplace netloc axi_pcie_0_pipe_qpll_lock 1 1 2 600 470 N
preplace netloc axi_pcie_0_axi_aclk_out 1 2 3 1050 1640 1580 1760 N
preplace netloc vio_2_probe_out5 1 2 1 960
preplace netloc vio_2_probe_out6 1 2 1 1030
preplace netloc axi_pcie_0_pipe_txphinitdone 1 1 2 620 1070 1020
preplace netloc mgt_fp2_clk0_1 1 0 2 NJ 1190 NJ
preplace netloc axi_pcie_0_pcie_7x_mgt 1 3 3 NJ 540 NJ 540 NJ
preplace netloc afc_reset_0_aux_reset_out 1 0 2 40 1200 570
preplace netloc axi_pcie_0_interrupt_out 1 1 3 590 340 NJ 340 1540
preplace netloc vio_2_probe_out7 1 2 1 1040
preplace netloc axi_pcie_0_pipe_qrst_idle 1 1 2 610 490 N
preplace netloc axi_interconnect_0_M02_AXI 1 2 3 960 310 NJ 310 2040
preplace netloc axi_pcie_0_pipe_rate_idle 1 1 2 640 510 N
preplace netloc jtag_axi_0_M_AXI 1 3 1 1600
preplace netloc vio_2_probe_out9 1 2 4 NJ 950 NJ 950 NJ 950 NJ
preplace netloc axi_pcie_0_MSI_Vector_Width 1 1 3 680 1090 NJ 1090 1540
preplace netloc util_ds_buf_0_IBUF_OUT 1 2 1 NJ
preplace netloc proc_sys_reset_0_interconnect_aresetn 1 1 4 580 1400 980 1400 1550 1560 NJ
preplace netloc axi_pcie_0_mmcm_lock 1 0 4 NJ 1240 NJ 1240 NJ 1240 1550
preplace netloc axi_pcie_0_pipe_txphaligndone 1 1 2 630 1080 1010
preplace netloc boot_clk_1 1 0 2 NJ 700 NJ
preplace netloc axi_pcie_0_M_AXI 1 3 1 1610
preplace netloc axi_pcie_0_pipe_txdlysresetdone 1 1 2 680 630 N
preplace netloc axi_gpio_0_GPIO 1 5 1 NJ
preplace netloc axi_interconnect_0_M00_AXI 1 4 1 2060
preplace netloc proc_sys_reset_0_peripheral_aresetn 1 1 2 590 1110 1050
preplace netloc vio_2_probe_out0 1 2 1 950
preplace netloc axi_interconnect_0_M01_AXI 1 2 3 950 280 NJ 280 2050
preplace netloc axi_pcie_0_MSI_enable 1 1 3 580 330 NJ 330 1560
preplace netloc M02_ACLK_1 1 0 4 NJ 1070 NJ 1100 NJ 1100 1590
preplace netloc vio_2_probe_out1 1 2 1 1000
preplace netloc axi_pcie_0_pipe_rxsyncdone 1 1 2 670 610 N
preplace netloc axi_pcie_0_pipe_rst_idle 1 1 2 650 530 N
preplace netloc vio_2_probe_out2 1 2 1 990
preplace netloc vio_2_probe_out3 1 2 1 980
levelinfo -pg 1 -10 410 820 1360 1890 2903 3040 -top 210 -bot 2050
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


