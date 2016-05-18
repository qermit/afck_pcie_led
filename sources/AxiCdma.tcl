namespace eval AxiCdma {
    variable n 0
	variable inst_iface hw_axi_1
	variable data_width 32
	variable addr_width 32
	variable CDMA_CORE_OFFSET 0x44A00000
	variable SG_BRAM_OFFSET 0x50000000
}

#proc AxiCdma::AxiCdma {} {

#   variable n
#   set instance [namespace current]::[incr n]
#   namespace eval $instance {variable s {}}

   # $object method arg.. sugar
#   interp alias {} $instance {} ::AxiCdma::do $instance

#	variable inst_iface
#	set inst_iface $iface

	
#}

#proc AxiCdma::do {self method args} { #-- Dispatcher with methods
	#puts ${self}
	#puts ${method}
#	return ::AxiCdma::getIface ${self}
#}

#proc AxiCdma::getIface {} {
#	variable inst_iface
#	return $inst_iface
#}

#proc AxiCdma::setIface { iface } {
#	variable inst_iface
#	set inst_iface $iface
#}

#proc AxiCdma::setOffset { offset } {
#	variable CDMA_CORE_OFFSET
#	set core_iface $offset
#}

proc AxiCdma::AxiRegisterRead {reg_base reg_offset {ret_format d4}} {
	variable inst_iface
	variable addr_width
	variable data_width
	
	set current_offset [format %08X [expr ${reg_base} + ${reg_offset}]]
	reset_hw_axi [get_hw_axis ${inst_iface}]
	
	set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${inst_iface}]  -force -address ${current_offset} -len 1 -size ${addr_width} -type read]
	run_hw_axi -quiet ${tmp_hw_axi}
	set register_addr [lindex [split [string trim [report_hw_axi_txn -quiet -t ${ret_format}  ${tmp_hw_axi} ]]] 0]
	
	set register_val 0
	set register_val_list [split [string trim [report_hw_axi_txn -quiet -t ${ret_format}  ${tmp_hw_axi} ]]]
	set reg_list_len [ llength ${register_val_list} ]
	
	for {set i 1} {$i < ${reg_list_len} } {incr i} {
			set tmp_var [ lindex $register_val_list ${i} ]
			set tmp_len [ string length ${tmp_var} ]
			if { ${tmp_len} > 0 } {
				set register_val  ${tmp_var}
				break
			}
	}
	return ${register_val}
}

proc AxiCdma::AxiRegisterWrite {reg_base reg_offset value} {
	variable inst_iface
	variable addr_width
	variable data_width
	
	set current_offset [format %08X [expr ${reg_base} + ${reg_offset}]]
	set current_value  [format %08X ${value} ]
	
	reset_hw_axi [get_hw_axis ${inst_iface}]
	
	set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${inst_iface}]  -force -address ${current_offset} -len 1 -size ${addr_width} -type write -data ${current_value} ]
	run_hw_axi -quiet ${tmp_hw_axi}
	return 
}

proc AxiCdma::getRegister { reg_offset } {
	variable CDMA_CORE_OFFSET
	set register_val [ AxiCdma::AxiRegisterRead ${CDMA_CORE_OFFSET} ${reg_offset} b4 ] 
	return ${register_val}
}

proc AxiCdma::setRegister { reg_offset value } {
	variable CDMA_CORE_OFFSET
	variable inst_iface
	variable addr_width
	variable data_width

	set current_offset [format %08X [expr ${CDMA_CORE_OFFSET} + ${reg_offset}]]
	set current_data [ format %08X $value ]
	puts "current offset: ${current_offset} => ${current_data}"

	
	reset_hw_axi [get_hw_axis ${inst_iface}]
	
	set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${inst_iface}]  -force -address ${current_offset} -data ${current_data} -len 1 -size ${addr_width} -type write]
	run_hw_axi -verbose ${tmp_hw_axi}
	
	return
}


proc AxiCdma::prepareData { axi_mem_iface offset size } {
	variable addr_width
	variable data_width
	set mul [expr ${data_width}	/ 8 ]
	for {set i 0} {$i < $size} {incr i} {	
		set current_offset [ format %08X [expr ${offset} + ${i} * ${mul}] ]
		set current_data [ format %08X $i ]
		puts "format ${current_offset} ${current_data}"
		set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${axi_mem_iface}]  -force -address ${current_offset} -len 1 -data ${current_data} -size ${addr_width} -type write]
		run_hw_axi -quiet ${tmp_hw_axi}
		delete_hw_axi_txn ${tmp_hw_axi}
	}
}

proc AxiCdma::isIdle {} {
	set register_val [ AxiCdma::getRegister 4 ]
	set is_idle [string index ${register_val} [expr 31 - 1]]
	puts "AXI CDMA Status ${register_val} - is idle ${is_idle}"
	return ${is_idle}
}

proc AxiCdma::simpleTransfer { srcOffst dstOffset transferSize } {
	AxiCdma::setRegister 0x18 ${srcOffst}
	AxiCdma::setRegister 0x20 ${dstOffset}
	AxiCdma::setRegister 0x28 ${transferSize}
}

proc AxiCdma::sgTransfer { srcOffst dstOffset transferSize chunkSize } {
	variable SG_BRAM_OFFSET
	#enable 
	AxiCdma::setRegister 0x0 0x4	
	AxiCdma::setRegister 0x0 0x21008	
	
	set parts [expr ${transferSize} / ${chunkSize} ]
	puts "Transfer parts: ${parts}"
	
	set taildsc_ptr 0
	
	for {set i 0} { ${i} < ${parts} } { incr i } {
		set current_sg_offset [ expr ${SG_BRAM_OFFSET} + ${i} * 0x40 ]
		set taildsc_ptr		  [ expr ${i} * 0x40 ]
		set next_sg_PTR 	  [ expr ${i} * 0x40 + 0x40 ] 
		set current_srcOffset [ expr ${srcOffst} + ${chunkSize} * ${i} ]
		set current_dstOffset [ expr ${dstOffset} + ${chunkSize} * ${i} ]
		
		puts [ format "Current SG offset: %08X" ${current_sg_offset} ]
		puts [ format "Current chunk src offset: %08X" ${current_srcOffset} ]
		puts [ format "Current chunk dst offset: %08X" ${current_dstOffset} ]
		
		AxiCdma::AxiRegisterWrite 	${current_sg_offset} 0x00 ${next_sg_PTR}
		AxiCdma::AxiRegisterWrite 	${current_sg_offset} 0x08 ${current_srcOffset}
		AxiCdma::AxiRegisterWrite 	${current_sg_offset} 0x10 ${current_dstOffset}
		AxiCdma::AxiRegisterWrite 	${current_sg_offset} 0x18 ${chunkSize}
		AxiCdma::AxiRegisterWrite 	${current_sg_offset} 0x1C 0
		
		
	}
	
	AxiCdma::setRegister 0x08 0
	AxiCdma::setRegister 0x10 ${taildsc_ptr}
	
	#AxiCdma::setRegister 0x18 ${srcOffst}
	#AxiCdma::setRegister 0x20 ${dstOffset}
	#AxiCdma::setRegister 0x28 ${transferSize}
	
	# set Sg first and last
	
}

