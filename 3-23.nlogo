 

extensions [ gis ]
globals [ foods-dataset
          points-dataset
          roads-dataset
          pools-dataset
          image-dataset
          sheds-dataset 
          elevation-dataset
          cesspool-dataset
          mice-dataset
          cesspoint-dataset
         
                    
          clustering-coefficient               
          average-path-length                  
          clustering-coefficient-of-lattice   
          average-path-length-of-lattice       
          infinity                             
                                         
          case
          ]
breed [ nodes node ]

breed [ ducks duck ]
ducks-own [situation host keeper-num shed-name duck-weight age]

breed [ shed-nodes shed-node ]
shed-nodes-own [val new-val end-node target keeper shed-node-weight]
breed [ houses house]
breed [ cesspools cesspool ]
breed [ farmers farmer]
farmers-own [ virus-tick2 location target farmer-weight]
breed [ mices mice ]
mices-own [virus-tick ]
breed [ cesspoints cesspoint ]
breed [ road-vertices road-vertice ]
breed [ spinners spinner]
patches-own [ population long country-name elevation lake? cess? house? ]
turtles-own
[
  s-degree 
  infected?           ;; if true, the turtle is infectious
  resistant?          ;; if true, the turtle can't be infected
  virus-check-timer   ;; number of ticks since this turtle's last virus-check
  node-clustering-coefficient
  distance-from-other-turtles   ;; list of distances of this node from other turtles
]

directed-link-breed [active-links active-link]
directed-link-breed [inactive-links inactive-link]

links-own [ current-flow ] 
directed-link-breed [blue-links blue-link]
blue-links-own [ weight ]

undirected-link-breed [green-links green-link]
green-links-own [ weight ]

breed [ foods food]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output

  gis:load-coordinate-system (word "data/" projection ".prj")

  set points-dataset gis:load-dataset "data/house.shp"
  set mice-dataset gis:load-dataset "data/mice.shp"
  set pools-dataset gis:load-dataset "data/pools.shp"      ;"data/countries.shp"
  set sheds-dataset gis:load-dataset "data/shed2.shp"
  set cesspool-dataset gis:load-dataset "data/cesspool.shp"
  set cesspoint-dataset gis:load-dataset "data/cesspoints.shp"
  set image-dataset gis:load-dataset "data/clip_img.asc"
  set roads-dataset gis:load-dataset "data/roads.shp"
  set foods-dataset gis:load-dataset "data/point_h.shp"
  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of points-dataset)
                                                (gis:envelope-of mice-dataset)
                                                (gis:envelope-of pools-dataset)
                                                (gis:envelope-of sheds-dataset)
                                                (gis:envelope-of cesspool-dataset)
                                                (gis:envelope-of image-dataset)
                                                (gis:envelope-of roads-dataset)
                                                (gis:envelope-of foods-dataset)
                                                )
  create-spinners 1
  [ set shape "clock"
    setxy (max-pxcor - 50) (max-pycor - 50)
    set color green 
    set size 80
    set heading 0
    set label 0 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to display-roads
  ;ask river-labels [ die ]
  gis:set-drawing-color black
  ;gis:draw roads-dataset 0
  ask patches gis:intersecting roads-dataset
  [ set pcolor black + 1 
    sprout-nodes 1 [set size 1 set color black + 1]
  ]  
end

to display-pools
  gis:set-drawing-color blue
  gis:draw pools-dataset 1
  gis:apply-coverage pools-dataset "PERIMETER" lake?
  ask patches [if (lake? > 0) [set pcolor blue] ]
end

to display-cesspools
  gis:set-drawing-color brown
  gis:draw cesspool-dataset 1
  gis:apply-coverage cesspool-dataset "PERIMETER" cess?
  ask patches [if (cess? > 0) [set pcolor brown - 2] ]
  
  
   foreach gis:feature-list-of cesspool-dataset
    [ let centroid gis:location-of gis:centroid-of ?
        if not empty? centroid
        [  create-shed-nodes 1
            [ set xcor item 0 centroid
              set ycor item 1 centroid
              set size 10
              set shape "circle" set color blue
              set label gis:property-value ? "Name2" 
              set keeper gis:property-value ? "Keeper2"
              ;set end-node gis:property-value ? "End_Shed"
              ] 
        ]
     ] 
  
  
end

to display-sheds
  
  gis:set-drawing-color yellow
  gis:draw sheds-dataset 1
   gis:apply-coverage sheds-dataset "NUM" population
   foreach gis:feature-list-of sheds-dataset
    [ let centroid gis:location-of gis:centroid-of ?
        if not empty? centroid
        [ let num 0 
          create-shed-nodes 1 
            [ set xcor item 0 centroid
              set ycor item 1 centroid
              set size population / 250
              set shape "circle" set color blue
              set label gis:property-value ? "Name" 
              set end-node gis:property-value ? "End_Shed"
              set keeper gis:property-value ? "Keeper2"
              set num population / 50
              ;set hidden? true
              ]
            
          create-ducks num  [set xcor item 0 centroid
                              set ycor item 1 centroid
                              set size 1 
                              set color green 
                              set heading random 360
                              set keeper-num gis:property-value ? "Keeper2" 
                              set shed-name gis:property-value ? "Name" 
                              set age 9999]
            
        ]
     ] 
    ask ducks [create-green-link-with min-one-of shed-nodes [distance myself][set color green set weight 1]]
end

to layout-ducks
  ask ducks [
       let duck-xy patch-ahead 2 
       ifelse [population] of duck-xy > 0
        [fd 2]
        [rt 180 rt random 360]    
        
      ]
  
end

to link-ducks
  ask ducks [create-green-links-with other ducks with [distance myself < 5][set color black set weight 0.786 * link-length / 5]
              ask my-links [if link-length >= 5 and color = black[ask self [die]]]
            ]
end
to link-node
    ask shed-nodes [
              let next-node end-node
              let tmp-keeper keeper
            
              
              create-blue-links-to other shed-nodes with [label = next-node]
                    [ set color blue
                      set weight 0.158
                      ;set label weight
                      ]
                    
             create-green-links-with other shed-nodes with [ tmp-keeper = keeper]
                    [ set color green
                      set weight 0.528 
                      ;set label weight
                    ] 
             
             create-green-links-with n-of 4 other shed-nodes with [distance myself < 180]
                    [ set color pink
                      set weight 0.064 
                      ;set label weight
                    ]        
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-virus
  ask ducks [become-susceptible]
  ask shed-nodes [set val 0]
  ask n-of initial-outbreak-num ducks with [ xcor > 250 and xcor < 260 and ycor > 580 and ycor < 600 ]
    [ become-infected 
      create-green-link-with min-one-of shed-nodes [distance myself][set color red]]
end
  

to display-image
  import-pcolors-rgb user-file
  ;gis:paint image-dataset 0
end

to update-spinner
  ask spinners
  [ set heading ticks * 30
    set label ticks ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to move
  ifelse ticks mod 24 = 10 or ticks mod 24 = 17
      [set case 1]
      [set case 0]
      
  if case = 0  
      [layout-ducks]
  if case = 1 
      [ask ducks [let aim min-one-of foods [distance myself]
                  ifelse aim != nobody
                     [ face aim   move-to aim]
                     [stop]
                 ]
      ]
   
end


to go3
 ; ask ducks with [situation = 1] 
 ;     [ set age 3
 ;       ask link-neighbors with [breed = ducks and situation = 0]
 ;       [if random 100 < 10 [set situation 1]]
 ;       set age age - 1 
 ;     ]
 
  ;ask ducks [create-green-links-with other ducks with [distance myself < 3][set hidden? true]
  ;             ask my-links [if link-length >= 3 [ask self [die]]]
  ;             ]
  ask shed-nodes [set val count link-neighbors with [breed = ducks and situation = 1] 
                  set size val 
                  if size > 0 [ set color red]
                 ] 
  ask shed-nodes [ 
    if size > 0
    [
      ;ask link-neighbors with [breed = ducks and situation = 0] [ if random 100 < 50 [set situation 1 set color red]]
      ask link-neighbors with [breed = shed-nodes] [ if random 100 < 100 [set size size + [size] of self / 2 set color red]]
    ]
  ]  
  
  
  
  ;ask blue-links [ ask end1 [set val count my-links 
  ;                           set size val * 0.8 / 10
  ;                           ]
  ;                 ask end2 [set val count my-links 
  ;                           set size val * 1.1 / 10
  ;                           ]
  ;               ]
  
  ;ask ducks with [situation = 1]   [if age = 0 [set situation 2 ]]  
  tick
  ;do-virus-checks
 

 
 
 do-plotting  
 set-current-plot "SIR-Curve"
  
 set-current-plot-pen "S"
  
       plot count ducks with [situation = 0]

  set-current-plot-pen "I"
  
       plot count ducks with [situation = 1]
  
  set-current-plot-pen "R"
  
       plot count ducks with [situation = 2]  
;;;;;;;;;;;
 set-current-plot "shed-a2"      
   set-current-plot-pen "S"
  ask shed-nodes with [label = "A2"][
       plot count link-neighbors with [breed = ducks and situation = 0]
  ]
  set-current-plot-pen "I"
  ask shed-nodes with [label = "A2"][
       plot count link-neighbors with [breed = ducks and situation = 1]
  ]
  set-current-plot-pen "R"
  ask shed-nodes with [label = "A2"][
       plot count link-neighbors with [breed = ducks and situation = 2]
  ]
end



 

to become-infected  ;; turtle procedure
  set infected? true
  set resistant? false
  set color red
  ask my-links [ set color red]
end

to become-susceptible  ;; turtle procedure
  set infected? false
  set resistant? false
  set color green
  ask my-links [ set color green ]
end

to become-resistant  ;; turtle procedure
  set infected? false
  set resistant? true
  ;ask self [die]
  set color gray
  ask my-links [ set color gray - 2 ]
end

to spread-virus
  ask ducks with [infected?]
    [ ask link-neighbors with [not resistant?]
        [ if random-float 100 < virus-spread-chance
            [ become-infected  ] ]
    ]
end

to do-virus-checks
  ask ducks with [infected? and virus-check-timer = 0]
  [
    if random 100 < recovery-chance
    [
      ifelse random 100 < gain-resistance-chance
        [ become-resistant ]
        [ become-susceptible ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to do-plotting ;; plotting procedure
  ask turtles [
   
   set s-degree sum [weight] of my-links 

    ]
  
  
  let max-degree max [count link-neighbors] of ducks

  set-current-plot "Degree Distribution"
  plot-pen-reset  ;; erase what we plotted before
  set-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar 
  set-current-plot-pen "W-Degree"
  histogram [s-degree] of ducks 
  
  set-current-plot-pen "Degree"
  histogram [count link-neighbors] of ducks;turtles
  
  set-current-plot "Degree Distribution (log-log)"
  plot-pen-reset  
  
  let degree 1
  while [degree <= max-degree]
  [
    let matches ducks with [count link-neighbors = degree]
    if any? matches
      [ plotxy log degree 10
               log (count matches) 10 ]
    set degree degree + 1
  ]
  
  ask shed-nodes[set val count link-neighbors]
end


to update-plot
  set-current-plot "SIR-Curve"
  set-current-plot-pen "S"
  plot (count ducks with [not infected? and not resistant?]) / (count ducks) * 100
  set-current-plot-pen "I"
  plot (count ducks with [infected?]) / (count ducks) * 100
  set-current-plot-pen "R"
  plot (count ducks with [resistant?]) / (count ducks) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
190
10
981
719
-1
-1
1.0
1
8
1
1
1
0
0
0
1
0
780
0
677
1
1
1
ticks

BUTTON
5
175
175
208
NIL
display-pools
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
5
60
60
93
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

CHOOSER
5
10
175
55
projection
projection
"WGS_84_Geographic"
0

BUTTON
5
95
105
128
NIL
display-sheds
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
65
60
170
93
NIL
display-image
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
3
553
180
586
initial-outbreak-num
initial-outbreak-num
0
20
2
1
1
NIL
HORIZONTAL

SLIDER
5
588
186
621
virus-spread-chance
virus-spread-chance
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
6
622
181
655
virus-check-frequency
virus-check-frequency
0
20
11
1
1
NIL
HORIZONTAL

SLIDER
7
656
179
689
recovery-chance
recovery-chance
0
20
7
1
1
NIL
HORIZONTAL

SLIDER
4
693
179
726
gain-resistance-chance
gain-resistance-chance
0
100
100
1
1
NIL
HORIZONTAL

BUTTON
115
365
178
398
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

PLOT
995
490
1295
630
SIR-Curve
time
% of nodes
0.0
52.0
0.0
100.0
true
true
PENS
"R" 1.0 0 -7500403 true
"I" 1.0 0 -2674135 true
"S" 1.0 0 -10899396 true

MONITOR
1180
435
1255
484
NIL
count ducks
17
1
12

MONITOR
1009
435
1089
484
NIL
count links
17
1
12

BUTTON
5
130
115
163
NIL
display-cesspools
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
1000
325
1105
374
NIL
count shed-nodes
17
1
12

BUTTON
10
290
118
323
NIL
setup-virus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
1100
435
1170
484
death_num
;count ducks with [infected?]\ncount ducks with [situation = 1]
17
1
12

BUTTON
5
210
175
243
NIL
display-roads
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
115
130
185
163
NIL
link-node
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
1000
10
1285
160
Degree Distribution
degree
# of nodes
1.0
10.0
0.0
300.0
true
false
PENS
"default" 1.0 2 -10899396 true
"W-Degree" 1.0 2 -2674135 true
"Degree" 1.0 2 -10899396 true

BUTTON
1145
380
1235
413
NIL
do-plotting
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
1000
165
1285
310
Degree Distribution (log-log)
log(degree)
log(# of nodes)
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 2 -16777216 true

BUTTON
105
95
190
128
NIL
layout-ducks
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
10
245
107
278
NIL
link-ducks
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
1000
380
1140
429
NIL
clustering-coefficient
17
1
12

BUTTON
1180
340
1235
373
NIL
CC
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
115
330
178
363
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
10
330
73
363
NIL
go3
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
995
640
1295
770
shed-a2
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"S" 1.0 0 -10899396 true
"I" 1.0 0 -2674135 true
"R" 1.0 0 -16777216 true

@#$#@#$#@
WHAT IS IT?
-----------
This model was built to test and demonstrate the functionality of the GIS NetLogo extension.


HOW IT WORKS
------------
This model loads four different GIS datasets: a point file of world cities, a polyline file of world rivers, a polygon file of countries, and a raster file of surface elevation. It provides a collection of different ways to display and query the data, to demonstrate the capabilities of the GIS extension.


HOW TO USE IT
-------------
Select a map projection from the projection menu, then click the setup button. You can then click on any of the other buttons to display data. See the procedures tab for specific information about how the different buttons work.


THINGS TO TRY
-------------
Most of the commands in the procedures tab can be easily modified to display slightly different information. For example, you could modify display-cities to label cities with their population instead of their name. Or you could modify highlight-large-cities to highlight small cities instead, by replacing gis:find-greater-than with gis:find-less-than.


EXTENDING THE MODEL
-------------------
This model doesn't do anything particularly interesting, but you can easily copy some of the code from the procedures tab into a new model that uses your own data, or does something interesting with the included data. See the other GIS code example, GIS Gradient Example, for an example of this technique.


RELATED MODELS
--------------
GIS Gradient Example provides another example of how to use the GIS extension.


CREDITS AND REFERENCES
----------------------
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

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

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

mouse side
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

mouse top
true
0
Polygon -7500403 true true 144 238 153 255 168 260 196 257 214 241 237 234 248 243 237 260 199 278 154 282 133 276 109 270 90 273 83 283 98 279 120 282 156 293 200 287 235 273 256 254 261 238 252 226 232 221 211 228 194 238 183 246 168 246 163 232
Polygon -7500403 true true 120 78 116 62 127 35 139 16 150 4 160 16 173 33 183 60 180 80
Polygon -7500403 true true 119 75 179 75 195 105 190 166 193 215 165 240 135 240 106 213 110 165 105 105
Polygon -7500403 true true 167 69 184 68 193 64 199 65 202 74 194 82 185 79 171 80
Polygon -7500403 true true 133 69 116 68 107 64 101 65 98 74 106 82 115 79 129 80
Polygon -16777216 true false 163 28 171 32 173 40 169 45 166 47
Polygon -16777216 true false 137 28 129 32 127 40 131 45 134 47
Polygon -16777216 true false 150 6 143 14 156 14
Line -7500403 true 161 17 195 10
Line -7500403 true 160 22 187 20
Line -7500403 true 160 22 201 31
Line -7500403 true 140 22 99 31
Line -7500403 true 140 22 113 20
Line -7500403 true 139 17 105 10

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
setup
display-cities
display-countries
@#$#@#$#@
@#$#@#$#@
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

ohyah
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
Rectangle -13345367 true false 150 270 150 300
Line -13345367 false 150 0 150 300
Rectangle -13345367 false false 135 0 165 300
Rectangle -13345367 true false 135 0 165 315
Line -13345367 false 135 165 45 195
Polygon -13345367 true false 135 165 15 225 135 105
Polygon -13345367 true false 165 105 285 225 165 165

@#$#@#$#@
1
@#$#@#$#@
