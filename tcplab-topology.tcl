

# This are helper functions to create the background traffic.


# TODO: Temporal procedure for setting RED parameters.

 proc set_red_params { redq psize qlim min_th max_th bytes wait gentle} {

     error "read RED article...";

 }    


# Create a specified number of connections all with the 
# same delay to the bottleneck router. All the TCP connection
# will experience the same RTT.
# The active opening of the connection goes from first-router
# to second-router.
 
proc create-fix-delaylink { lnode rnode bw delay } {

    global ns 

    $ns simplex-link $lnode $rnode $bw $delay DropTail
    $ns simplex-link $rnode $lnode $bw $delay DropTail

# TODO: Is there a way of automatically calculating the 
# TODO: queue sizes? so that we could save some memory or
# TODO: improve performance.

    [[$ns link $lnode $rnode] queue] set limit_ 1000
    [[$ns link $rnode $lnode] queue] set limit_ 100

}

# Create a specified number of connections all with a variable
# RTT. Every link will get a random value between del-l and del-r 
# specified in miliseconds.

# TODO: verify the delay calculation

proc create-var-delaylink { lnode rnode del_l del_r bw del_rng } {

    global ns
    
    set diff_delay [new RandomVariable/Uniform]
    $diff_delay set min_ $del_l
    $diff_delay set max_ $del_r
    $diff_delay use-rng $del_rng
    
    set node_delay [expr [$diff_delay value]/1000]
    $ns simplex-link $lnode $rnode $bw $node_delay DropTail
    $ns simplex-link $rnode $lnode $bw $node_delay DropTail
    [[$ns link $lnode $rnode] queue] set limit_ 1000
    [[$ns link $rnode $lnode] queue] set limit_ 100

}

