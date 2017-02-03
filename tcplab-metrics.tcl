# TCP-LAB: tcplab-metrics.tcl
# This is a library that make easier the calculation 
# of the certain metrics to evaluate TCP.
# Andres Arcia (University of Los Andes, Venezuela)
# Collaborators:
# Alejandro Paltrinieri (University of Buenos Aires, Argentina)

#source $env(NS)/tcl/rpi/tcp-stats.tcl
#source $env(NS)/tcl/rpi/link-stats.tcl
#source $env(NS)/tcl/rpi/script-tools.tcl
#source $env(NS)/tcl/rpi/graph.tcl

Class Throughput

# n0: starting node
# n1: arriving node 
# t: time grain to obtain new thorughput sample
# avg_grain: number of samples to average
# file: file prefix for this throughput
Throughput instproc init { n0 n1 t avg_grain file } {
    $self instvar link_stats_ t_ avg_grain_ tfile_ avgfile_ tcount_
    $self instvar acc_count_ avg_count_

    set ns_ [Simulator instance]
    set link_stats_ [new LinkStats $n0 $n1]
    set t_ $t
    set avg_grain_ $avg_grain
    set avg_count_ 0
    set acc_count_ 0

    set tfile_ [open "$file-thr-time.dat" w]  
    set avgfile_ [open "$file-thr-avg.dat" w]  

    set now [$ns_ now]

    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

Throughput instproc take_sample { } {

    $self instvar t_ avg_grain_ link_stats_ avg_count_ acc_count_
    $self instvar tfile_ avgfile_

    incr avg_count_
    
    set now [[Simulator instance] now] 

    # Remember the sliced throughput can be obtained just
    # once because the reference time is reset.

    set th [$link_stats_ get-sliced-throughput]
    set acc_count_ [expr $acc_count_ + $th]

    if { $avg_count_ == $avg_grain_ } {

        puts $avgfile_ "$now [expr $acc_count_ / $avg_grain_]"
        set avg_count_ 0
        set acc_count_ 0

    }

    puts $tfile_ "$now $th"
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}


Class IThroughput

# Gives the individual throughput for each of the TCP flows within the
# list. This function gives just the sliced/instantaneous throughput.
# --
# tcp_list: list of TCP flows
# t: time grain to obtain the throughput sample
# file: prefix for the output file
IThroughput instproc init { tcp_list t file } {
    $self instvar t_ tcp_list_ ind_thr_file_

    set t_ $t
    set tcp_list_ $tcp_list
     
    set ind_thr_file_ [open "$file-ind-thr.dat" w]
    
    set now [[Simulator instance] now] 
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

IThroughput instproc take_sample { } {
	
	$self instvar t_ tcp_list_ ind_thr_file_
   
    set now [[Simulator instance] now] 
    
    set length [llength $tcp_list_]

  	if { $length == 0 } {
        error "Error: empty TCP list to Individual Throughput."
    }

 	puts -nonewline $ind_thr_file_ "$now "
  
    for { set i 0 } { $i < $length } { incr i } {
  	    puts -nonewline $ind_thr_file_ "[[lindex $tcp_list_ $i] get-throughput-bps] "
  	}
	
	puts $ind_thr_file_ ""
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}



Class AThroughput

# This class gives the aggregated throughput of a list of TCP flows
# averaged in time. Every time that the function takes a sample, it
# corresponds to the whole quantity of bits transfered from the beggining
# of the connexion, therefore its name AThroughput (accumulated throughput).
# --
# tcp_list: list of TCP flows 
# t: time grain to obtain new thorughput sample
# file: file prefix for this throughput
AThroughput instproc init { tcp_list t file } {
    $self instvar t_ tcp_list_ agg_thr_file_

    set t_ $t
    set tcp_list_ $tcp_list
     
    set agg_thr_file_ [open "$file-agg-thr.dat" w]
    
    set now [[Simulator instance] now] 
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

AThroughput instproc take_sample { } {
	
	$self instvar t_ tcp_list_ agg_thr_file_
   
    set now [[Simulator instance] now] 
    
    set athr_ [expr [get-list-mean-throughput $tcp_list_] * [llength $tcp_list_]]
	puts $agg_thr_file_ "$now $athr_"
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}


Class AGoodput

# This class gives the aggregated goodput of a list of TCP flows
# averaged in time. Every time that the function takes a sample, it
# corresponds to the whole quantity of bits transfered from the beggining
# of the connexion, therefore its name AThroughput (accumulated throughput).
# --
# tcp_list: list of TCP flows 
# t: time grain to obtain new thorughput sample
# file: file prefix for this throughput
AGoodput instproc init { tcp_list t file } {
    $self instvar t_ tcp_list_ agg_good_file_

    set t_ $t
    set tcp_list_ $tcp_list
     
    set agg_good_file_ [open "$file-agg-good.dat" w]
    
    set now [[Simulator instance] now] 
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

AGoodput instproc take_sample { } {
	
	$self instvar t_ tcp_list_ agg_good_file_
   
    set now [[Simulator instance] now] 
    
    set agood_ [expr [get-list-mean-goodput $tcp_list_] * [llength $tcp_list_]]
	puts $agg_good_file_ "$now $agood_"
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}



Class CMThroughput

# This class gives the cummulative mean throughput of a list of TCP flows
# averaged in time. Every time that the function takes a sample, it
# corresponds to the whole quantity of bits transfered from the beggining
# of the connexion, then it is averaged by the quantity of TCP senders. 
# --
# tcp_list: list of TCP flows 
# t: time grain to obtain new thorughput sample for all TCP connections
# file: output file prefix 
CMThroughput instproc init { tcp_list t file } {
    $self instvar t_ tcp_list_ cummean_thr_file_

    set t_ $t
    set tcp_list_ $tcp_list
     
    set cummean_thr_file_ [open "$file-cummean-thr.dat" w]
    
    set now [[Simulator instance] now] 
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

CMThroughput instproc take_sample { } {
	
	$self instvar t_ tcp_list_ cummean_thr_file_
   
    set now [[Simulator instance] now] 
    
    set cmthr_ [expr [get-list-mean-throughput $tcp_list_]]
	puts $cummean_thr_file_ "$now $cmthr_"
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}


Class Fairness

# This class is able to observe the fairness among different flows during 
# certain period of time. 
# At the end of a period t the fairness index is calculated from the beggining 
# of the measurement period (ie, the initialization of the object). 
# tcp_list: list of TCP flow to process their throughput through Jain's index. 
# t: time grain to obtain new thorughput sample
# avg_grain: number of samples to average
# file: file prefix for this fairness object

Fairness instproc init { tcp_list t avg_grain file } {
    $self instvar tcp_list_ t_ avg_grain_ tfile_ avgfile_ tcount_
    $self instvar acc_count_ avg_count_ 

    set ns_ [Simulator instance]
    set t_ $t
    set tcp_list_  $tcp_list
    set avg_grain_ $avg_grain
    set avg_count_ 0
    set acc_count_ 0

    set tfile_ [open "$file-fair-time.dat" w]  
    set avgfile_ [open "$file-fair-avg.dat" w]  

    set now [$ns_ now]

    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

Fairness instproc take_sample { } {

    $self instvar tcp_list_ t_ avg_grain_ avg_count_ acc_count_
    $self instvar tfile_ avgfile_

    incr avg_count_
    
    set now [[Simulator instance] now] 

    # Remember the sliced throughput can be obtained just
    # once because the reference time is reset.

    set fair [get-fairness-index  $tcp_list_]
    set acc_count_ [expr $acc_count_ + $fair]

    if { $avg_count_ == $avg_grain_ } {

        puts $avgfile_ "$now [expr $acc_count_ / $avg_grain_]"
        set avg_count_ 0
        set acc_count_ 0

    }

    puts $tfile_ "$now $fair"
    
    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}



# This class is intended to measure the occupation of data packets
# and ACKs. Two files are created with instant and average
# occupation. 
Class Occupation

# n0: departing node
# n1: arriving node
# t: time grain to measure the occupation
# avg_grain: number of sample to average
# file: file prefix to store the time and avg statistics

Occupation instproc init { n0 n1 t avg_grain file } {
    $self instvar link_stats_ t_ avg_grain_ tfile_ avgfile_ tcount_
    $self instvar acc_count_ avg_count_
    $self instvar last_total_dp_depart last_total_ack_depart 
    $self instvar tmp_docc tmp_aocc 
    $self instvar mean_dp_occupation mean_ack_occupation ns_

    set ns_ [Simulator instance]
    set link_stats_ [new LinkStats $n0 $n1]
    set t_ $t
    set avg_grain_ $avg_grain

    set avg_count_ 0
    set acc_count_ 0
    set last_total_dp_depart 0
    set last_total_ack_depart 0
    set tmp_docc 0
    set tmp_aocc 0
    set mean_dp_occupation 0
    set mean_ack_occupation 0

    set tfile_ [open "$file-ocup-time.dat" w]  
    set avgfile_ [open "$file-ocup-avg.dat" w]  

    set now [$ns_ now]

    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}



Occupation instproc take_sample { } {

    $self instvar link_stats_ t_ avg_grain_ tfile_ avgfile_ tcount_
    $self instvar acc_count_ avg_count_
    $self instvar last_total_dp_depart last_total_ack_depart 
    $self instvar tmp_docc tmp_aocc 
    $self instvar mean_dp_occupation mean_ack_occupation ns_


    set now [$ns_ now]

    incr avg_count_
    
    set tmp_docc [expr $tmp_docc + [$link_stats_ get-dp-packets-inqueue]]
    set tmp_aocc [expr $tmp_aocc + [$link_stats_ get-ack-packets-inqueue]]
    
    if { $avg_count_ == $avg_grain_ } {
	
        set curr_queue_size [expr ($tmp_docc + $tmp_aocc) / $avg_grain_ ]

        if { $curr_queue_size > 0.0 } {
	    set mean_dp_occupation [expr $tmp_docc / ($avg_grain_ * $curr_queue_size) ]
	    set mean_ack_occupation [expr $tmp_aocc / ($avg_grain_ * $curr_queue_size) ]
        } else {
	    set mean_dp_occupation 0
	    set mean_ack_occupation 0
        }
	
        set avg_count_ 0
        set tmp_docc 0
        set tmp_aocc 0

        puts $avgfile_ "$now $mean_dp_occupation $mean_ack_occupation"
    }
    
    # write DP in queue, ACKs in queue, total trans. DP, total trans. ACKs

    puts $tfile_ "$now [$link_stats_ get-dp-packets-inqueue] [$link_stats_ get-ack-packets-inqueue] [expr [$link_stats_ get-dp-packet-departures] - $last_total_dp_depart] [expr [$link_stats_ get-ack-packet-departures] - $last_total_ack_depart]"

    set last_total_dp_depart [$link_stats_ get-dp-packet-departures]
    set last_total_ack_depart [$link_stats_ get-ack-packet-departures]
    
    $ns_ at [expr $now + $t_] "$self take_sample"
}





Class Dropped

Dropped instproc init { n0 n1 t avg_grain file } {

    $self instvar link_stats_ t_ avg_grain_ tfile_ avgfile_ tcount_
    $self instvar acc_count_ avg_count_
    $self instvar short_total_dp_drop  
    $self instvar short_total_ack_drop 
    $self instvar large_total_dp_drop
    $self instvar large_total_ack_drop
    $self instvar ns_

    set ns_ [Simulator instance]
    set link_stats_ [new LinkStats $n0 $n1]
    set t_ $t
    set avg_grain_ $avg_grain

    set avg_count_ 0
    set acc_count_ 0
    set short_total_dp_drop 0 
    set short_total_ack_drop 0
    set large_total_dp_drop 0
    set large_total_ack_drop 0

    set tfile_ [open "$file-drop-time.dat" w]  
    set avgfile_ [open "$file-drop-avg.dat" w]  

    set now [$ns_ now]

    [Simulator instance] at [expr $now + $t_] "$self take_sample"
}

Dropped instproc take_sample { } {

    $self instvar t_ avg_grain_ link_stats_ avg_count_ acc_count_
    $self instvar tfile_ avgfile_
    $self instvar short_total_dp_drop  
    $self instvar short_total_ack_drop 
    $self instvar large_total_dp_drop
    $self instvar large_total_ack_drop
    $self instvar ns_

    incr avg_count_
    
    set now [[Simulator instance] now] 

    # Remember the sliced throughput can be obtained just
    # once because the reference time is reset.

    if { $avg_count_ == $avg_grain_ } {
	
        puts $avgfile_ "$now [expr ([$link_stats_ get-dp-packet-drops] - $large_total_dp_drop) / $avg_grain_] [expr ([$link_stats_ get-ack-packet-drops] - $large_total_ack_drop) / $avg_grain_]"

        set avg_count_ 0
        set acc_count_ 0
	set large_total_dp_drop [$link_stats_ get-dp-packet-drops]
	set large_total_ack_drop [$link_stats_ get-ack-packet-drops]

    }
    
    puts $tfile_ "$now [expr [$link_stats_ get-dp-packet-drops] - $short_total_dp_drop] [expr [$link_stats_ get-ack-packet-drops] - $short_total_ack_drop]"

    set short_total_dp_drop [$link_stats_ get-dp-packet-drops]
    set short_total_ack_drop [$link_stats_ get-ack-packet-drops]

    $ns_ at [expr $now + $t_] "$self take_sample"    
}



# This is a hash function to map flow-ids (per algorithm) 
# and numbers (ids) to identify them in ns-2.
# A flow-id is composed of the code of the direction {lr,rl},
# the code of the algorithm (snd+rcv conditions) {div,acc,del} 
# and an ordinal number {1,...,L}. Note that the first flow
# is numbered "1". Also, L is the maximum number
# of allowed flows per algorithm, so L=10000 should be enough. 
# Since we have two directions, from 0 to L/2-1 is the space 
# designed to identify "lr" flows and from L/2 to L-1 to
# identify the "rl" flows. 

# TODO: fix it to incorporate the group in the unique id.
proc flow-to-id { flow_code } {


    set code [split $flow_code "-"]
    
    if {[lindex $code 1]=="bg" } {
       set L 10000
    } else {
       # if set to 15000 it'll collide with RL traffic
       set L 1000
    }

    # This is temporal, actually it does not solve the problem
    # of identifying a flow correctly.

    if { [lindex $code 0] == "lr" } {
	if { [string match *div* [lindex $code 2] ] || [string match *oneackpp* [lindex $code 2]] || [string match *delack* [lindex $code 2]]} {
           # puts [ expr 1*$L + [lindex $code 3] - 1]
	    return [ expr 1*$L + [lindex $code 3] - 1] 
	} elseif { [lindex $code 2] == "acc" } {
	    return [ expr 2*$L + [lindex $code 3] - 1] 
	} elseif { [lindex $code 2] == "del" } {
           # puts [ expr 3*$L + [lindex $code 3] - 1]
	    return [ expr 3*$L + [lindex $code 3] - 1] 
        }
        
    } elseif { [lindex $code 0] == "rl" } {
	if { [string match *div* [lindex $code 2] ] || [string match *oneackpp* [lindex $code 2]] || [string match *delack* [lindex $code 2]] } {
           # puts [ expr 1*$L + [lindex $code 3] - 1]
	    return [ expr 1*$L + $L/2 + [lindex $code 3] - 1] 
	} elseif { [lindex $code 2] == "acc" } {
	    return [ expr 2*$L + $L/2 + [lindex $code 3] - 1] 
	} elseif { [lindex $code 2] == "del" } {
           # puts [ expr 3*$L + [lindex $code 3] - 1]
	    return [ expr 3*$L + $L/2 + [lindex $code 3] - 1]  
        }
    } else {
	error "In hash function: An unknown code."
    }
}

proc id-to-flow { id } {

    set L 10000

    set type [ expr $id / $L]
    
    if { $type < 1 || $type > 3 } {
	error "In id-to-flow function: Illegal flow number"
    }

    if { [expr $id - ($id/$L)*$L] < $L/2 } {
	set dir "lr"
	set mult 0
    } else {
	set dir "rl"
	set mult 1
    }

    set type_str { div acc del }

    return "$dir-[lindex $type_str [expr $type-1]]-[expr $id-($id/$L)*$L-$mult*$L/2+1]" 
}


# tcp_list contains the TCP agents from which the throughput will be obtained
# tcp_names are the varible names of the agents for which the throughput is measured

proc print-order-throughput { tcp_list tcp_names } {
  global nodes_char

  set length [llength $tcp_list]

  if { $length == 0 } {
      error "Error: empty TCP list to in print-order-throughput."
  }

  set thr_l {}

  for { set i 0 } { $i < $length } { incr i } {
      set name [ lindex $tcp_names $i ]
      set thr  [ [lindex $tcp_list $i] get-throughput-bps ]
      set nodes_char(thr-[expr $i+1]) $thr	
      lappend thr_l [ list $name $thr ]
  }

  set thr_l [lsort -real -index 1 $thr_l]
  
  for { set i 0 } { $i < $length } { incr i } {
      puts [ lindex $thr_l $i ] 
  }

}

proc print-order-goodput { tcp_list tcp_names } {

  set length [llength $tcp_list]

  if { $length == 0 } {
      error "Error: empty TCP list to in print-order-goodput."
  }

  set good_l {}

  for { set i 0 } { $i < $length } { incr i } {
      set name [ lindex $tcp_names $i ]
      set good  [ [lindex $tcp_list $i] get-goodput-bps ]
      lappend good_l [ list $name $good ]
  }

  set thr_l [lsort -real -index 1 $good_l]
  
  for { set i 0 } { $i < $length } { incr i } {
      puts [ lindex $good_l $i ] 
  }

  return $good_l
}


proc get-list-mean-throughput { tcp_list } {

set length [llength $tcp_list]

  if { $length == 0 } {
      error "Error: empty TCP list to in print-mean-throughput."
  }

  set thr 0
  
  for { set i 0 } { $i < $length } { incr i } {
      set thr  [expr $thr + [[lindex $tcp_list $i] get-throughput-bps] ]      
  }

  set thr [expr $thr/$length]
  
  return $thr
}


proc get-list-mean-goodput { tcp_list } {

set length [llength $tcp_list]

  if { $length == 0 } {
      error "Error: empty TCP list to in print-mean-goodput."
  }

  set good 0
  
  for { set i 0 } { $i < $length } { incr i } {
      set good [expr $good + [[lindex $tcp_list $i] get-goodput-bps] ]      
  }

  set meangood [expr $good/$length]
  
  return $meangood
}



# search inside a list of lists and return the relative
# position inside the more general list

proc lsearchn { args } {
    set argc [llength $args]
    set patt [lindex $args end]
    set list [lindex $args end-1]
    set options [lrange $args 0 end-2]
    set index 0
    foreach sublist $list {
	set return [lsearch $options $sublist $patt]
	if {$return != -1} {
	    break
	}
	incr index
    }
    if {$return eq -1} {
        set index -1
    }
    return $index
}


proc print-position-in-list { tcp_list tcp_names flow_name } {

set length [llength $tcp_list]

if { $length == 0 } {
    error "Error: empty TCP list to in print-order-throughput."
}

set thr_l {}

for { set i 0 } { $i < $length } { incr i } {
    set name [ lindex $tcp_names $i ]
    set thr  [ [lindex $tcp_list $i] get-throughput-bps ]
    lappend thr_l [ list $name $thr ]
}

set thr_l [lsort -real -index 1 $thr_l]

set pos [ lsearchn -glob $thr_l $flow_name  ]

return "[expr $pos+1]/[llength $thr_l]"

}

