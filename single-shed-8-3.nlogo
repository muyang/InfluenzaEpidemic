turtles-own
[
  infected?           ;; if true, the turtle is infectious
  resistant?          ;; if true, the turtle can't be infected
  virus-check-timer   ;; number of ticks since this turtle's last virus-check
]
breed [ducks duck]
breed [foods food]
globals [case sum-of-b black-patches water? edge? water-patches foods-patches dt]

ducks-own [water-time eat-time flockmates  nearest-neighbor age virus-per-day r u k q c p b v1 v2 v3 v4 x1 x2 x3 x4 v z]
patches-own [droplet chemical air-chemical]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-nodes
  set dt 1 / 1440
  draw-box
  ;set-default-shape ducks "circle"
  ;let x 2
  ;repeat 25 [create-foods 1 [setxy x 3 set size 1 set color yellow set shape "circle" ] set x x + 2]
  ;let x2 2
 ; repeat 25 [create-foods 1 [setxy x2 7 set size 1 set color yellow set shape "circle" ] set x2 x2 + 2]
  
  
  ask foods [set hidden? true ask neighbors [set pcolor yellow] ]

  create-ducks number-of-nodes
                    [ set size 0.5
                      set color green
                      set infected? false
                      set resistant? false
                      set water-time random 2880  ;;2 hours
                      set eat-time random 2880
                      set r 2.5
                      set p 2;random 1 + 1
                      set c 1;random 1
                      set q 2;random 0.4 + 2
                      set k 1;random 1
                      set b 0.1;random 0.1
                      set u 0.6;random 0.8 + 1
                    ]  
  ask ducks [ move-to one-of black-patches
               rt random-float 360]
end

to draw-box
  
  ask patches
    [ ifelse (pxcor > (max-pxcor - 3)) or (pxcor < (min-pxcor + 3)) or
             (pycor > (max-pycor - 2)) or (pycor < (min-pycor + 2)) or 
             (pycor > max-pycor / 2 - 1 and pycor < max-pycor / 2 + 1)
        
        [ set pcolor grey - 2 set edge? true]
        [ ifelse pxcor mod 4 = 0 [set pcolor blue]
                                   [set pcolor black ] 
        ]
    ]
  ask patches [if pxcor >= 5 and pxcor <= 55 and pxcor mod 2 = 1 and (pycor = 3 or pycor = 7) [set pcolor yellow]]
  set black-patches patches with [pcolor = black]
  set water-patches patches with [pcolor = blue]
  set foods-patches patches with [pcolor = yellow]
  
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ca
  setup-nodes
  ask links [if link-length >= 5 [ask self [die]] ]
  ask n-of initial-outbreak-size ducks [ become-infected ]
  ask links [ set color white ]
  ;do-plotting
end

to walk
  ask ducks [ifelse (ticks mod 24 * 60 >= 23 * 60 or ticks mod 24 * 60 < 5 * 60)
    [fd 0]
    [ifelse patch-ahead 2 = nobody or [edge?] of patch-ahead 2 = true
                 [rt random 180 fd 2][fd 2 rt random 90 lt random 90]
                 
    ]   
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to virus-diffuse 
  ask ducks [if infected? [
        let v-out virus-per-day
        ask patch-here [set air-chemical (air-chemical + v-out / 24 / 60) ]]  
  ]
  
  ask patches [set air-chemical air-chemical * 0.1 ] ;;;; 1 to 0.1 / min

  ask water-patches [let ch air-chemical    ;;1/6 from air into water
                     ifelse chemical + ch - 0.064 / 24 / 60 > 0
                        [set chemical chemical + ch - 0.064 / 24 / 60]
                        [set chemical 0]
  ]
  ask water-patches [ifelse chemical > 0 
                       [let xx pxcor 
                        let yy pycor
                        ifelse yy > max-pycor / 2  [ask water-patches with [pxcor = xx and pycor > max-pycor / 2] [set chemical chemical / 3 set pcolor red] ]
                                                   [ask water-patches with [pxcor = xx and pycor < max-pycor / 2] [set chemical chemical / 3 set pcolor red] ]
                       ]
                       [set pcolor blue]
  ]
  

  ask foods-patches [let ch air-chemical
                     ;let n-eat count ducks-here with [eat-time = 0]
                     ifelse chemical + ch - 0.15 / 10 / 3 / 16 > 0
                         [set chemical chemical + ch - 0.15 / 10 / 3 / 16]
                         [set chemical 0]
  ]
  ask foods-patches [ifelse chemical > 0 
                       [set pcolor red] 
                       [set pcolor yellow]
  ]
end 

to count-infect-day
  ask ducks [if infected? [set age age + 1 
                           set virus-per-day 36.785 * 3.6 * (age / (60 * 24)) / (94.954 + (age / (60 * 24)) ^ 4) / 2.45 * 3.6]]   ;; max=3.6 
end

to go
  ;tick-advance 1 / 86400
  count-infect-day
  ask ducks with [hidden? = false]
  [if ticks mod 1440 < 1380 and ticks mod 1440 >= 300   ;;[5-23]
                [ifelse [pcolor] of patch-ahead 1 = 3
                    [rt random 180 + 90]
                    [ifelse age < 24 * 60 * 2 [fd 0.5 rt random 360]    
                                              [fd 0.1 rt random 360]  ;;if infected-time > 1 day ,v slow 
                    ]
                  set water-time water-time + 1 if water-time > 2880 [set water-time 0]
                  set eat-time eat-time + 1 if eat-time > 2880 [set eat-time 0]
                ]
  ]

  tick
  ask ducks with [hidden? = false and water-time = 0] 
    [move-to one-of water-patches]
  
  ask ducks with [hidden? = false and eat-time = 0] 
    [move-to one-of foods-patches]  
    
  virus-diffuse
  diffuse air-chemical 8 / 9
  spread-virus2
  do-virus-checks
  
  if ticks mod 1440 = 0 [ 
    set-current-plot "Network Status"
    set-current-plot-pen "susceptible"
    plot (count ducks with [color = green]) ;/ (number-of-nodes) * 100
    set-current-plot-pen "infected"
    plot (count ducks with [color = red]) ;/ (number-of-nodes) * 100
    set-current-plot-pen "resistant"
    plot (count ducks with [color = grey]) ;/ (number-of-nodes) * 100
    set-current-plot-pen "removed"
    plot (count ducks with [color = black]) ;/ (number-of-nodes) * 100
  ]
end

to become-infected  ;; turtle procedure
  set infected? true
  set resistant? false
  set color red
end

to become-susceptible  ;; turtle procedure
  set infected? false
  set resistant? false
  set color green
end

to become-resistant  ;; turtle procedure
  set infected? false
  set resistant? true
  set color gray
end


to spread-virus2
  ask ducks with [color = green]
    [ifelse water-time = 0 or eat-time = 0
      [ ask patch-here 
        [ set virus-spread-chance (chemical + air-chemical) * 0.052 * 4]
      if random-float 1 < virus-spread-chance 
        [ become-infected ] 
      ] 
      [ ask patch-here 
        [ set virus-spread-chance air-chemical * 0.052 * 4]
      if random-float 1 < virus-spread-chance 
        [ become-infected ] 
      ] 
    ]
end

to do-virus-checks
  ask ducks with [color = red and age > 5 * 24 * 60]  ;and virus-check-timer = 0]
       [ifelse random-float 100 < recovery-chance
                [set infected? true set color red - 1]
                [set hidden? true set color black set infected? false ] 
       ]
  ask ducks with [color = red - 1 and age > 14 * 24 * 60]
       [set color grey set infected? false set age 0] 
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go2
  count-infect-day
  ask ducks with [hidden? = false]
  [if ticks mod 1440 < 1380 and ticks mod 1440 >= 300   ;;[5-23]
                [ifelse [pcolor] of patch-ahead 1 = 3
                    [rt random 180 + 90]
                    [ifelse age < 24 * 60 * 2 [fd 0.5 rt random 360]    
                                              [fd 0.1 rt random 360]  ;;if infected-time > 1 day ,v slow 
                    ]
                  set water-time water-time + 1 if water-time > 2880 [set water-time 0]
                  set eat-time eat-time + 1 if eat-time > 2880 [set eat-time 0]
                ]
  ]

  tick
  ask ducks with [hidden? = false and water-time = 0] 
    [move-to one-of water-patches]
  
  ask ducks with [hidden? = false and eat-time = 0] 
    [move-to one-of foods-patches]  
    
  virus-diffuse
  diffuse air-chemical 8 / 9
  
  ask ducks [
    set v (v + [chemical] of patch-here + [air-chemical] of patch-here ) * 1
    let dv v * (r - p * x1 - q * z) * dt
    let dx1 (c * v - b * x1 - u * v * z) * dt
    let dz (k * v - b * z - u * v * z) * dt
    set v v + dv
    set x1 x1 + dx1
    set z z + dz
  ]
  
  ask ducks [if x1 > 0.0004 and v / x1 > 10[die]]
  
  if ticks mod 144 = 0 [ 
    set-current-plot "Network Status"
    
    set-current-plot-pen "removed"
    plot (number-of-nodes - count ducks ) ;/ (number-of-nodes) * 100
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
260
10
1069
185
-1
-1
13.1
1
1
1
1
1
0
0
0
1
0
60
0
10
1
1
1
ticks

SLIDER
24
202
229
235
recovery-chance
recovery-chance
0.0
100
57
0.1
1
%
HORIZONTAL

SLIDER
24
132
230
165
virus-spread-chance
virus-spread-chance
0.0
10.0
1.0774462575319537E-8
0.1
1
%
HORIZONTAL

PLOT
429
200
826
362
Network Status
time
% of nodes
0.0
52.0
0.0
100.0
true
true
PENS
"susceptible" 1.0 0 -10899396 true
"infected" 1.0 0 -2674135 true
"resistant" 1.0 0 -7500403 true
"removed" 1.0 0 -16777216 true

SLIDER
25
15
230
48
number-of-nodes
number-of-nodes
10
2800
2800
5
1
NIL
HORIZONTAL

SLIDER
24
167
229
200
virus-check-frequency
virus-check-frequency
0
24
24
1
1
ticks
HORIZONTAL

SLIDER
25
85
230
118
initial-outbreak-size
initial-outbreak-size
1
40
4
1
1
NIL
HORIZONTAL

SLIDER
25
50
230
83
average-node-degree
average-node-degree
1
number-of-nodes - 1
6
1
1
NIL
HORIZONTAL

MONITOR
548
372
604
421
R
count ducks with [color = grey]
17
1
12

MONITOR
486
372
543
421
I
count ducks with [infected?]
17
1
12

MONITOR
426
372
483
421
S
count ducks with [color = green]
17
1
12

PLOT
940
200
1253
358
Degree Distribution
degree
nodes num
1.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 2 -16777216 true

PLOT
942
362
1253
511
Degree Distribution (log-log)
log(degree)
log(nodes num)
0.0
0.3
0.0
0.3
true
false
PENS
"default" 1.0 2 -16777216 true

BUTTON
257
199
320
232
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
256
243
329
276
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
608
371
660
420
removed
count ducks with [color = black]
17
1
12

MONITOR
109
383
198
432
NIL
count links
17
1
12

MONITOR
1160
62
1255
111
CC1
2 * count links / (count turtles * count turtles - 1 )
17
1
12

PLOT
946
524
1255
674
b
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 1 -16777216 true

MONITOR
129
316
186
365
b
sum-of-b\n
17
1
12

MONITOR
372
200
429
249
NIL
ticks
17
1
12

BUTTON
55
281
118
314
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
255
339
318
372
NIL
go2
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
718
387
784
420
±äÒì1
ask ducks [set v2 v1 * 0.2] \nask ducks [set v1 v1 - v2]\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
784
386
850
419
±äÒì2
ask ducks \n[set v3 v1 * 0.2 + v2 * 0.2\n set v1 v1 * 0.8\n set v2 v2 * 0.8]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
850
386
916
419
±äÒì3
ask ducks [\nset v4 v1 * 0.2 + v2 * 0.2 + v3 * 0.2\nset v1 v1 * 0.8\nset v2 v2 * 0.8\nset v3 v3 * 0.8]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
454
451
913
484
NIL
ask n-of 100 ducks [if v1 > 0 [set u u + 0.1 set r r * 1.5]]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

@#$#@#$#@
WHAT IS IT?
-----------
This model demonstrates the spread of a virus through a network.  Although the model is somewhat abstract, one interpretation is that each node represents a computer, and we are modeling the progress of a computer virus (or worm) through this network.  Each node may be in one of three states:  susceptible, infected, or resistant.  In the academic literature such a model is sometimes referred to as an SIR model for epidemics.


HOW IT WORKS
-----------
Each time step (tick), each infected node (colored red) attempts to infect all of its neighbors.  Susceptible neighbors (colored green) will be infected with a probability given by the VIRUS-SPREAD-CHANCE slider.  This might correspond to the probability that someone on the susceptible system actually executes the infected email attachment.
Resistant nodes (colored gray) cannot be infected.  This might correspond to up-to-date antivirus software and security patches that make a computer immune to this particular virus.

Infected nodes are not immediately aware that they are infected.  Only every so often (determined by the VIRUS-CHECK-FREQUENCY slider) do the nodes check whether they are infected by a virus.  This might correspond to a regularly scheduled virus-scan procedure, or simply a human noticing something fishy about how the computer is behaving.  When the virus has been detected, there is a probability that the virus will be removed (determined by the RECOVERY-CHANCE slider).

If a node does recover, there is some probability that it will become resistant to this virus in the future (given by the GAIN-RESISTANCE-CHANCE slider).

When a node becomes resistant, the links between it and its neighbors are darkened, since they are no longer possible vectors for spreading the virus.


HOW TO USE IT
-------------
Using the sliders, choose the NUMBER-OF-NODES and the AVERAGE-NODE-DEGREE (average number of links coming out of each node).

The network that is created is based on proximity (Euclidean distance) between nodes.  A node is randomly chosen and connected to the nearest node that it is not already connected to.  This process is repeated until the network has the correct number of links to give the specified average node degree.

The INITIAL-OUTBREAK-SIZE slider determines how many of the nodes will start the simulation infected with the virus.

Then press SETUP to create the network.  Press GO to run the model.  The model will stop running once the virus has completely died out.

The VIRUS-SPREAD-CHANCE, VIRUS-CHECK-FREQUENCY, RECOVERY-CHANCE, and GAIN-RESISTANCE-CHANCE sliders (discussed in "How it Works" above) can be adjusted before pressing GO, or while the model is running.

The NETWORK STATUS plot shows the number of nodes in each state (S, I, R) over time.


THINGS TO NOTICE
--------------------
At the end of the run, after the virus has died out, some nodes are still susceptible, while others have become immune.  What is the ratio of the number of immune nodes to the number of susceptible nodes?  How is this affected by changing the AVERAGE-NODE-DEGREE of the network?


THINGS TO TRY
-------------
Set GAIN-RESISTANCE-CHANCE to 0%.  Under what conditions will the virus still die out?   How long does it take?  What conditions are required for the virus to live?  If the RECOVERY-CHANCE is bigger than 0, even if the VIRUS-SPREAD-CHANCE is high, do you think that if you could run the model forever, the virus could stay alive?


EXTENDING THE MODEL
-------------------
The real computer networks on which viruses spread are generally not based on spatial proximity, like the networks found in this model.  Real computer networks are more often found to exhibit a "scale-free" link-degree distribution, somewhat similar to networks created using the Preferential Attachment model.  Try experimenting with various alternative network structures, and see how the behavior of the virus differs.

Suppose the virus is spreading by emailing itself out to everyone in the computer's address book.  Since being in someone's address book is not a symmetric relationship, change this model to use directed links instead of undirected links.

Can you model multiple viruses at the same time?  How would they interact?  Sometimes if a computer has a piece of malware installed, it is more vulnerable to being infected by more malware.

Try making a model similar to this one, but where the virus has the ability to mutate itself.  Such self-modifying viruses are a considerable threat to computer security, since traditional methods of virus signature identification may not work against them.  In your model, nodes that become immune may be reinfected if the virus has mutated to become significantly different than the variant that originally infected the node.


RELATED MODELS
--------------
Virus, Disease, Preferential Attachment, Diffusion on a Directed Network


NETLOGO FEATURES
----------------
Links are used for modeling the network.  The LAYOUT-SPRING primitive is used to position the nodes and links such that the structure of the network is visually clear.


HOW TO CITE
-----------
If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:
- Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:
- Copyright 2008 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork for terms of use.


COPYRIGHT NOTICE
----------------
Copyright 2008 Uri Wilensky. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) this copyright notice is included.
b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ducks with [color = red]</metric>
    <metric>count ducks with [color = grey]</metric>
    <enumeratedValueSet variable="virus-check-frequency">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-resistance-chance">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virus-spread-chance">
      <value value="-0.16287113173780277"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-chance">
      <value value="20.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="18"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
