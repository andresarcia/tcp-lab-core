#
# getopt.tcl
# inpired from http://www.45.free.net/~vitus/ice/works/tcl.html#getopt
#  
#
# Option parsing library for Tcl scripts
# Copyright (C) SoftWeyr, 1997
# Original Author V. Wagner <vitus@agropc.msk.su
# Extensive Modifications by Pedro Vale Estrela, pedro.estrela@gmail.com
# (tagus.inesc-id.pt/~pestrela/ns2)
# Modifications added by Andrés Arcia (sept/08) (andres.arcia@gmail.com)
# 
# Distributed under GNU public license. (i.e. compiling into standalone
# executables or encrypting is prohibited, unless source is provided to users)
#

#
# "my_getopt" usage: 
#
# a) define cmd_line_opt(opt_conv) as in this example:
#
#	global opt
#	set cmd_line_opt(opt_conv) {
#		{ p protocol }
#		{ nam call_nam }
#		
#		{ tt generator_type }	{ tr pkt_rate }  
#		{ ts packet_size }		{ ti traffic_intradomain }
#		{ tb traffic_buffer }
#	}
#
# b) define the default options as in this example:
#	set cmd_line_opt(protocol) 		TIMIP
#	set cmd_line_opt(traffic_size)	100
#	set cmd_line_opt(call_nam)		0
#	set cmd_line_opt(generator_type)	CBR
#	...
#
# c) call "my_getopt $argv" in the beginning of the script
#
# d) the recognized parameters will replace the default options in the "cmd_line_opt" global array; 
# isolated parameters will get the value "1"
#
# USAGE EXAMPLES:
#	ns <your script>  
#  		(this will use the default options)
#
#	ns <your script> -p HAWAII -tt FTP -nam
#  		(this will replace the default cmd_line_opt(protocol) and cmd_line_opt(generator type) with the specified ones, and 
#		set the "cmd_line_opt(call_nam) flag. Note that the option's order can be interchanged at ease, eg
#		"ns <your script> -nam -tt FTP -p HAWAII"
#
#	ns <your script>  -nam -p HAWAII -tt FTP -p CIP -p HMIP
#  		(same as above, but the protocol will be the last one specified , eg HMIP)
#
#
# HELP EXAMPLES:
#	ns <your script>  -h
#		(shows the available options as a list)
#
#	ns <your script>  -h 2
#		(shows the available options and their associated values)
#







#  
# getopt2 - recieves an array of possible options with default values
# and list of options with values, and modifies array according to supplied
# values
# ARGUMENTS: arrname - array in calling procedure, whose indices is names of
# options WITHOUT leading dash and values are default values.
# if element named "default" exists in array, all unrecognized options
# would concatenated there in same form, as they was in args
# args - argument list - can be passed either as one list argument or 
# sepatate arguments 
# RETURN VALUE: none
# SIDE EFFECTS: modifies passed array 
#
proc getopt {arrname args} {
	upvar $arrname cmd_line_opt
	if ![array exist cmd_line_opt] {
		return -code error "ERROR: Array $arrname must be defined."
	}
	
	if {[llength $args]==1} {
		eval set args $args
	}
	
	if {![llength $args]} return
	
	#debug 1
	#if {[llength $args]%2!=0} {error "Odd count of opt. arguments"}

	for {set i 0} { $i < [expr [llength $args] - 1] } { incr i } {
		set a [lindex $args $i]
		set b [lindex $args [expr $i + 1]]
		

		if [string match -* $a] {
			set a [string trimleft $a -]
			
			
			if [string match -* $b] {
				## opção sem parametros. usa valor 1
				set b 1
				
				#puts "$a -> boolean (==1); "
				set i [expr $i - 1]
			}
			
			#puts "$a -> $b "
			
			## ve se esta opção existe no array de shorthands			
			if { [info exists cmd_line_opt($a)] } {
				set cmd_line_opt($a) $b
				incr i
			} else {
				
				if { $a == "h" } {
				
				do_help $b
				
				} else {
				
				set msg "ERROR: Unknown option $a. Should be one of:"
				foreach j [array names cmd_line_opt] {append msg " -" $j}
				puts $msg
				}
 
                exit 1

			}
		} else {
			puts "Ignoring Option $a"
		}

	}
	


	set a [lindex $args [expr [llength $args] - 1] ]
	
	
	if { [string match -* $a]} {
		set a [string trimleft $a -]
			
		set b 1 
		#puts "$a -> boolean (==1); "

		## ve se esta opção existe no array de shorthands			
		if { [info exists cmd_line_opt($a)] } {
			set cmd_line_opt($a) $b
			incr i
		} else {
			set msg "unknown option $a. Should be one of:"
			foreach j [array names opt] {append msg " -" $j}
			puts $msg
			
			exit 1
		}
	}


	return
}


proc my_getopt { argv } {
	global cmd_line_opt
	#set args [lindex $argv 0]
	set args $argv
	#########

	set conv $cmd_line_opt(opt_conv)

	foreach op $conv {
		set a [ lindex $op 0 ]
		set b [ lindex $op 1 ]
		
		set opt_temp($a) ""
	}

	#debug 1	
	
	getopt opt_temp $args
	
	#puts "********"


	foreach op $conv {
		set a [ lindex $op 0 ]
		set b [ lindex $op 1 ]
		set value $opt_temp($a)
		
		if { $value != "" } { 
			set cmd_line_opt($b) $value
			#puts "$b:  $cmd_line_opt($b)"
		} else {
			# ignora opções que nao foram especificadas
		}
	}
	
	#debug 1
	return

}

# print all the options:
proc print_opt { } {

global cmd_line_opt

    foreach name_ [array names cmd_line_opt] {
    if {$name_ != "opt_conv"} {
	    puts -nonewline "$name_ --> "
        set r [eval "puts \$cmd_line_opt($name_)"]
        }
    }

}


#
# define cmd_line_opt(do_help) 1 for showing the available options as a list
# define cmd_line_opt(do_help) 2 for showing the available options and its current value
#
proc do_help { help_level } {

	global cmd_line_opt 

	foreach op $cmd_line_opt(opt_conv) {
		set a [ lindex $op 0 ]
		set b [ lindex $op 1 ]
		
		set opt_temp($a) $cmd_line_opt($b)
		set opt_temp2($a) $b

	}
	
		
	if { $help_level >= 1 } {
		set msg "\n Available Options: \n"
		foreach j [array names opt_temp ] {append msg " -" $j}
		puts $msg
	}
	
	if { $help_level == 2 } {
     	puts "\n Values in Use:"
		foreach j [lsort [array names opt_temp ]] {
			puts "-$j $opt_temp($j)    \t\t($opt_temp2($j))"
		}
	}

	return
}


