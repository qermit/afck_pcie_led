#
# Copyright (c) 2016 by Piotr Miedzik <P.Miedzik@gsi.de>
#

package require cmdline
package require opt


#
# IPCore section
#

namespace eval IPCore {
	proc register_transport {args} {
	
	}
}

namespace eval IPCore::common {

	variable data_width 32
	variable addr_width 32

	proc bitToDec { bitval } {
		set  val "0b"
		append val ${bitval}
		return [ format "%d" ${val} ]
	}

	proc decToHex { decval {len 8} } {
		set format_str [ format "0x%%0%dx" ${len} ]
		return [ format ${format_str} ${decval} ]
	}	
	
	proc uniqkey { } {
     set key   [ expr { pow(2,31) + [ clock clicks ] } ]
     set key   [ string range $key end-8 end-3 ]
     set key   [ clock seconds ]$key
     return $key
	}
	
	proc sleep { ms } {
     set uniq [ uniqkey ]
     set ::__sleep__tmp__$uniq 0
     after $ms set ::__sleep__tmp__$uniq 1
     vwait ::__sleep__tmp__$uniq
     unset ::__sleep__tmp__$uniq
	}
	
	
		tcl::OptProc ReadRegister {
	    {-params -dict {} "Params"}
		{-transport hw_axi_1 "Transport interface"}
		{-bus_offset -string 0x0 "AXI ip core address"}
		{-dry -boolean False "Dry run"}
		{reg_offset "Reg offset"}
		{?ret_format? d4 "return format"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset -dry dry} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		variable addr_width
		variable data_width
	
		set current_offset [format %08X [expr ${bus_offset} + ${reg_offset}]]
		set register_val 0
	
		if { ! ${dry} } {
			reset_hw_axi [get_hw_axis ${transport}]
	
			set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${transport}]  -force -address ${current_offset} -len 1 -size ${addr_width} -type read]
			run_hw_axi -quiet ${tmp_hw_axi}
			set register_addr [lindex [split [string trim [report_hw_axi_txn -quiet -t ${ret_format}  ${tmp_hw_axi} ]]] 0]
		
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
		}
		return ${register_val}
	}
	
	
	tcl::OptProc WriteRegister {
	    {-params -dict {} "Params"}
		{-transport hw_axi_1 "Transport interface"}
		{-bus_offset -string 0x0 "AXI ip core address"}
		{-dry -boolean False "Dry run"}
		{-debug -boolean False "Print trace to stderr"}
		{reg_offset "Reg offset"}
		{value "Value to set"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset -dry dry -debug debug} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
	
		variable addr_width
		variable data_width
	
		set current_offset [format %08X [expr ${bus_offset} + ${reg_offset}]]
		set current_data [ format %08X $value ]
		if { ${debug} } {
			puts "current offset: ${current_offset} => ${current_data}"
		}
		if { ! ${dry} } {
			reset_hw_axi [get_hw_axis ${transport}]

			set tmp_hw_axi [create_hw_axi_txn HW_AXI_TMP [get_hw_axis ${transport}]  -force -address ${current_offset} -data ${current_data} -len 1 -size ${addr_width} -type write]
	
			run_hw_axi -quiet ${tmp_hw_axi}
		}
	}
	
}

namespace eval IPCore::OHWR {}

# remove all Xilinx ipcore definition first

if { [namespace exists IPCore::Xilinx ] } { namespace delete IPCore::Xilinx }
namespace eval IPCore::Xilinx {}

# Xilinx I2C IP Core
# @todo: many things

namespace eval IPCore::Xilinx::IIC {
	variable IIC_OFFSET  0x40800000
	#variable IIC_OFFSET  0x40810000
	
	variable REGS [dict create \
		ISR			0x020 \
		CR			0x100 \
		SR			0x104 \
		TX_FIFO		0x108 \
		RX_FIFO		0x10C \
		RX_FIFO_PIRQ 0x120 \
		GPO			0x124 \
		TBUF		0x138 \
		THIGH		0x13C \
		TLOW		0x140 \
		THDDAT		0x144 \
		]
	
	
	variable REG_GPO  0x124
	variable REG_ISR 0x020
	variable REG_CR 0x100
	variable REG_SR 0x104
	variable REG_TX_FIFO 0x108
	variable REG_RX_FIFO 0x10C
	variable REG_RX_FIFO_PIRQ 0x120
	#variable IIC_OFFSET  0x40800000

	variable LedState 0
	
	proc set_bus_offset { new_offset } {
		variable IIC_OFFSET
		set IIC_OFFSET ${new_offset}
	}

	tcl::OptProc getGPO {  
		{-params -dict {} "Dict params"}
		{-transport hw_axi_1 "Transport interface"}
		{-bus_offset -string IIC_OFFSET "AXI ip core address"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		
		variable IIC_OFFSET
		if { ${bus_offset} == "IIC_OFFSET" } { set bus_offset [set IIC_OFFSET] }
		variable REG_GPO
		
		return [ IPCore::common::ReadRegister  -params ${params} ${REG_GPO} ]
	}

	
	tcl::OptProc setGPO { 
		{-params -dict {} "Dict params"}
		{-transport -string "hw_axi_1" "Transport interface"}
		{-bus_offset -string IIC_OFFSET	"AXI ip core address"}
		{ new_val -int 0 "New Value"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		variable IIC_OFFSET
		if { ${bus_offset} == "IIC_OFFSET" } { set bus_offset [set IIC_OFFSET] }
		
		variable REG_GPO

		IPCore::common::WriteRegister -params ${params} ${REG_GPO} ${new_val}
	}
	
	tcl::OptProc wr_raw {
		{-params -dict {} "Params"}
		{-transport -string "hw_axi_1" "Transport interface"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_addr -int 0 "Chip ID/Chip I2C Address"}
		{data_to_write -list {} "Data to write"}
		{?read_length? -int 0 "data to read"}
	} {
		variable IIC_OFFSET
		if { [ lsearch -exact $Args "-bus_offset" ] < 0 } {	set bus_offset ${IIC_OFFSET} }
		
	}
	
	tcl::OptProc reset {
		{-params -dict {} "Params"}
		{-transport -string "hw_axi_1" "Transport interface"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		
		variable IIC_OFFSET
		
		variable REG_CR
		variable REGS
        IPCore::common::WriteRegister -params ${params} ${REG_CR} 0x2
		IPCore::common::WriteRegister -params ${params} ${REG_CR} 0x1
		
		## czy to jest potrzebne?
		IPCore::common::WriteRegister -params ${params} [dict get ${REGS} THDDAT] 0x100
	}
	
	tcl::OptProc write_read {
		{-params -dict {} "Params"}
		{-transport -string "hw_axi_1" "Transport interface"}
		{-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_addr -strint 0x00 "Chip address"}
		{data_write {} "Data to write"}
		{?data_to_read_len? -int 0 "data to read length"} 
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}

		variable REG_CR
		variable REG_TX_FIFO
		variable REG_RX_FIFO
		variable REG_RX_FIFO_PIRQ
		variable REG_SR
		
		reset -params ${params}
		IPCore::common::WriteRegister -params ${params} ${REG_RX_FIFO_PIRQ} 0xF
		isr_clear -params ${params}
		
		set iic_addr_w [expr ${chip_addr} >> 1 << 1 ]
		set iic_addr_r [ expr ${chip_addr} + 1 ]
	
		if { [ llength ${data_write} ] > 0 } {
			reg_set ${REG_TX_FIFO} [ expr ${iic_addr_w} + 0x100 ]
			for { set i 0 } { ${i} < [ llength ${data_write} ] } { incr i } {
			    set data_to_write [lindex ${data_write} ${i} ]
				if { [ llength ${data_write} ] == [ expr ${i} + 1] } {
					if { ${data_to_read_len} == 0 } {
						incr data_to_write 0x200
					}
				}
				reg_set ${REG_TX_FIFO} ${data_to_write}
			}
		}
	
		if ${data_to_read_len} {
			return [iic_read  ${iic_addr_r} ${data_to_read_len}]
		}
	}

	
	proc reg_set { reg val } {
		variable IIC_OFFSET
		IPCore::common::WriteRegister ${IIC_OFFSET} ${reg} ${val}
	}
	
	proc reg_get { reg format } {
		variable IIC_OFFSET
		return [ IPCore::common::ReadRegister ${IIC_OFFSET} ${reg} ${format} ] 
	}
	
	proc iic_read { iic_addr len } {
		variable REG_CR 
		variable REG_TX_FIFO
		variable REG_RX_FIFO
		variable REG_RX_FIFO_PIRQ
		
		#reset 
		
		reg_set ${REG_RX_FIFO_PIRQ} 0xF
		
		set lista {}
		
		for {set i 0} { ${i} < ${len} } {incr i } {
			reg_set ${REG_TX_FIFO} [ expr ${iic_addr} + 0x100 ]
			#reg_set ${REG_TX_FIFO} [ expr ${len} + 0x200 ]
			lappend lista [reg_get ${REG_RX_FIFO} x1]
		}
		return ${lista}
		#IPCore::common::WriteRegister ${IIC_OFFSET} ${REG_RX_FIFO_PIRQ} ${len}
		#IPCore::common::WriteRegister ${IIC_OFFSET} ${REG_CR} 0x4
		
	}

	proc stop { iic_addr len } {
		variable IIC_OFFSET
		variable REG_CR 

		IPCore::common::WriteRegister ${IIC_OFFSET} ${REG_CR} 0x0
		
	}
	
	proc detect_all { {start  8} { stop 120 } } {
		variable IIC_OFFSET
		
		set i2c_chips {}
		


		for { set i ${start} }  { ${i} < ${stop} } {incr i } {
			
			set addr [ expr ${i} * 2 ]
				IPCore::common::WriteRegister  ${IIC_OFFSET} 0x120 0xF
				IPCore::common::WriteRegister  ${IIC_OFFSET} 0x100 0x2
				IPCore::common::WriteRegister  ${IIC_OFFSET} 0x100 0x1
				
			isr_clear
			
			#IPCore::common::sleep 50
			IPCore::common::WriteRegister  0x40810000 0x108 [ expr ${addr} + 0x300 ]
			#IPCore::common::sleep 50
			
			set isr_status [ isr_get ]
			
			if { [ string index ${isr_status} 6 ] == "0" } {
				#puts "Found address : ${addr}"
				lappend i2c_chips ${addr}
			} else {
				#puts "Missing address : ${addr}"
				
			}
			
		}
		return ${i2c_chips}
	}
	
	proc isr_get { } {
		variable IIC_OFFSET
		variable REG_ISR
		
		return [ IPCore::common::ReadRegister  ${IIC_OFFSET} ${REG_ISR} b1 ] 
		
	}

	proc isr_print { } {
		variable IIC_OFFSET
		variable REG_ISR
		set isr_status [ isr_get ]
		puts "ISR Status: ${isr_status}"
		
	}
	
	proc isr_toggle { val } {
		variable IIC_OFFSET
		variable REG_ISR
		
		IPCore::common::WriteRegister  ${IIC_OFFSET} ${REG_ISR} ${val}
		
	}
	proc isr_clear { } {
		set isr_status [ isr_get ]
			isr_toggle "0b${isr_status}" 
	}
	
	proc sr_get { } {
		variable IIC_OFFSET
		variable REG_SR
		return [ IPCore::common::ReadRegister  ${IIC_OFFSET} ${REG_SR} b1 ] 
	}
	
	proc rx_get { } {
		variable IIC_OFFSET
		variable REG_RX_FIFO
		return [ IPCore::common::ReadRegister  ${IIC_OFFSET} ${REG_RX_FIFO} x1 ] 
	}
	
}




namespace eval IPCore::Xilinx::SPI {
	# FMC1 ADC
	variable SPI_CTL_OFFSET  0x44A00000
	# FMC1 PLL
	# variable SPI_CTL_OFFSET  0x44A10000
	# FMC2 ADC
	#variable SPI_CTL_OFFSET  0x44A20000
	# FMC2 PLL
	#variable SPI_CTL_OFFSET  0x44A30000

	proc set_bus_offset { new_offset } {
		variable SPI_CTL_OFFSET
		set SPI_CTL_OFFSET ${new_offset}
	}
	

	proc set_bus_iface { iface_id } {
		variable SPI_CTL_OFFSET
		set SPI_CTL_OFFSET [ expr 0x44A00000 + 0x10000 * ${iface_id} ]
	}

	tcl::OptProc wr_raw {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chip ID"}
		{data_to_write -list {} "Data to write"}
		{?read_length? -int 0 "data to read"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset -chip_select chip_select} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
	
		set BIT_CPHA 4
		set VAL_CPHA 0
		set BIT_CPOL 3
		set VAL_CPOL 0
		
		set CPOL_CPHA [ expr ( ${VAL_CPHA} << ${BIT_CPHA} ) | ( ${VAL_CPOL} << ${BIT_CPOL} ) ]
		
		IPCore::common::WriteRegister -params ${params} 0x70 0xF; 
		IPCore::common::WriteRegister -params ${params} 0x60 [ expr 0x066 | 0b10000000 | ${CPOL_CPHA} ];
		IPCore::common::WriteRegister -params ${params} 0x70 [ expr 0xF ^ (2 ** ${chip_select}) ]; 

		for {set i 0} { ${i} < [ llength ${data_to_write} ] } { incr i } {
			IPCore::common::WriteRegister -params ${params} 0x68 [lindex ${data_to_write} ${i} ]
			#todo mozna wyczyscic fifo
			IPCore::common::ReadRegister -params ${params} 0x6C x4
		}
		set ret_val {}
		
		for {set i 0} { ${i} < ${read_length} } { incr i } {
			IPCore::common::WriteRegister -params ${params} 0x68 0xFF; 
			lappend ret_val [ IPCore::common::ReadRegister -params ${params}  0x6C x1 ]
		}
		IPCore::common::WriteRegister -params ${params} 0x70 0xF; 		
			
		return ${ret_val}
	}

	tcl::OptProc wr {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chip ID"}
		{-reg_offset -string 0x00 "register offset"}
		{-data_to_write -list {} "Data to write"}
		{-read_length -int 0 "data to read"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset -chip_select chip_select} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}

		set wr_args {}
		set op_arg 0x00
		set count_arg 0x00
		
		if { [ llength ${data_to_write} ] > 0 } {
			
		} else {
			set op_arg 0x80
			
			switch ${read_length} {
			    0 { set count_arg 0x00 }
				1 { set count_arg 0x00 }
				2 { set count_arg 0x10 }
				3 { set count_arg 0x20 }
				default { set count_arg 0x30 }
			}
		}
		lappend wr_args [format "0x%02X" [ expr ${count_arg} | ${op_arg} ]]
		lappend wr_args ${reg_offset}
		
		set ret_val [ wr_raw -params ${params} [concat ${wr_args} ${data_to_write} ] ${read_length} ]
	
		return ${ret_val}		
	}
}



namespace eval IPCore::Xilinx::GPIO {
	variable GPIO_CTL_OFFSET 0x40000000
	
	variable REGS [dict create GPIO_DATA 0x00 GPIO_TRI 0x04 GPIO2_DATA 0x08 GPIO2_TRI 0x0C GIER 0x011C IP_IER 0x0128 IP_ISR 0x0120]
	
	variable CACHED_OUT1 [dict create]
	variable CACHED_OUT2 [dict create]
	
	proc update_cached_out { bus_offset gpio_id value } {
		if { ${gpio_id} == 0 } {
		   variable CACHED_OUT1		   
		   dict set CACHED_OUT1 ${bus_offset} ${value}
		} elseif { ${gpio_id} == 1 } {
		   variable CACHED_OUT2
		   dict set CACHED_OUT2 ${bus_offset} ${value}
		}
	}
	
	proc get_cached_out { bus_offset gpio_id } {
		if { ${gpio_id} == 0 } {
		   variable CACHED_OUT1
		   if { [dict exists ${CACHED_OUT1} ${bus_offset} ] } {
		      return [ dict get ${CACHED_OUT1} ${bus_offset} ]
		   } else {
		      return 0x00000000
		   }
		} elseif { ${gpio_id} == 1 } {
		   variable CACHED_OUT2
		   if { [dict exists ${CACHED_OUT2} ${bus_offset} ] } {
		      return [ dict get ${CACHED_OUT2} ${bus_offset} ]
		   } else {
		      return 0x00000000
		   }		
		}
	}
	
	
	proc setVal { bus_offset gpio_id value } {
	    variable REGS
		set reg 0x00
		if { $gpio_id == 0 } {
		  set reg [dict get ${REGS} GPIO_DATA]
		} elseif { $gpio_id == 1 } {
		  set reg [dict get ${REGS} GPIO2_DATA]
			
		} else {
		  return
		}
		update_cached_out ${bus_offset} ${gpio_id} ${value}
		IPCore::common::WriteRegister ${bus_offset} ${reg} ${value}
		
		puts "Setting value to ${reg} -> ${value}"
	}
	
	proc setDirecton { bus_offset gpio_id direction } {
		variable REGS
		set reg 0x00
		if { $gpio_id == 0 } {
		  set reg [dict get ${REGS} GPIO_TRI]
		} elseif { $gpio_id == 1 } {
		  set reg [dict get ${REGS} GPIO2_TRI]
		} else {
		  return
		}
		
		IPCore::common::WriteRegister ${bus_offset} ${reg} ${value}
		puts "Setting value to ${reg} -> ${value}"
	}
	
	
	proc getVal { bus_offset gpio_id} {
	    variable REGS
		set reg 0x00
		if { $gpio_id == 0 } {
		  set reg [dict get ${REGS} GPIO_DATA]
		} elseif { $gpio_id == 1 } {
		  set reg [dict get ${REGS} GPIO2_DATA]
			
		} else {
		  return
		}
		update_cached_out ${bus_offset} ${gpio_id} ${value}
		IPCore::common::WriteRegister ${bus_offset} ${reg} ${value}
		
		puts "Setting value to ${reg} -> ${value}"
	}
	#proc setVal1 
}


namespace eval AxiCdma::LED {
	variable LED_CTL_OFFSET  0x00020000
	variable LedState 0
	
	proc setLed {} {
		variable LED_CTL_OFFSET
		variable LedState
		
		if { ${LedState} == 7} {
			set LedState 0
		} else {
			set LedState [ expr ${LedState} + 1 ]
		}
		
		IPCore::common::WriteRegister ${LED_CTL_OFFSET} 0 ${LedState}
	}
}

namespace eval AxiCdma::Cdma {
	variable CDMA_CTL_OFFSET 0x00010000
	
	proc isIdle {} {
		variable CDMA_CTL_OFFSET
		set register_val [ IPCore::common::ReadRegister ${CDMA_CTL_OFFSET} 0 x4 ]
		#set register_val [ AxiCdma::getRegister 4 ]
		#set is_idle [string index ${register_val} [expr 31 - 1]]
		#puts "AXI CDMA Status ${register_val} - is idle ${is_idle}"
		#return ${is_idle}
	}
	
	proc transferData { srcOffst dstOffset transferSize } {
		variable CDMA_CTL_OFFSET
		IPCore::common::WriteRegister -bus ${CDMA_CTL_OFFSET} 0x18 ${srcOffst}
		IPCore::common::WriteRegister -bus ${CDMA_CTL_OFFSET} 0x20 ${dstOffset}
		IPCore::common::WriteRegister -bus ${CDMA_CTL_OFFSET} 0x28 ${transferSize}
	}
}


# chips section
# remove it first

if { [namespace exists Bus ] } { namespace delete Bus }

namespace eval Bus {}
namespace eval Bus::IC {}

namespace eval Bus::IC::EEPROM {
	variable IIC_CHIP_ADDR 0xA0
	
	proc read { new_val } {
		variable IIC_CHIP_ADDR
	
		
		IPCore::common::WriteRegister  ${IIC_CHIP_ADDR} 0x100 ${nev_val}
		IPCore::common::ReadRegister  ${IIC_CHIP_ADDR} 0x100 ${nev_val}
	}
}

namespace eval Bus::IC::AD9510 {
	variable SPI_CTL_OFFSET  0x44A10000
	variable REGS [dict create \
	port_config 0x00 \
	A_counter 0x04 \
	B_counter 0x05 \
	B_counter2 0x06 \
	PLL1 0x07 \
	PLL2 0x08 \
	PLL3 0x09 \
	PLL4 0x0A \
	R_divider 0x0B \
	R_divider2 0x0C \
	PLL5 0x0D \
	delay_bypass_5 0x34 \
	delay_fullscale_5 0x35 \
	delay_fine_adjust_5 0x36 \
	delay_bypass_6 0x38 \
	delay_fullscale_6 0x39 \
	delay_fine_adjust_6 0x3A \
	LVPECL_OUT0 0x3C \
	LVPECL_OUT1 0x3D \
	LVPECL_OUT2 0x3E \
	LVPECL_OUT3 0x3F \
	LVDS_CMOS_OUT4 0x40 \
	LVDS_CMOS_OUT5 0x41 \
	LVDS_CMOS_OUT6 0x42 \
	LVDS_CMOS_OUT7 0x43 \
	CLK_SELECT 0x45 \
	divider_0a 0x48 \
	divider_0b 0x49 \
	divider_1a 0x4A \
	divider_1b 0x4B \
	divider_2a 0x4C \
	divider_2b 0x4D \
	divider_3a 0x4E \
	divider_3b 0x4F \
	divider_4a 0x50 \
	divider_4b 0x51 \
	divider_5a 0x52 \
	divider_5b 0x53 \
	divider_6a 0x54 \
	divider_6b 0x55 \
	divider_7a 0x56 \
	divider_7b 0x57 \
	function 0x58 \
	update_reg 0x5A \
	]
	proc getHwBus {} {
		return { SPI }
	}
	
	tcl::OptProc update_reg {
		{-params -dict {} "Params"}
	} {
		variable REGS
		IPCore::Xilinx::SPI::wr -params ${params} -reg_offset [dict get ${REGS} update_reg] -data_to_write { 0x1 }
	}
	
	tcl::OptProc reset {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}	
	    {-bus_offset -string 0x44A10000	"AXI ip core address"}
		{-chip_select -int 0 "Chips select" }
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		variable REGS
		set reg_port_config [dict get ${REGS} port_config]
		# reset registers (don't turn off Long Instruction bit), MSB/LSB independed mirrored bit option
		IPCore::Xilinx::SPI::wr -params ${params} -reg_offset ${reg_port_config} -data_to_write { 0x18 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg_offset ${reg_port_config} -data_to_write { 0x3C }
		# sleep ?
		IPCore::Xilinx::SPI::wr -params ${params} -reg_offset ${reg_port_config} -data_to_write { 0x18 }
		#update_reg ?
	}
	
	tcl::OptProc init_1 {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A10000	"AXI ip core address"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x3C -data { 0x8 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x3D -data { 0x8 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x3E -data { 0x8 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x3F -data { 0x8 }
		# cmos output
		#write_read 0xE { 0x0 0x3C 0x0B }
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x40 -data { 0x3 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x41 -data { 0x3 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x42 -data { 0x3 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x43 -data { 0x3 }
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x45 -data { 0x1A }
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x48 -data { 0x0 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4a -data { 0x0 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4C -data { 0x0 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4E -data { 0x0 }
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x49 -data { 0x90 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4B -data { 0x90 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4D -data { 0x90 }
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x4F -data { 0x90 }
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x58 -data { 0x20 }
		update_reg -params ${params}
		IPCore::common::sleep 10
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x58 -data { 0x24 }
		update_reg -params ${params}
		IPCore::common::sleep 10
		
		IPCore::Xilinx::SPI::wr -params ${params} -reg 0x58 -data { 0x20 }
	}
	
	tcl::OptProc dump_config {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A10000	"AXI ip core address"}
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		
		set registers {0x3C 0x3D 0x3E 0x3F 0x40 0x41 0x42 0x43 0x45 0x48 0x4A 0x4C 0x4E 0x49 0x4B 0x4D 0x4F}
		
		for {set i 0} { ${i} < [ llength ${registers} ] } {incr i} {
			puts [format "Register %s -> %s" [lindex $registers $i ] [ IPCore::Xilinx::SPI::wr -params ${params} -reg [lindex $registers ${i} ] -read 1 ] ]
		}
	}
}




namespace eval Bus::IC::ISLA216P {
	variable ISLA216P_OFFSET  0x44A00000
		
	proc getHwBus {} {
		return {SPI}
	}
	
	
	variable REGS [dict create \
	port_config        0x00 	\
	burst_end          0x02 \
	chip_id            0x08 \
	chip_version       0x09 \
	ofsset_coarse_adc0 0x20 \
	offset_fine_adc0   0x21 \
	gain_coarse_adc0   0x22 \
	gain_medium_adc0   0x23 \
	gain_fine_adc0     0x24 \
	modes_adc0         0x25 \
	ofsset_coarse_adc1 0x26 \
	offset_fine_adc1   0x27 \
	gain_coarse_adc1   0x28 \
	gain_medium_adc1   0x29 \
	gain_fine_adc1     0x2A \
	modes_adc1         0x2B \
	temp_counter_high  0x4B \
	temp_counter_low   0x4C	\
	temp_counter_control 0x4D \
	slew_diff           0x70 \
	phase_slip          0x71 \
	clock_divide        0x72 \
	output_mode_A       0x73 \
	output_mode_B       0x74 \
	test_io             0xC0 \
	user_patt1_lsb      0xC1 \
	user_patt1_msb      0xC2 \
	user_patt2_lsb      0xC3 \
	user_patt2_msb      0xC4 \
	user_patt3_lsb      0xC5 \
	user_patt3_msb      0xC6 \
	user_patt4_lsb      0xC7 \
	user_patt4_msb      0xC8 \
	user_patt5_lsb      0xC9 \
	user_patt5_msb      0xCA \
	user_patt6_lsb      0xCB \
	user_patt6_msb      0xCC \
	user_patt7_lsb      0xCD \
	user_patt7_msb      0xCE \
	user_patt8_lsb      0xCF \
	user_patt8_msb      0xD0 \
	]
	
	tcl::OptProc init_all {
		{-params -dict {} "params dictionary"}
		{-transport -string hw_axi_1 "Transport to use"}
		{-bus_offset -string 0x44A00000 "AXI ip core address"}
	} {
		for {set i 0} {${i} < 4} {incr i} {
			init_1 -chip_select ${i} -bus_offset ${bus_offset}
		}
	}
	
	tcl::OptProc reset_soft {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chips select" }
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}

		IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x00 -data { 0b10111101 }
		IPCore::common::sleep 1000
		IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x00 -data { 0b10011001 }
		IPCore::common::sleep 1000
		#puts [ IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x00 -read 1 ]
	}
	
	tcl::OptProc init_1 {
		{-params -dict {} "params dictionary"}
	    {-transport -string hw_axi_1 "Transport to use"}
        {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chips select" }
	} {
		dict for {param key} {-transport transport -bus_offset bus_offset} {
			if { [ lsearch ${Args} ${param} ] >= 0 } {
				dict set params ${key} [set ${key}]
			} elseif { [ dict exists ${params} ${key} ] } {
				set ${key} [dict get ${params} ${key}]
			} else {
				dict set params ${key} [set ${key}]
			}
		}
		# setup mode
		reset_soft -params ${params} -chip ${chip_select}
		# power down mode - pin control
		IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x25 -data { 0x00 }
		# clock_divide - divide by 1
		IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x72 -data { 0x01 }
		#// default LVDS 3mA, two's complement
		IPCore::Xilinx::SPI::wr -params ${params} -chip ${chip_select} -reg 0x73 -data { 0x20 }

		#set tmp_out_mode_b [ AxiCdma::SPI::wr -chip_select ${chip_select} -reg_offset 0x74 -read_length 1 ]
		## mode slow 0b01000000
		#set mode_fast 0b00000000 
		#set out_mode_b [expr ( ${tmp_out_mode_b} &  0b10111111) | ${mode_fast} ]
		#IPCore::Xilinx::SPI::wr -chip_select ${chip_select} -reg_offset 0x74 -data_to_write { ${out_mode_b} }
	}
	
	tcl::OptProc getTemp {
	    {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chips select" }
	} {
		IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0x4D -data_to_write { 0xCA }
		IPCore::common::sleep 500 
		IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0x4D -data_to_write { 0x20 }
		puts [IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0x4B -read 1]
		puts [IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0x4C -read 1]
		IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0x4D -data_to_write { 0x20 }
	
	}
	
	proc get_reg_addr { regName } {
		variable REGS
		if { [dict exists $REGS $regName] } {
			return [ dict get $REGS $regName ]
		} 
		return -1
	}
	
	tcl::OptProc setReg {
	    {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_addr -int 0 "Chips select" }
		{regName  "Name of register or address" }
		{regValue  "Value"}
	} {
		variable ISLA216P_OFFSET
		if { [ lsearch -exact $Args "-bus_offset" ] < 0 } {	set bus_offset ${ISLA216P_OFFSET} }
		
		set reg_offset [get_reg_addr ${regName}]
		if { ${reg_offset} == -1 } {
			return False
		}
		
		IPCore::Xilinx::SPI::wr -bus ${bus_offset} -chip ${chip_addr} -reg ${reg_offset} -data_to_write ${regValue}
		
		return True
	}

	tcl::OptProc getReg {
	    {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_addr -int 0 "Chips select" }
		{regName  "Name of register or address" }
		
	} {
		variable ISLA216P_OFFSET
		if { [ lsearch -exact $Args "-bus_offset" ] < 0 } {	set bus_offset ${ISLA216P_OFFSET} }
		
		set reg_offset [get_reg_addr ${regName}]
		if { ${reg_offset} == -1 } {
			return False
		}
		
		return [ IPCore::Xilinx::SPI::wr -bus ${bus_offset} -chip ${chip_addr} -reg ${reg_offset} -read 1 ]
	}
		
	
	tcl::OptProc setTestMode {
	    {-bus_offset -string 0x44A00000	"AXI ip core address"}
		{-chip_select -int 0 "Chips select" }
		{-test_mode -choice {None User Max Min Mid} }
		{-pattern -list {} }
	} {
		set mode 0x00;
		switch ${test_mode} {
			Max { set mode 0x20 }
			Min { set mode 0x30 }
			Mid { set mode 0x10 }
			User { 
				#set pattern_length =
				for {set i 0} { ${i}  < [ llength ${pattern} ] } {incr i} {
					set tmp  [ list [ lindex ${pattern} ${i} ] ]
					
					set tmp_lsb [ expr ${tmp} & 0x00FF ]
					set tmp_msb [ expr ( ${tmp} & 0xFF00 ) >> 8 ]
					
					#puts [format "setting LSB: offset 0x%02X -> 0x%02X" [expr 0xC1 + ${i} * 4 ] ${tmp_lsb} ]
					#puts [format "setting LSB: offset 0x%02X -> 0x%02X" [expr 0xC1 + ${i} * 4 +1] ${tmp_msb} ]
					IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset [expr 0xC1 + ${i} * 4 ] -data_to_write ${tmp_lsb}
					IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset [expr 0xC1 + ${i} * 4 + 1 ] -data_to_write ${tmp_msb}
				}
				
				set mode [ expr 0x80 + ( [ llength ${pattern} ] - 1 ) ]
			}
		}
		
		IPCore::Xilinx::SPI::wr -bus_offset ${bus_offset} -chip_select ${chip_select} -reg_offset 0xC0 -data_to_write ${mode}
		return	
	}
}

namespace eval Bus::IC:SI57x {
	variable IIC_CHIP_ADDR 0x92
	variable F_0 155.52
	variable RFREQ_0 
	variable HSDIV_0
	variable N1_0
	variable FXTAL
	variable initial_array {}
	
	
	proc get_initial_reg {offset} {
		variable initial_array
		return  [join [concat "0x" [lindex ${initial_array} ${offset} ] ] "" ] 
		#return [ expr [ join { "0x"  [}
	}

	proc get_initial_reg_std {offset} {
		variable initial_array
		return  [get_initial_reg [ expr ${offset} - 7 ] ]
		#return [ expr [ join { "0x"  [}
	}
	
	proc read_initial {} {
		variable initial_array
		variable IIC_CHIP_ADDR
		
		variable RFREQ_0 
		variable HSDIV_0
		variable N1_0
		variable F_0
		variable FXTAL
		
		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} { 0x87 0x01 }
		set initial_array [IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} {0x7} 12 ]

		
		set r7 [ get_initial_reg 0 ] 
		set HSDIV_0 [expr ($r7 & 0xe0)>>5]
		incr HSDIV_0 4
		
		set N1_0 [expr ($r7 & 0x1f)<<2]
		set r8 [ get_initial_reg 1 ]
		set N1_0 [expr $N1_0 | (($r8 & 192)>>6)]
		set N1_0 [expr $N1_0 + 1]
		set RFREQ_0 [expr $r8 & 63]
		
		set adr 9
		while {$adr <= 12} {
			#puts ${adr}
			set RFREQ_0 [expr $RFREQ_0 * 256]
			set RFREQ_0 [expr [get_initial_reg_std $adr] | $RFREQ_0]
			incr adr
		}
		
	    set FXTAL [expr ( $F_0 * $HSDIV_0 * $N1_0) / ( $RFREQ_0 / (1 << 28 ) ) ]
		
		
		puts "HSDIV: ${HSDIV_0}"
		puts "N1: ${N1_0}"
		puts "RFREQ: ${RFREQ_0}"
		puts "FXTAL: ${FXTAL}MHz"
		
	}
	
	proc set_new_freq { new_freq } {
		variable FXTAL
		variable IIC_CHIP_ADDR
		set hsdvals {{1 5.0} {7 11.0} {5 9.0} {3 7.0} {2 6.0}  {0 4.0}}
	    set found 0
		foreach hsdl $hsdvals {
			set hsdr [lindex $hsdl 0]
			set hsdv [lindex $hsdl 1]
			puts "hsdr=$hsdr hsdv=$hsdv"
			#Now we check possible hsdiv values and take the greatest
			#matching the condition
			set n1v 1
			while {$n1v<=128} {
				set fdco [expr $new_freq * $n1v]
				set fdco [expr $fdco * $hsdv]
				puts "new_freq=$new_freq fdco=$fdco n1v=$n1v hsdv=$hsdv"
				if {($fdco >= 4.85e3) & ($fdco <= 5.67e3)} {
					set found 1
					break
				}
				if {$n1v<2} {
					set n1v [expr $n1v+1]
				} else {
					set n1v [expr $n1v+2]
				}
			}
			if {$found==1} {
				break
			}
		}
		puts "Found ${found}"
		set nfreq [expr floor($fdco * (1<<28) / $FXTAL) ]
		puts $nfreq
		
		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} { 0x89 0x10 }   
		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} { 0x87 0x30 }
		
		set new_regs { 0 0 0 0 0 0 }
		lset new_regs 0 [expr ($hsdr << 5) | (($n1v-1)>>2)]
		lset new_regs 1 [expr ((($n1v-1) & 0x3)<<6) | (wide($nfreq) >> 32) ]
		lset new_regs 2 [expr (wide($nfreq) >> 24) & 0xFF ]
		lset new_regs 3 [expr (wide($nfreq) >> 16) & 0xFF ]
		lset new_regs 4 [expr (wide($nfreq) >>  8) & 0xFF ]
		lset new_regs 5 [expr (wide($nfreq) >>  0) & 0xFF ]

		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} [concat { 0x7 } $new_regs ]
		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} { 0x89 0x00 }
		IPCore::Xilinx::IIC::write_read -params ${params} -chip ${IIC_CHIP_ADDR} { 0x87 0x40 }
		
		# todo auto enable?
		#eval IPCore::Xilinx::IIC::reg_set 0x124 1
		
		
	}
	
	proc print {} {
		variable initial_array
		puts ${initial_array}
	}
	
	
}

namespace eval Bus::BPM {
	variable IIC_OFFSET 0x40800000
	# fmc1_board/spi_FMC1_ADC
	variable SPI_AD_OFFSET 0x44A20000
	# fmc1_board/spi_FMC1_pll
	variable SPI_ISLA_OFFSET 0x44A10000


	proc FMC1_ADC250_init {} {
		set params [dict create dry True]
	variable IIC_OFFSET
	variable SPI_AD_OFFSET
	variable SPI_ISLA_OFFSET
	
	IPCore::Xilinx::IIC::setGPO -params ${params} -bus_offset ${IIC_OFFSET} 0b00000110
	IPCore::common::sleep 500
	IPCore::Xilinx::IIC::setGPO -params ${params} -bus_offset ${IIC_OFFSET} 0b00000111
	IPCore::common::sleep 500
	#reset pll HW
	IPCore::Xilinx::IIC::setGPO -params ${params} -bus_offset ${IIC_OFFSET} 0b00000101
	IPCore::common::sleep 500
	IPCore::Xilinx::IIC::setGPO  -params ${params}-bus_offset ${IIC_OFFSET} 0b00000111
	IPCore::common::sleep 500
	Bus::IC::AD9510::init_1 -params ${params} -bus_offset ${SPI_AD_OFFSET}
	set AD9510_status [ IPCore::Xilinx::SPI::wr -bus_offset ${SPI_AD_OFFSET} -read_length 1 ]
	
	IPCore::common::sleep 500
	#reset ADC HW
	IPCore::Xilinx::IIC::setGPO -params ${params} -bus_offset ${IIC_OFFSET} 0b00000011
	IPCore::common::sleep 500
	IPCore::Xilinx::IIC::setGPO -params ${params} -bus_offset ${IIC_OFFSET} 0b00000111
	IPCore::common::sleep 500
	Bus::IC::ISLA216P::init_1 -params ${params} -bus_offset ${SPI_ISLA_OFFSET}
	set ISLA_status [ IPCore::Xilinx::SPI::wr -bus_offset ${SPI_ISLA_OFFSET} -read_length 1 ]
	#puts [format "AD9510_status: %s; ISLA status: %s" ${AD9510_status} ${ISLA_status}]
	
	
	
	## test mode - check bis polarity
	Bus::IC::ISLA216P::setTestMode -params ${params} -bus  ${SPI_ISLA_OFFSET} -chip 0 -test_mode User -pattern { 0xFFFF }
	#AxiCdma::SPI::ISLA216P::setTestMode -bus  ${SPI_ISLA_OFFSET} -chip 0 -test_mode User -pattern { 0x0000 }
	## test mode - io aligment
	#AxiCdma::SPI::ISLA216P::setTestMode -bus  ${SPI_ISLA_OFFSET} -chip 0 -test_mode User -pattern { 0xAAAA }
	
	
	## test mode - line aligment -> delay
	#AxiCdma::SPI::ISLA216P::setTestMode -bus  ${SPI_ISLA_OFFSET} -chip 0 -test_mode User -pattern { 0xAAAA }
	
	}
}

tcl::OptProc LibTest1 {
   {-params -dict {} "Dictionary"}
   {-bus_offset -string 0x44A00000	"AXI ip core address"}
   {-chip_select -int 0 "Chips select" }
} { 

	dict for {param key} {-bus_offset bus_offset -chip_select chip_select} {
		puts stderr "${param} ${key}"
		if { [ lsearch ${Args} ${param} ] >= 0 } {
			dict set params ${key} [set ${key}]
		} elseif { [ dict exists ${params} ${key} ] } {
			set ${key} [dict get ${params} ${key}]
		} else {
			dict set params ${key} [set ${key}]
		}
	}
	
	
	dict for {key val} ${params} {
		puts stdout [ format "%14s => %s -> %s" $key $val [set $key] ]
	}
	
}

if { [namespace exists AxiCdma ] } { namespace delete AxiCdma }


#
# General section
# @todo: remove AxiCdma
#

namespace eval AxiCdma {
	variable ctl_iface hw_axi_1
	variable ddr_iface hw_axi_1

	variable PCIE_CTL_OFFSET 0x00000000
	variable CDMA_CTL_OFFSET 0x00010000
	
	variable DDR_OFFSET        0x80000000
	variable PCIE_SLAVE_OFFSET 0x40000000
	
	variable FREQ_ROOT		125000000
	variable FREQ_MIG		100000000
	
	proc getFreqMig {} {
		variable FREQ_MIG
		return ${FREQ_MIG}
	}
	proc getFreqRoot {} {
		variable FREQ_ROOT
		return ${FREQ_ROOT}
	}
}
package require csv
package require struct::matrix

namespace eval AxiCdma::Analyser {
    variable bus_clock_hz 100000000
	
	proc setBusClockHz { newHz } {
		variable bus_clock_hz
		set bus_clock_hz ${newHz}
	}
	
	proc getDelayInNs { hz cycles } {
		set result [ expr ${cycles} * 1000000000 / ${hz} ]
		return ${result}
	}
	
	proc analyseData { fileName bus_clock_hz } {
		set my_matrix [ ::struct::matrix data ]
		set my_file [open ${fileName} ]
		
		csv::read2matrix ${my_file} ${my_matrix} , auto 

		set column_titles [ ${my_matrix} get row 0 ]
		${my_matrix} delete row 0
		set column_index_arvalid [ lsearch -regexp ${column_titles} _ARVALID\$ ]
		set column_index_rvalid [ lsearch -regexp ${column_titles} _RVALID\$ ]
		set column_index_burst_size [ lsearch -regexp ${column_titles} _AXI_ARLEN ]
		
		set rows [ ${my_matrix} rows]
		
		set first_arvalid_index -1
		set burst_size -1
		for { set row 0 }  { ${row} < ${rows} } {incr row } {
			if { [ ${my_matrix} get cell ${column_index_arvalid} ${row} ]  == 1 } {
				set first_arvalid_index ${row}
				set burst_size [expr 1 + [ IPCore::common::bitToDec [ ${my_matrix} get cell ${column_index_burst_size} ${row} ]]]
				break
			}
		}
		
		set first_rvalid_index -1
		for { set row 0 }  { ${row} < ${rows} } {incr row } {
			if { [ ${my_matrix} get cell ${column_index_rvalid} ${row} ]  == 1 } {
				set first_rvalid_index ${row}
				break
			}
		}
		
		
		set cycle_delay [ expr ${first_rvalid_index} - ${first_arvalid_index} ]
		
		puts "MIG ui freq: ${bus_clock_hz} Hz"
		puts "MIG read delay cycles: ${cycle_delay}"
		puts "MIG burst size: ${burst_size}"
		set delay_in_ns [ AxiCdma::Analyser::getDelayInNs ${bus_clock_hz} ${cycle_delay} ]
		puts "MIG delay: ${delay_in_ns}ns"

		${my_matrix} destroy
		close ${my_file}
	}
	#write_hw_ila_data -csv_file d:/test.csv [get_hw_ila_datas -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7a200t_0] -filter {CELL_NAME=~"mig_i/mig/ila_0"}]]

	proc transferData { srcOffst dstOffset transferSize } {
		variable CDMA_CTL_OFFSET
		IPCore::common::WriteRegister ${CDMA_CTL_OFFSET} 0x18 ${srcOffst}
		IPCore::common::WriteRegister ${CDMA_CTL_OFFSET} 0x20 ${dstOffset}
		IPCore::common::WriteRegister ${CDMA_CTL_OFFSET} 0x28 ${transferSize}
	}
}

# @todo register transports
IPCore::register_transport hw_axi_1 XilinxJtagAxi "localhost:3121/xilinx_tcf/Digilent/210249994172"
IPCore::register_transport uart_1 GeneralUart "/dev/ttyUSB0" 115200
IPCore::register_transport pcie_1 PciSysfs "/sys/bus/pci/devices/0000:05:00.0/resource0"
IPCore::register_transport etherbone_1 Etherbone "tcp://127.0.0.1:12312"
IPCore::register_transport etherbone_1 Etherbone "dev/wbm0"


#puts "AxiCdma::SPI::AD9510::init_1"
#puts "AxiCdma::SPI::ISLA216P::init_1"
#puts "AxiCdma::SPI::wr -bus 0x44A10000 -reg 0 -read 1"