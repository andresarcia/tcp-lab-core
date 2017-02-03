# nam scaling
set x_init 500
set y_init 500
set y_incr 10.5
set x_incr 20.5
set x_scale 10ms

#Code that create the nodes at the extreme of the bottleneck
for {set i 1} {$i <= $max_nodes} {incr i} {
    set left($i) [$ns node]
    $left($i) set X_ $x_init
    $left($i) set Y_ [expr $y_init + $y_incr*($i-1)]

    set right($i) [$ns node]
    $right($i) set X_ [expr $x_init + (([time_parse $btneck_delay] + [time_parse $node_delay])/[time_parse $x_scale])*$x_incr]
    $right($i) set Y_ [expr $y_init + $y_incr*($i-1)]
}

#Code to draw the position of the routers in NAM

set router(1) [$ns node]
$router(1) set X_ [expr $x_init +  ([time_parse $node_delay]/[time_parse $x_scale])*$x_incr]
$router(1) set Y_ [expr $y_init +  ($y_incr*$max_nodes)/2]
set router(2) [$ns node]
$router(2) set X_ [expr $x_init +  ([time_parse $btneck_delay]/[time_parse $x_scale])*$x_incr]
$router(2) set Y_ [expr $y_init +  ($y_incr*$max_nodes)/2]