create_project afck_pcie_led ./ -part xc7k325tffg900-2

set_property target_language VHDL [current_project]

set_property BOARD_PART ohwr.org:afck:part0:1.0 [current_project]
set_property  ip_repo_paths  ./ip_repo/afc_reset [current_project]
update_ip_catalog

add_files -fileset constrs_1 -norecurse ./sources/constr/AFCK.xdc

source ./design_1_bd.tcl


make_wrapper -files [get_files ./afck_pcie_led.srcs/sources_1/bd/design_1/design_1.bd] -top

add_files -norecurse ./afck_pcie_led.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1