# TCP-LAB: tcplab-metrics.tcl
# This set of procedures are intended to set specific TCP flow 
# conditions.
# Andres Arcia (University of Los Andes, Venezuela)
# Collaborators:
# Alejandro Paltrinieri (University of Buenos Aires, Argentina)


# NOTE for set-common-conditions:
# -------------------------------
# Remember that there are "private" variables of the Full-TCP implementation
# that are not treated as such, and that may be harmful to touch them 
# independently. So be aware of:
#
# private variables self-initialized for Agent/TCP/FullTcp/Sack:
#  		set reno_fastrecov_ false
#		set open_cwnd_on_pack_ false
#
# private variables self-initialized fo	Agent/TCP/FullTcp/Newreno:
#		set open_cwnd_on_pack_ false
#		set partial_window_deflation_ true
# In this last set for NewReno note that reno_fastrecov_ remains "true" up until 
# default version available for ns-2.33.
#
# Also remember that the initialization of a standard TCP agent 
# sets the announced window in 20. Therefore, if a different value
# should be announced it is necesary to change it after the (default)
# constructor initialization. That is why window_ is initialized here
# to 10000. 

proc set-common-conditions { sender receiver } {

    global tcp_opt

    $sender set segsize_ $tcp_opt(segsize)

    # To modify packet size in *normal* TCP agents use the variable packetSize_.  
    # BTW, It does not interfere with FullTCP packet size setting (segsize_).
	eval "$sender set packetSize_ $tcp_opt(segsize)"
	eval "$receiver set packetSize_ 40"

    foreach agent { $sender $receiver } {

    # To modify packet size in FullTcp, we use varible segsize_.
    # Remember that calculation of pkt size = segsize_ + header_size.
	eval "$agent set segsize_ $tcp_opt(segsize)"
	eval "$agent set nodelay_ true"
	eval "$agent set timestamps_ false"
	eval "$agent set windowInit_ $tcp_opt(initialwin)"
	eval "$agent set window_ 10000"
    eval "$agent set ssthresh_ $tcp_opt(ssthresh)"
	eval "$agent set maxburst_ $tcp_opt(maxburst)"
	}

}

# Use Token Bucket Filter to pace divacks...
proc set-div-pacing { acksize dpdp node receiver } {

    global tcp_opt ns

    set tbf [new TBF]
    $tbf set bucket_ [expr $acksize*8]
    $tbf set rate_ [expr $acksize*$dpdp*[bw_parse $tcp_opt(r2l_bw)]/$tcp_opt(segsize)]
    $tbf set qlen_ 10000
    $ns attach-tbf-agent $node $reiceiver $tbf

}


# M divacks during slow start for every data packet
proc set-divss1-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 1"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
	eval "$agent set acks_per_datapacket $dpdp_div"
    eval "$agent set divack_start true"
	eval "$agent set divack_ss true"
    eval "$agent set divack_ca false"
	eval "$agent set interval_ 200ms"
    }

}


# M divacks during congestion avoidance for every data packet
proc set-divca1-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 1"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
    eval "$agent set acks_per_datapacket $dpdp_div"
    eval "$agent set divack_start true"
	eval "$agent set divack_ss false"
    eval "$agent set divack_ca true"
	eval "$agent set interval_ 200ms"	
    }
}

# M divacks for all phases (ss and ca) for every data packet
proc set-divssca1-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 1"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
        eval "$agent set acks_per_datapacket $dpdp_div"
        eval "$agent set divack_start true"
	eval "$agent set divack_ss true"
        eval "$agent set divack_ca true"
	eval "$agent set interval_ 200ms"       
    }
}

# M divacks during slow start for every OTHER data packet
proc set-divss2-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 2"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
        eval "$agent set acks_per_datapacket $dpdp_div"
        eval "$agent set divack_start true"
	eval "$agent set divack_ss true"
        eval "$agent set divack_ca false"
	eval "$agent set interval_ 200ms"
    }
}

# M divacks during congestion avoidance for every OTHER data packet
proc set-divca2-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 2"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
        eval "$agent set acks_per_datapacket $dpdp_div"
        eval "$agent set divack_start true"
	eval "$agent set divack_ss false"
        eval "$agent set divack_ca true"
	eval "$agent set interval_ 200ms"
    }
}

# M divacks for all phases (ss and ca) for every OTHER data packet
proc set-divssca2-conditions { sender receiver } {
    
    global dpdp_div pace_div 

    set-common-conditions $sender $receiver 

    foreach agent { $sender $receiver } {
	eval "$agent set segsperack_ 2"
	eval "$agent set ackcc_active false"
	eval "$agent set ack_counter 1000000"
        eval "$agent set acks_per_datapacket $dpdp_div"
        eval "$agent set divack_start true"
	eval "$agent set divack_ss true"
        eval "$agent set divack_ca true"
	eval "$agent set interval_ 200ms"	
    }
}

# Delayed ACKs: 1 ACK every other data packet
proc set-delack-conditions { sender receiver } {
    
    set-common-conditions $sender $receiver
    
    foreach agent { $sender $receiver } {
	eval "$agent  set segsperack_ 2"
	eval "$agent  set divack_start false"
	eval "$agent  set ackcc_active false"
	eval "$agent  set interval_ 100ms"
	eval "$agent  set minrto_ 0.2"
    }
}

# One ACK per data packet
proc set-oneackpp-conditions { sender receiver } {
    
    set-common-conditions $sender $receiver 
    
    foreach agent { $sender $receiver } {
	eval "$agent  set segsperack_ 1"
	eval "$agent  set divack_start false"
	eval "$agent  set ackcc_active false"
	eval "$agent  set interval_ 200ms"
    }
}	

# ACK Congestion Control
proc set-ackcc-conditions { sender receiver } {

    set-common-conditions $sender $receiver

    foreach agent { $sender $receiver } {
	eval "$agent set divack_start false"
	eval "$agent set ackcc_active true"
#	eval "$agent set dupackcc_active true"
	eval "$agent  set minrto_ 0.2"
	eval "$agent set interval_ 100ms"
    }
}

# ACK Congestion Control special settings for SACK. 
proc set-ackcc-sack-conditions { sender receiver } {

    set-common-conditions $sender $receiver

    foreach agent { $sender $receiver } {
	eval "$agent set divack_start false"
	eval "$agent set ackcc_active true"
#	eval "$agent set dupackcc_active true"
	eval "$agent set interval_ 200ms"
    }
}

proc set-abc-tcp-list { tcp_sender_list } {

  set length [llength $tcp_sender_list]

  if { $length == 0 } {
      error "Error: empty TCP flow list to in set-abc-list."
  }

  for { set i 0 } { $i < $length } { incr i } {
      [lindex $tcp_sender_list $i] set abc_active 1
  }

}


# CREATE A GROUP OF FLOWS
#
# A group of flows is defined by a unique id (group name + flow type)
# the traffic type for the flow (longlived or shortlived are expressed in bytes)  
# the number of flows to be created, the data point of attachment (left to right
# or server to client sense of the data) and the acks point of attachement (right
# to left or client to server sense of the ACKs) is given for the set of flows.
# The bandwidth and delay of the access link is also given for the group.
# to desynchronize/syncronize the starting of the flows the start_time is given.

# flow_type = { div, acc, one, del }
# traf_type = { <LENGHT_IN_BYTES>, longlived }
# start_time = { <TIME_IN_SECS>, random }
# from_node: point of attachment of the active node oppening the connection
# to_node: point of attachment of the passive node receiving the data 
# dir: the direction of the data "lr" or "rl" (left to right, right to left).
# bw: access link bandwidth
# delay: access link delay

# TODO: Solve the problem of a unique identifier for a flow
# TODO: Incorporate the possibility of adding different 
# delays for the access links for background flows.

proc create-var-delay-flow-group-2 { group_name flow_type traf_type nb_of_flows from_node to_node start_time dir bw } {

 create-fix-delay-flow-group-2 $group_name $flow_type $traf_type $nb_of_flows $from_node $to_node $start_time $dir $bw 0 1
 
}

# Remember to define in the main source of the simulation:
# the random number generators: unsync_num and delay_rng. If they were defined 
# within this procedure, when different group of flows are created for the
# same topology, they'll have the same random string (thus, having the same
# starting time, access delays, etc). IMO, this is rather an undersirable 
# property. So define them out of this procedure. 

proc create-fix-delay-flow-group-2 { group_name flow_type traf_type nb_of_flows from_node to_node start_time dir bw delay {var_delay 0} } {

    global tcp_opt ns pace_div
    global lnode rnode nodes_char
    global snd rcv trf_src
    global unsync_num delay_rng
    global lr_start rl_start
        
    set id "$group_name-$flow_type"
    
    # To evaluate a valid number
	set pattern  {(^|[ \t])([-+]?(\d+|\.\d+|\d+\.\d*))($|[^+-.])}
	
    
    if {$nb_of_flows <= 0} {
       error "Error in number of flows ($nb_of_flows)"
       exit 1
    }
    
    for {set i 1} { $i <= $nb_of_flows } { incr i } {
	
	set lnode($dir-$id-$i) [$ns node]
	set rnode($dir-$id-$i) [$ns node]
	
	# Link the nodes with the bottleneck. 
	# This is a topology for equal RTTs.
	
	# obtain a random access delay if desired
	if { $var_delay == 1 } {
		set delay [$delay_rng value]
		puts [format "node: %d, delay: %5.7f" $i $delay]
		set nodes_char(del-$i) $delay
	}	
	create-fix-delaylink $lnode($dir-$id-$i) $from_node $bw $delay
	create-fix-delaylink $to_node $rnode($dir-$id-$i) $bw $delay
 
	if { [ string match $dir "lr" ] == 1 } {

	# LEFT TO RIGHT TRAFFIC

		if { $traf_type == "longlived" || [regexp $pattern $traf_type whole char_before number digits_before_period] } {


	    set tmp [create-ftp-over-tcp-agent $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $lnode(lr-$id-$i) $rnode(lr-$id-$i) [ flow-to-id "lr-$id-$i" ] ]

	    } elseif { $traf_type == "mice-uniform" } {

		set tmp [tcplab-create-mice-uniform $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $lnode(lr-$id-$i) $rnode(lr-$id-$i) [ flow-to-id "lr-$id-$i" ]  ]

	    } elseif { $traf_type == "mice-exponential" } {
	    
	 	set tmp [tcplab-create-mice-exponential $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $lnode(lr-$id-$i) $rnode(lr-$id-$i) [ flow-to-id "lr-$id-$i" ]  ]
	    } else {
	    error "Bad traffic type in tcplab-flows.tcl"
	    }
  
	} elseif { [ string match $dir "rl" ] == 1 } {

	# RIGHT TO LEFT TRAFFIC
	
		if { $traf_type == "longlived" || [regexp $pattern $traf_type whole char_before number digits_before_period] } {

	    set tmp [create-ftp-over-tcp-agent $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $rnode(rl-$id-$i) $lnode(rl-$id-$i) [ flow-to-id "rl-$id-$i" ] ]

	    } elseif { $traf_type == "mice-uniform" } {

		set tmp [tcplab-create-mice-uniform $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $rnode(rl-$id-$i) $lnode(rl-$id-$i) [ flow-to-id "rl-$id-$i" ]  ]

	    } elseif { $traf_type == "mice-exponential" } {
	    
	 	set tmp [tcplab-create-mice-exponential $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $rnode(rl-$id-$i) $lnode(rl-$id-$i) [ flow-to-id "rl-$id-$i" ]  ]
	 	} else {
	 	
	 	error "Bad traffic type in tcplab-flows.tcl"
	 	
	 	}
	 	
	} else {
	    error "Not a valid direction: $dir."
	}
	
	set snd($dir-$id-$i) [lindex $tmp 0]
	set rcv($dir-$id-$i) [lindex $tmp 1]
	set trf_src($dir-$id-$i) [lindex $tmp 2]

	
	if { $start_time == "random" } {
	    set st [$unsync_num value]
	} elseif { $start_time == "preset" } {
	    if { $dir == "lr" } {
	       set st $lr_start($dir-$id-$i)
	    } elseif { $dir == "rl"} {
	       set st $rl_start($dir-$id-$i)
	    }
	} else {
	    set st $start_time
	}

	if { $traf_type == "longlived" } {
	#	    puts "$dir-$id-$i @ $st"
	    $ns at $st "$trf_src($dir-$id-$i) start"
	} elseif { $traf_type == "mice-uniform" || $traf_type == "mice-exponential"} { 
		# do nothing mice starts by themselves at the beggining of the
		# transfer.
	} else {
	
	if { [regexp $pattern $traf_type whole \
              char_before number digits_before_period] } {
		# sending a single file of size $traf_type
	    $ns at $st "$snd($dir-$id-$i) sendmsg $traf_type DAT_EOF"
	    # TODO: This is a temporary behavior, once the first flow is 
	    # TODO: done, then the simulation stops.
	    $snd($dir-$id-$i) proc done_data {} "finish"
    } else {
        error ">>$traf_type<< is not a valid traffic type."
    }
    
	}
	
	set fname "set-$flow_type-conditions"
	eval "$fname $snd($dir-$id-$i) $rcv($dir-$id-$i)"
    }

}

# 
# This procedure creates a cross traffic passing a bottleneck defined
# by a couple of routers within the array "router". 
# By default, access configuration is bw=100Mb and delay=1ms.
#
proc create-fix-delay-crossed-traffic { group_name flow_type traf_type ltor rtol start_time { bw 100Mb } { delay 1ms } } {

    global router 
    # left to right traffic
    create-fix-delay-flow-group-2 $group_name $flow_type $traf_type $ltor $router(1) $router(2) random "lr" $bw $delay

    # right to left traffic 
    create-fix-delay-flow-group-2 $group_name $flow_type $traf_type $rtol $router(1) $router(2) random "rl" $bw $delay

}

#
# old proc just for testing purposes
# it should dissapear.
#
proc create-fix-delay-flow-group { group_name flow_type traf_type ltor rtol start_time { bw 100Mb } { delay 1ms } } {
    global tcp_opt ns router pace_div
    global lnode rnode snd rcv trf_src
    global unsync_num
    global lr_start rl_start

    #    set delay_rng [new RNG]
    #    for {set i 0} {$i < $opt(substrnum)} {incr i} {
    #	$delay_rng next-substream
    #    }
    
    set id "$group_name-$flow_type"
    
    for {set i 1} { $i <= $ltor } { incr i } {
	
	set lnode(lr-$id-$i) [$ns node]
	set rnode(lr-$id-$i) [$ns node]
	
	# Link the nodes with the bottleneck. 
	# This is a topology for equal RTTs.
	
	create-fix-delaylink $lnode(lr-$id-$i) $router(1) $bw $delay
	create-fix-delaylink $router(2) $rnode(lr-$id-$i) $bw $delay
	
	set tmp [create-ftp-over-tcp-agent $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $lnode(lr-$id-$i) $rnode(lr-$id-$i) [ flow-to-id "lr-$id-$i" ] ]

	set snd(lr-$id-$i) [lindex $tmp 0]
	set rcv(lr-$id-$i) [lindex $tmp 1]
	set trf_src(lr-$id-$i) [lindex $tmp 2]
	
	# TODO:
	# All flows do divack pacing. Recall that for a flow that
	
	# does duplex transmission, then divack pacing is nonesense 
	if { $pace_div == 1 && [ string match $id "div" ] == 1 } {
	    set-div-pacing 40 $dpdp_div $rnode(lr-$id-$i) $rcv(rl-$id-$i)
	}
	
	if { $start_time == "random" } {
	    set st [$unsync_num value]
	} elseif { $start_time == "preset" } {
	    set st $lr_start(lr-$id-$i)
	} else {
	    set st $start_time
	}

	if { $traf_type == "longlived" } {
#	    puts "lr-$id-$i @ $st"
	    $ns at $st "$trf_src(lr-$id-$i) start"
	} else {
	    $ns at $st "$snd(lr-$id-$i) sendmsg $traf_type DAT_EOF"
	    # TODO: This is a temporary behavior, once the first flow is 
	    # TODO: done, then the simulation stops.

	    $snd(lr-$id-$i) proc done_data {} "finish"
	}
	
	    # Activate flow
	    # TODO: the randomness in flow activation is important
	    # TODO: so, design a way of parameterize it. To me it 
	    # TODO: does not fit the ideal requierement to experiment.
	    
	    set fname "set-$flow_type-conditions"
	    eval "$fname $snd(lr-$id-$i) $rcv(lr-$id-$i)"
    }

# RIGHT-TO-LEFT FLOWS

    for {set i 1} { $i <= $rtol } { incr i } {

	set lnode(rl-$id-$i) [$ns node]
	set rnode(rl-$id-$i) [$ns node]
	
	# Link the nodes with the bottleneck. 
	# This is a topology for equal RTTs.
	create-fix-delaylink $lnode(rl-$id-$i) $router(1) $bw $delay
	create-fix-delaylink $router(2) $rnode(rl-$id-$i) $bw $delay
	set tmp [create-ftp-over-tcp-agent $tcp_opt(tcp_sender) $tcp_opt(tcp_sink) $rnode(rl-$id-$i) $lnode(rl-$id-$i) [ flow-to-id "rl-$id-$i" ] ]
	
	set snd(rl-$id-$i) [lindex $tmp 0]
	set rcv(rl-$id-$i) [lindex $tmp 1]
	set trf_src(rl-$id-$i) [lindex $tmp 2] 
	
	if { $pace_div == 1 && [string match $id "div" ] == 1 } {
	    set-div-pacing 40 $dpdp_div $rnode(rl-$id-$i) $rcv(rl-$id-$i)
	}
	
	if { $start_time == "random" } {
	    set st [$unsync_num value]
    } elseif { $start_time == "preset" } {
	    set st $rl_start(rl-$id-$i)
	} else {
	    set st $start_time
	}
	
	if { $traf_type == "longlived" } {
	    # puts "rl-$id-$i @ $st"
	    $ns at $st "$trf_src(rl-$id-$i) start"
	} else {
	    $ns at $st "$snd(rl-$id-$i) sendmsg $traf_type DAT_EOF"
	    $snd(rl-$id-$i) proc done_data {} "finish"
	}
	
	set fname "set-$flow_type-conditions"
	eval "$fname $snd(rl-$id-$i) $rcv(rl-$id-$i)"
	
    }
}


# Called each time to send a different file.
# This is an extended version of the one in rpi package by Yong Xia.
#
# In this version I force the call of a new mice after the end of 
# the previous one. 

proc tcplab-mice-stats-uniform { sender send_time file_sz interrequest_rvar size_rvar } {
global ns mice_out

set transfsz [$sender set ndatabytes_]
set transfti [expr [$ns now]-$send_time]

set ns [Simulator instance]

#set next_flow [expr [$interrequest_rvar value] * 1.0]
#it was 0.5 secs before.
set next_flow 1

puts $mice_out "beg $send_time end [$ns now] cumsize $transfsz filsize $file_sz inst-thr [expr $file_sz/$transfti]"

$ns at [expr [$ns now] + $next_flow] \
    "tcplab-mice-callback-uniform $sender $interrequest_rvar $size_rvar"

# this should make every mice start from slow start
# and reset TCP statistics 
# connection should not be reset?
# Altman&Jimenez do -> $sender reset in an old version of ns-2 reported on 
# their ns-2 reference manual.

}

proc tcplab-mice-callback-uniform { sender interrequest_rvar size_rvar } {
  global ns

  set file_sz [expr [$size_rvar value] * 1.0]
  #$ftp send $file_sz

  $sender sendmsg $file_sz DAT_EOF
  $sender proc done_data {} "tcplab-mice-stats-uniform $sender [$ns now] $file_sz $interrequest_rvar $size_rvar"
  #puts "<DEBUG> tcplab-mice-callback-uniform at time [[Simulator instance] now] mice size $file_sz"

}


proc tcplab-mice-stats-exponential { sender send_time file_sz interrequest_rvar size_rvar } {
global ns mice_out

set transfsz [$sender set ndatabytes_]
set transfti [expr [$ns now]-$send_time]

set ns [Simulator instance]

set next_flow [expr [$interrequest_rvar value] * 1.0]

puts $mice_out "beg $send_time end [$ns now] cumsize $transfsz filsize $file_sz inst-thr [expr $file_sz/$transfti]"

$ns at [expr [$ns now] + $next_flow] \
    "tcplab-mice-callback-exponential $sender $interrequest_rvar $size_rvar"
}

proc tcplab-mice-callback-exponential { sender interrequest_rvar size_rvar } {
  global ns

  set file_sz [expr [$size_rvar value] * 1.0]
  #$ftp send $file_sz

  $sender sendmsg $file_sz DAT_EOF
  $sender proc done_data {} "tcplab-mice-stats-exponential $sender [$ns now] $file_sz $interrequest_rvar $size_rvar"
  #puts "<DEBUG> tcplab-mice-callback-exponential at time [[Simulator instance] now] mice size $file_sz"

}


# Submitted by Yong Xia
#  create-mice-over-sth    creates a source that periodically sends a
#                          file with exponential interrequest times
#                          and pareto file sizes.
#
# Dave's comment: src and sink are TCL class names.  For example:
#  $src = TCP/Reno and $sink = TCPSink
# causes this procedure to behave the same as create-mice-over-reno.
# 
# Andres:
# This function sets the tcp flow then calls the mice-callback function.
# So far it is exactly the same function as Yong Xia.
# 
# For ACK-CC: the interrequest time has been: 5, 2, 1

proc tcplab-create-mice-uniform { src sink n0 n1 { fid 0 } { interrequest 1 } \
                         { size 10240} { shape 1.35 } { nsrcs 1 } } {

 set ns [Simulator instance]
 for { set i 0 } { $i < $nsrcs } { incr i } {

	 set tmp [create-ftp-over-tcp-agent $src $sink $n0 $n1 $fid]

#	puts "interrequest $interrequest"

     set interrequest_rvar [new RandomVariable/Exponential]
     $interrequest_rvar set avg_ $interrequest

# To reproduce results on [Barakat-2003]	 
  	 set size_rvar [new RandomVariable/Uniform]
	 $size_rvar set min_ 10000
	 $size_rvar set max_ 10000000

#    set first_value [$interrequest_rvar value] 
#    may induce a backoff in fulltcp (due to SYN+ACK loss).  
	 set first_value 0

     $ns at [expr [$ns now] + $first_value] \
             "tcplab-mice-callback-uniform [lindex $tmp 0] $interrequest_rvar $size_rvar"
 }
 
 if {$nsrcs == 1} {
 	# if the number of sources is one, then for debugging purposes,
	# return: sender receiver ftp-source
    return "[lindex $tmp 0] [lindex $tmp 1] [lindex $tmp 2]"
 }
}

proc tcplab-create-mice-exponential { src sink n0 n1 { fid 0 } { interrequest 5 } \
                         { size 10240} { shape 1.35 } { nsrcs 1 } } {

# global interrequest_rvar size_rvar

 set ns [Simulator instance]
 for { set i 0 } { $i < $nsrcs } { incr i } {

	 set tmp [create-ftp-over-tcp-agent $src $sink $n0 $n1 $fid]

     set interrequest_rvar [new RandomVariable/Exponential]
     $interrequest_rvar set avg_ $interrequest

     set size_rvar [new RandomVariable/Pareto]
     $size_rvar set avg_ $size
     $size_rvar set shape_ $shape

#   by appropriately setting this value, we may induce 
#   a backoff in fulltcp (due to SYN+ACK loss).  
    set first_value [$interrequest_rvar value] 
#	set first_value 0

     $ns at [expr [$ns now] + $first_value] \
             "tcplab-mice-callback-exponential [lindex $tmp 0] $interrequest_rvar $size_rvar"
 }
 
 if {$nsrcs == 1} {
 	# if the number of sources is one, then for debugging purposes,
	# return: sender receiver ftp-source
    return "[lindex $tmp 0] [lindex $tmp 1] [lindex $tmp 2]"
 }
}


# End added by Yong Xia


# Finish graph files and brings them to the current working directory.
# graph_lst is the list of references obtained through create-graphs

proc end-graphs { gr_lst } {
       
    foreach g $gr_lst {
	$g display
    }
    
    [Graph set plot_device_] close
}

# Creates a number of files ready to be consumed by xgraph. 
# traced_var_lst is a list of TCP variables to be traced
# nodes_lst is a list of TCP agents to be traced 
# returns a list of graph references to be finished at the end
# of the simulation (i.e. when finish procedure is called).

proc open-file-graph { } {
	Graph set plot_device_ [new filedev]
}

proc open-screen-graph { } {
	Graph set plot_device_ [new xgraph]
}

proc create-tcp-graphs { traced_var_lst nodes_lst node_names_lst } {

    if { [ llength $traced_var_lst ] == 0 } {
	error "No variable to trace in create-graphs."
    }
    
    set gr_l {}
    set i 0

    foreach n $nodes_lst {
	foreach g $traced_var_lst { 
	    set n_name [lindex $node_names_lst $i]
	    set g_ [new Graph/TraceInTime $g $n -1 "$n_name\-$g"]
	    $g_ set title_ "$n_name-$g"
	    lappend gr_l $g_
	    incr i
	}
    }
    
    return $gr_l
}

proc create-queue-graphs { queue_list graph_namelst } {

	if { [ llength $queue_list ] == 0 } {
	error "No list of queues specified."   
	}

	set gr_l {}
	set i 0

	foreach npair $queue_list {
	    set t_ [lindex $graph_namelst $i]
        set g_ [new Graph/QLenVersusTime [lindex $npair 0] [lindex $npair 1] -1 true true "" $t_ ] 
		$g_ set title_ $t_ 
		lappend gr_l $g_
		incr i
	}
	
	return $gr_l
}
