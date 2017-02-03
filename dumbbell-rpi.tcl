# Automatic dumbbell topology
# Andres ARCIA
#------------------------------------------------------- 
# Create a new simulator object.

source $env(NS)/tcl/rpi/tcp-stats.tcl
source $env(NS)/tcl/rpi/link-stats.tcl
source $env(NS)/tcl/rpi/script-tools.tcl
source $env(NS)/tcl/rpi/graph.tcl
source getopt.tcl

set ns [new Simulator]

global opt

set opt(opt_conv) {
    { l n_left }
    { r n_right }
    { snd tcp_sender }
    { rcv tcp_sink }
    { simt duration }
    { dtime dw-start-time }
    { fn filename }
    { ty type }
    { nam usenam }
    { buf buffer_size }
    { dpdp divackspdp }
    { tr tracing }
    { snd_gr snd_graph }
    { rcv_gr rcv_graph }
    { ss segsize }
    { fs filesize }
    { atk attack }
    { pace pacedivacks }
    { arwnd auto_rwnd }
    { assth auto_ssth }
    { btneck bt_bw }
    { ts timestamps }
    { dacks delayacks }
}

set opt(n_left)        0
set opt(n_right)       0
set opt(tcp_sender)    Agent/TCP/FullTcp/Newreno
set opt(tcp_sink)      Agent/TCP/FullTcp/Newreno
set opt(simt)          30
set opt(dw-start-time) 0.0 
set opt(filename)      "experiment"
set opt(type)          "avg"
set opt(usenam)        "no"
set opt(duration)      30
set opt(buffer_size)   20
set opt(divackspdp)    2
set opt(tracing)       0
set opt(snd_graph)     "none"
set opt(rcv_graph)     "none"
set opt(segsize)       460
set opt(filesize)      15000
set opt(attack)        "yes"
set opt(pacedivacks)   "no"
set opt(auto_rwnd)     "no"
set opt(auto_ssth)     "no"
set opt(bt_bw)         1.5Mb
set opt(timestamps)    "no"
set opt(delayacks)     "no"

my_getopt $argv

#if { [file exists $opt(filename).set] == 0} {
#    puts "Error: file $opt(filename).set does not exists.\n";
#    exit 1;
#}

# -------
# tracing
# -------

if { $opt(usenam) == "yes" } {
set namfile [open $opt(filename).nam w]
$ns namtrace-all $namfile
}

# ------------------------------
# file for statistics and traces
# ------------------------------ 

if { $opt(tracing) } {
    set tracefd  [open $opt(filename).tr w]
    $ns trace-all $tracefd
}

# The file for statistics is open for append this new simulation 
if { $opt(type) == "avg" } { 
set stats_file [open $opt(filename).stats a]
}

# ----------------
# general settings
# ----------------

# setting bandwidth and delays
set btneck_delay 50ms
set node_delay 5ms
set node_bw 10Mb

# nam scaling
set x_init 500
set y_init 500
set y_incr 10.5
set x_incr 20.5
set x_scale 10ms

if {$opt(n_left) >= $opt(n_right)} {
    set max_nodes $opt(n_left) 
} else {
    set max_nodes $opt(n_right)
}

#--------------------------------------------------
# nodes at the left and the right of the bottleneck
#--------------------------------------------------

for {set i 1} {$i <= $max_nodes} {incr i} {
    set left($i) [$ns node]
    $left($i) set X_ $x_init
    $left($i) set Y_ [expr $y_init + $y_incr*($i-1)]

    set right($i) [$ns node]
    $right($i) set X_ [expr $x_init + (([time_parse $btneck_delay] + [time_parse $node_delay])/[time_parse $x_scale])*$x_incr]
    $right($i) set Y_ [expr $y_init + $y_incr*($i-1)]
}

set router(1) [$ns node]
$router(1) set X_ [expr $x_init +  ([time_parse $node_delay]/[time_parse $x_scale])*$x_incr]
$router(1) set Y_ [expr $y_init +  ($y_incr*$max_nodes)/2]
set router(2) [$ns node]
$router(2) set X_ [expr $x_init +  ([time_parse $btneck_delay]/[time_parse $x_scale])*$x_incr]
$router(2) set Y_ [expr $y_init +  ($y_incr*$max_nodes)/2]

# links between nodes

set diff_delay [new RandomVariable/Uniform]
$diff_delay set min_ 5 
$diff_delay set max_ 25
set rng1 [new RNG]
# to be seeded heuristically:
$rng1 seed 0 
$diff_delay use-rng $rng1

for {set i 1} {$i <= $max_nodes} {incr i} {

# left

    set node_delay [expr [$diff_delay value]/1000]
    $ns simplex-link $left($i) $router(1) $node_bw $node_delay DropTail
    $ns simplex-link $router(1) $left($i) $node_bw $node_delay DropTail
    $ns simplex-link-op $left($i) $router(1) queuePos 0.5
    $ns simplex-link-op $router(1) $left($i) queuePos 0.5
    [[$ns link $left($i) $router(1)] queue] set limit_ [expr ($opt(filesize)/$opt(segsize))]
    [[$ns link $router(1) $left($i)] queue] set limit_ 20

# right

    set node_delay [expr [$diff_delay value]/1000]
    $ns simplex-link $right($i) $router(2) $node_bw $node_delay DropTail
    $ns simplex-link $router(2) $right($i) $node_bw $node_delay DropTail
    $ns simplex-link-op $right($i) $router(2) queuePos 0.5
    $ns simplex-link-op $router(2) $right($i) queuePos 0.5
    [[$ns link $right($i) $router(2)] queue] set limit_ [expr 45*84]
    [[$ns link $router(2) $right($i)] queue] set limit_ 20
}

#------------
# bottleneck DROPTAIL
#------------

$ns simplex-link $router(1) $router(2) $opt(bt_bw) $btneck_delay DropTail
$ns simplex-link $router(2) $router(1) $opt(bt_bw) $btneck_delay DropTail

#$ns duplex-link $router(1) $router(2) $btneck_bw $btneck_delay DropTail

# ---
# RPI
# ---
set stats [new LinkStats $router(1) $router(2)]
# reset statistics in order to dismiss the first part of the simulation
# $ns at 0.1 "$stats reset"

# The study for the queue size is for: 5, 8, 13, 21, 34 packets

[[$ns link $router(1) $router(2)] queue] set limit_ $opt(buffer_size) 

#[[$ns link $router(1) $router(2)] queue] set queue_in_bytes_ true
#[[$ns link $router(1) $router(2)] queue] set mean_pkt_size 916

[[$ns link $router(2) $router(1)] queue] set limit_ $opt(buffer_size) 

#[[$ns link $router(2) $router(1)] queue] set queue_in_bytes_ true
#[[$ns link $router(2) $router(1)] queue] set mean_pkt_size 916

#---------------
# bottleneck RED
#---------------

# Queue/RED set bytes_ true
# Queue/RED set queue_in_bytes_ true
# Queue/RED set mean_pktsize_ 1500
# Queue/RED set setbit_ false
# Queue/RED set drop_tail_ true

# Queue set limit_ 70

# $ns simplex-link $router(1) $router(2) $btneck_bw $btneck_delay RED
# $ns simplex-link $router(2) $router(1) $btneck_bw $btneck_delay RED

# ---------------
# TCP common settings
# ---------------
# DO NOT WORK IN FullTCP: $opt(tcp_sender) set packetSize_ 1460

if { $opt(auto_rwnd) == "yes" } {
# Announcing a convenient receiver window, which is configured to the
# double of the BDP in number of packets of segment size. 
    Agent/TCP/FullTcp set window_ [expr 2*([bw_parse $opt(bt_bw)]*[delay_parse $btneck_delay]/8)/$opt(segsize)]
} else {
    Agent/TCP/FullTcp set window_ 1000000
}

if { $opt(auto_ssth) == "yes" } {
# Tune the ssthresh to half the BDP
    Agent/TCP/FullTcp set ssthresh_ [expr ([bw_parse $opt(bt_bw)]*[delay_parse $btneck_delay]/8)/$opt(segsize)]
} else {
    Agent/TCP/FullTcp set ssthresh_ 1000000
}

if { $opt(timestamps) == "yes" } {
    Agent/TCP/FullTcp set timestamps_ true
} else {
    Agent/TCP/FullTcp set timestamps_ false
}
# fix settings for divacks
Agent/TCP/FullTcp set ack_counter 1000000 
Agent/TCP/FullTcp set start_spack false 
# Initial Window for delay ACKs
Agent/TCP/FullTcp set windowInit_ 2
# _NO_ limits for cwnd openness in recovery
Agent/TCP/FullTcp set maxcwnd_ 0
# Nagle
Agent/TCP/FullTcp set nodelay_ true
# variable settings
Agent/TCP/FullTcp set acks_per_datapacket $opt(divackspdp)
# Activate delay acks 
if { $opt(delayacks) == "yes" } {
    Agent/TCP/FullTcp set segsperack_ 2
} else {
    Agent/TCP/FullTcp set segsperack_ 1
}

# -------------------------------
# divack settings (just one flow)
# -------------------------------
  
#$ns attach-agent $router(1) $sender_agent($j)

set divack_l_node [$ns node]
set divack_r_node [$ns node]
set divack_bw    10Mb
set divack_delay 0ms

# left node connection
$ns simplex-link $divack_l_node $router(1) $divack_bw $divack_delay DropTail
$ns simplex-link $router(1) $divack_l_node $divack_bw $divack_delay DropTail
[[$ns link $divack_l_node $router(1)] queue] set limit_ [expr $opt(filesize)/$opt(segsize)]
[[$ns link $router(1) $divack_l_node] queue] set limit_ 20

# right node connection 
$ns simplex-link $divack_r_node $router(2) $divack_bw $divack_delay DropTail
$ns simplex-link $router(2) $divack_r_node $divack_bw $divack_delay DropTail
[[$ns link $divack_r_node $router(2)] queue] set limit_ [expr 45*84]
[[$ns link $router(2) $divack_r_node] queue] set limit_ 20

#set result [lindex [create-ftp-over-tcp-agent $opt(tcp_sender) $opt(tcp_sink) $divack_l_node $divack_r_node 0.0 1] 0]
#set divack_sender   [lindex $result 0]
#set divack_sink     [lindex $result 1]

set divack_sender   [new $opt(tcp_sender)]
#$ns attach-agent $divack_l_node $divack_sender
$ns attach-agent $router(1) $divack_sender
$divack_sender      set segsize_ $opt(segsize) 
$divack_sender      set reno_fastrecov_ true
$divack_sender      set open_cwnd_on_pack_ true
#$divack_sender      set timestamps_ false

# The one that makes the attack
set divack_sink   [new $opt(tcp_sink)]
#$ns attach-agent $divack_r_node $divack_sink
$ns attach-agent $router(2) $divack_sink
$divack_sink        set packetSize_ 40
$divack_sink        set delack_interval_ 200ms
#$divack_sink        set timestamps_ false

# The Token Bucket to pace divacks... :-)
if {$opt(pacedivacks) == "yes"} {
    set tbf [new TBF]
    $tbf set bucket_ [expr [$divack_sink set packetSize_]*8]
    $tbf set rate_ [expr [$divack_sink set packetSize_]*$opt(divackspdp)*[bw_parse $opt(bt_bw)]/$opt(segsize)]
    $tbf set qlen_ [expr 45*84]
    $ns attach-tbf-agent $divack_r_node $divack_sink $tbf
}

$ns connect $divack_sender $divack_sink
$divack_sink        listen

#set ftp [new Application/FTP]
#$ftp attach-agent $divack_sender
#$ns at 1.0 "$ftp start"

# An infinite? FTP sender
#set divack_traffic  [lindex $result 2]

# Send a file of size $opt(filesize)
$ns at $opt(dw-start-time) "$divack_sender sendmsg $opt(filesize) FILE_EOF"

# Start performing the attack!
if {$opt(attack) == "yes"} {
$ns at 0.0 "$divack_sink set start_spack true"
}

if {$opt(snd_graph) == "none" && $opt(rcv_graph) == "none"} {
    $divack_sender proc done_data {} "finish"
} else {
    $divack_sender proc done_data {} "finish 1"
}

#--------------------------------
# agents: tcp, sinks, application
#--------------------------------
# 

# Connect agents.
# From left to right 
# to avoid flows syncronization
set unsync_num [new RandomVariable/Uniform]
$unsync_num set min_ 0.1
$unsync_num set max_ 5
set rng [new RNG]
# to be seeded heuristically:
$rng seed 0
$unsync_num use-rng $rng

# Old line (may be useful):
# $ns at 0.0 "$traffic_source($i) start"
# $ns at $opt(duration) "$traffic_source($i) stop"

# first $n_left agents are intended for the nodes at the left of the btneck.

set total_agents [expr $opt(n_left) + $opt(n_right)]

# counter for all connections, number 1 is the divack connection
set j 1

# flows from left to right
for {set i 1} {$i <= $opt(n_left)} {incr i} {
    
    set result [lindex [create-ftp-over-tcp-agent $opt(tcp_sender) $opt(tcp_sink) $left($i) $right($i) 0.0 [expr $j+1] ] 0]
    
    set sender_agent($j) [lindex $result 0]
    $sender_agent($j) set segsize_ $opt(segsize) 
    $sender_agent($j) set reno_fastrecov_ true
    $sender_agent($j) set open_cwnd_on_pack_ true
    
    set sink_agent($j)   [lindex $result 1] 
    $sink_agent($j) set segsperack_ 1 
    $sink_agent($j) set packetSize_ 40
    $sink_agent($j) set delack_interval_ 200ms
    $sink_agent($j) listen
    
    set traffic_source($j) [lindex $result 2] 
    $ns at [$unsync_num value] "$traffic_source($j) start"
    
    incr j
 }

# flows from right to left
 for {set i 1} {$i <= $opt(n_right)} {incr i} {

     set result [lindex [create-ftp-over-tcp-agent $opt(tcp_sender) $opt(tcp_sink) $right($i) $left($i) 0.0 [expr $j + 1]] 0]

     set sender_agent($j) [lindex $result 0]
     $sender_agent($j) set segsize_ $opt(segsize) 
     $sender_agent($j) set reno_fastrecov_ true
     $sender_agent($j) set open_cwnd_on_pack_ true
     
     set sink_agent($j)   [lindex $result 1] 
     $sink_agent($j) set segsperack_ 1 
     $sink_agent($j) set packetSize_ 40
     $sink_agent($j) set delack_interval_ 200ms
     $sink_agent($j) listen

     set traffic_source($j) [lindex $result 2] 
     $ns at [$unsync_num value] "$traffic_source($j) start"

     incr j
 }


# -------------------------------------------
# Statistics for data packet and ACK counting

set last_total_dp_depart 0
set last_total_ack_depart 0
set last_total_dp_drop 0
set last_total_ack_drop 0
set t_count 0
set tmp_docc 0
set tmp_aocc 0
set mean_dp_occupation 0
set mean_ack_occupation 0

if { $opt(type) == "time" }  {
   set timely_graph_file [open $opt(filename).tgraph w]
   set timely_avg_graph_file [open $opt(filename).avg-tgraph w]
}


proc timely_graphs_ {dt} {

    global ns timely_graph_file timely_avg_graph_file stats 
    global last_total_dp_depart last_total_ack_depart 
    global last_total_dp_drop last_total_ack_drop t_count
    global tmp_docc tmp_aocc router
    
    set now [$ns now]

    incr t_count

    if {$t_count < 10} {
        set tmp_docc [expr $tmp_docc + [$stats get-dp-packets-inqueue]]
        set tmp_aocc [expr $tmp_aocc + [$stats get-ack-packets-inqueue]]
    } else { 
# set queue_size [[[$ns link $router(1) $router(2)] queue] set limit_]
        set curr_queue_size [expr ($tmp_docc + $tmp_aocc) / 10.0]

        if { $curr_queue_size > 0.0 } {            
        set mean_dp_occupation [expr $tmp_docc / (10.0 * $curr_queue_size) ]
        set mean_ack_occupation [expr $tmp_aocc / (10.0 * $curr_queue_size) ]
        } else {
        set mean_dp_occupation 0
        set mean_ack_occupation 0
        }

        set t_count 0
        set tmp_docc 0
        set tmp_aocc 0

        puts $timely_avg_graph_file "[format %.2f $now]  $mean_dp_occupation $mean_ack_occupation"
    }

    puts $timely_graph_file "[format %.2f $now] [$stats get-dp-packets-inqueue] [$stats get-ack-packets-inqueue] [expr [$stats get-dp-packet-departures] - $last_total_dp_depart] [expr [$stats get-ack-packet-departures] - $last_total_ack_depart] [expr [$stats get-dp-packet-drops] - $last_total_dp_drop] [expr [$stats get-ack-packet-drops] - $last_total_ack_drop]"
    
    set last_total_dp_depart [$stats get-dp-packet-departures]
    set last_total_ack_depart [$stats get-ack-packet-departures]
    set last_total_dp_drop [$stats get-dp-packet-drops]
    set last_total_ack_drop [$stats get-ack-packet-drops]
    
    $ns at [expr $now + $dt] "timely_graphs_ $dt"
}


# Run the simulation
proc finish { { show_graph 0 } } {
    
    global ns argv opt divack_sender stats max_nodes stats_file
    global timely_graph_file timely_avg_graph_file sender_agent
    global usenam tracevar_ch1 namfile

    if { $show_graph == 1 } {

        if { $opt(snd_graph) != "none" } {
            global g_snd_
            $g_snd_ display
        }
        
        if { $opt(rcv_graph) != "none" } {
            global g_rcv_
            $g_rcv_ display
        }
        
        [Graph set plot_device_] close
    }

    if { $opt(type) == "time" }  {
    close $timely_graph_file
    close $timely_avg_graph_file
    }

# $ns flush-trace
    
    if { $opt(usenam) == "yes" } {
	close $namfile
	exec nam -r 2000.000000us $opt(filename).nam &	
    }
    
    set tcp_bkgrnd_l {}
   
    for {set i 1} {$i <= $max_nodes} {incr i} {
        lappend tcp_bkgrnd_l $sender_agent($i)
    }
 
    set divack_l {}

    lappend divack_l $divack_sender

# __REMINDER__
# remember to update experiments.pl for _labels_ and _units_

    if { $opt(type) == "avg" }  {

# before it was ndatabytes_
        puts $stats_file "[Agent/TCP/FullTcp set acks_per_datapacket] $opt(buffer_size) [$divack_sender set ack_] [get-total-data-packets $divack_l] [get-total-retransmitted-packets $divack_l ] [get-total-retransmission-timeouts $divack_l] [expr [$ns now] - $opt(dw-start-time)]"

    close $stats_file

    }
 
  if { $opt(type) == "stdout" } {
        puts "echo \"[Agent/TCP/FullTcp set acks_per_datapacket] $opt(buffer_size) [$divack_sender set ack_] [get-total-data-packets $divack_l] [get-total-retransmitted-packets $divack_l ] [get-total-retransmission-timeouts $divack_l] [expr [$ns now] - $opt(dw-start-time)]\" > $opt(filename).stats"
  }

#    close $tracevar_ch1

    exit 0
}

# -------
# TRACING
# -------

if { $opt(snd_graph) != "none" } {
    Graph set plot_device_ [new filedev]
    set g_snd_ [new Graph/TraceInTime $opt(snd_graph) $divack_sender -1 "$opt(filename)-$opt(snd_graph)"]
    $g_snd_ set title_ "$opt(filename)-$opt(snd_graph)"
}

if { $opt(rcv_graph) != "none" } {
    Graph set plot_device_ [new gnuplot]
    set g_rcv_ [new Graph/TraceInTime $opt(rcv_graph) $divack_sink -1 "$opt(filename)-$opt(snd_graph)"]
    $g_rcv_ set title_ "$opt(filename)-$opt(rcv_graph)"
}


# The cwnd diminishes its size exponentilly, halving the cwnd every RTT
# set cwnd_g [new Graph/TraceInTime cwnd_ $sender_agent(1)]
# $cwnd_g set title_ "cwnd growth"

#Graph set plot_device_ [new xgraph]
#set cwnd_g [new Graph/TraceInTime t_seqno_ $sender_agent(1)]
#$cwnd_g set title_ "sequence number"

# start a timely graph every 0.1 sec

if { $opt(type) == "time" }  {
$ns at 40.0 "timely_graphs_ 0.1"
}

#$ns at $opt(duration) "finish 1"

$ns run
