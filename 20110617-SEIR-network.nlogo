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
ducks-own [s-i-r m-f-d situation host keeper-num shed-name duck-weight age ID]

breed [ shed-nodes shed-node ]
shed-nodes-own [val new-val end-node target keeper shed-node-weight s ex i r death my-ticks infected? a]
breed [ houses house]
breed [ cesspools cesspool ]

breed [ birds bird]
birds-own [ virus-tick2 location target flockmates nearest-neighbor]

breed [ mices mice ]
mices-own [virus-tick ]
breed [ cesspoints cesspoint ]
breed [ road-vertices road-vertice ]
breed [ spinners spinner]
patches-own [ population long country-name elevation lake? cess? house? sheds?]
turtles-own
[
  s-degree 
  ;infected?           ;; if true, the turtle is infectious
  resistant?          ;; if true, the turtle can't be infected
  virus-check-timer   ;; number of ticks since this turtle's last virus-check
  node-clustering-coefficient
  distance-from-other-turtles   ;; list of distances of this node from other turtles
]

directed-link-breed [active-links active-link]
directed-link-breed [inactive-links inactive-link]

links-own [ current-flow weight life] 
directed-link-breed [blue-links blue-link]


undirected-link-breed [green-links green-link ]
green-links-own [ weight life]
undirected-link-breed [pink-links pink-link]
pink-links-own [ weight life ]
breed [ foods food]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
directed-link-breed [bird-links bird-link]
directed-link-breed [mice-links mice-link]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ca
  ask patches [set pcolor 0]
  gis:load-coordinate-system (word "data/" projection ".prj")

  set points-dataset gis:load-dataset "data/point_h.shp"
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
  
  
  ; foreach gis:feature-list-of cesspool-dataset
  ;  [ let centroid gis:location-of gis:centroid-of ?
  ;      if not empty? centroid
  ;      [  create-shed-nodes 1
  ;          [ set xcor item 0 centroid
  ;            set ycor item 1 centroid
  ;            set size 10
  ;            set shape "circle" set color blue
  ;            set label gis:property-value ? "Name2" 
  ;            set keeper gis:property-value ? "Keeper2"
  ;            ;set end-node gis:property-value ? "End_Shed"
  ;            ] 
  ;      ]
  ;   ] 
  
  
end

to display-sheds
  
  gis:set-drawing-color yellow
  gis:draw sheds-dataset 1
  gis:apply-coverage sheds-dataset "PERIMETER" sheds?
  gis:apply-coverage sheds-dataset "NUM" population
   foreach gis:feature-list-of sheds-dataset
    [ let centroid gis:location-of gis:centroid-of ?
        if not empty? centroid
        [ let num 0 
          create-shed-nodes 1 
            [ set xcor item 0 centroid
              set ycor item 1 centroid
              set size 0
              set shape "circle" set color blue
              set label gis:property-value ? "Name" 
              set end-node gis:property-value ? "End_Shed"
              set keeper gis:property-value ? "Keeper2"
              set num population / 10
              set s population 
              set ex 0
              set i 0
              set r 0
              set my-ticks 0
              set infected? false
              ]
         
            
        ]
     ] 

end

to link-for-water
    ask shed-nodes [
              let next-node end-node      
              create-blue-links-to other shed-nodes with [label = next-node]
                    [ set color blue set thickness 5
                      set weight 0.158
                      ;set label weight
                      set life 9999
                      ]             
    ]
end

to link-for-bird
    ask shed-nodes with [i > 0]
                    [ let nn other shed-nodes with [distance myself < 700];;650
                      let p population
                      let pp sum [population] of shed-nodes
                     create-bird-links-to nn 
                    [ ;let min-length min [link-length] of bird-links
                      ifelse random-float 1 < 0.027 ^ 2 ;* exp(1 - link-length / 120) ;* p ^ 2 / pp * exp(1 - link-length / 30)   ; 18 / 55 / 12;;; (150 ^ 3 / link-length ^ 3 - link-length);;
                        [set color orange
                         set weight 0.01 / link-length
                         ;set label weight
                         set life 1]  
                         [die]                                     
                    ]        
    ]
end

to link-for-feed
  ask shed-nodes ;with [i > 0]
                    [ let tmp-keeper keeper
                      if (ticks mod 24 > 5 and ticks mod 24 <= 6) or (ticks mod 24 >= 21 and ticks mod 24 <= 22)
                        [create-mice-links-to other shed-nodes with [ tmp-keeper = keeper]
                           [ set color green set thickness 5
                             set weight 0.5 / link-length
                             ;set label weight
                             set life 1
                           ]  
                        ]
                     if (ticks mod 24 >= 14 and ticks mod 24 <= 15)
                        [ create-bird-links-to other shed-nodes with [ tmp-keeper = keeper]
                           [ set color green set thickness 5
                             set weight 0.5 / link-length
                             ;set label weight
                             set life 1
                           ] 
                        ] 
  ]
end

to link-for-mice
  ask shed-nodes with [i > 0]
                   [ let nn other shed-nodes with [distance myself < 100]
                     create-mice-links-to nn 
                    [ifelse random-float 1 < 0.18 ^ 2    ;;;20 / 8 / 14 ;1 - exp((link-length - 150) / link-length)
                     
                     [ set color pink
                      set weight 0.4 / link-length
                      ;set label weight
                      set life 1] 
                     [die]
                    ]
                    
                 ]
end

to link-node
  
  if (ticks mod 24 > 5 and ticks mod 24 <= 6) or (ticks mod 24 >= 14 and ticks mod 24 <= 15) or (ticks mod 24 >= 21 and ticks mod 24 <= 22) [link-for-feed]
  
  if ticks mod 24 > 20 or ticks mod 24 < 5 [link-for-mice]
 
  if ticks mod 24 > 5 and ticks mod 24 < 18 [link-for-bird]
  
  
  ask links [ifelse life <= 0 
                    [die]
                    [set life life - 1]]
end

to set-virus
  ask shed-nodes with [label = "B2"] [set infected? true set s 1486 set i 36 set ex 1278 set r 0 set color yellow] 
end


to re-display
  ;ask patches [set pcolor (pcolor + 5 / 12) mod 10]
  ask shed-nodes with [r > 0] [set color red 
                               set val i ;/ population
                               set size r / 50]
end

to go
  tick-advance dt
  link-node
  re-display
  spread-virus
  ;set a 98.54 * ticks / (4913 + ticks ^ 1.867)
  
  ;set a 36.785 * (ticks / 24)/ (94.954 + (ticks / 24) ^ 2.751) / 1.055
  ;set a 265944.059572867 * (ticks + 48 )/ (2.147654522917443E7 + (ticks + 48) ^ 3.389)
  ;set a 0.3
  ask shed-nodes 
       [ ifelse infected? 
         [set my-ticks my-ticks + 1
          set a 5.041 * (my-ticks / 24 + 1.5) / (7.13 + (my-ticks / 24 + 1.5) ^ 1.892)
          ;set a 265944.059572867 * (my-ticks + 96 )/ (2.147654522917443E7 + (my-ticks + 96) ^ 3.389)
          if s >= 0    ;;;;yichu
           [set s s - int (a * s * i * dt) 
            set ex ex + int (a * s * i * dt) - int(b * ex * dt) 
            set i i + int (b * ex * dt)  - int(c * i * dt) 
            set r r + int (c * i * dt ) 
            if s < 0 [set s 0]
            if ex < 0 [set ex 0]
            if i < 0 [set i 0]
           ]
         ]
         [set my-ticks 0]
       ]
  
  tick
  ask shed-nodes with [label = "A2"] [ set-current-plot "A" set-current-plot-pen "A2" plot r]
  ask shed-nodes with [label = "A5"] [ set-current-plot "A" set-current-plot-pen "A5" plot r]
  ask shed-nodes with [label = "A6"] [ set-current-plot "A" set-current-plot-pen "A6" plot r]
  ask shed-nodes with [label = "A7"] [ set-current-plot "A" set-current-plot-pen "A7" plot r]
  ask shed-nodes with [label = "A8"] [ set-current-plot "A" set-current-plot-pen "A8" plot r]
  let rr sum [r] of shed-nodes with [label = "A10" or label = "A9" or label = "A11"] set-current-plot "A" set-current-plot-pen "A9-11" plot rr
  
    ask shed-nodes with [label = "B2"] [ set-current-plot "B" set-current-plot-pen "B2" plot r]
    ask shed-nodes with [label = "B3"] [ set-current-plot "B" set-current-plot-pen "B3" plot r]
    ask shed-nodes with [label = "B4"] [ set-current-plot "B" set-current-plot-pen "B4" plot r]
    ask shed-nodes with [label = "B5"] [ set-current-plot "B" set-current-plot-pen "B5" plot r]
    ask shed-nodes with [label = "B6"] [ set-current-plot "B" set-current-plot-pen "B6" plot r]
    ask shed-nodes with [label = "B7"] [ set-current-plot "B" set-current-plot-pen "B7" plot r]
    ask shed-nodes with [label = "B8"] [ set-current-plot "B" set-current-plot-pen "B8" plot r]
    let r-b91011 sum [r] of shed-nodes with [label = "B9" or label = "B10" or label = "B11"] set-current-plot "B" set-current-plot-pen "B9-11" plot r-b91011
    
    ask shed-nodes with [label = "C1"] [ set-current-plot "C" set-current-plot-pen "C1" plot r]
    ask shed-nodes with [label = "C2-3"] [ set-current-plot "C" set-current-plot-pen "C2-3" plot r]
    ask shed-nodes with [label = "C4"] [ set-current-plot "C" set-current-plot-pen "C4" plot r]
    ask shed-nodes with [label = "C5"] [ set-current-plot "C" set-current-plot-pen "C5" plot r]
    ask shed-nodes with [label = "C6"] [ set-current-plot "C" set-current-plot-pen "C6" plot r]
    ask shed-nodes with [label = "C7"] [ set-current-plot "C" set-current-plot-pen "C7" plot r]
    ask shed-nodes with [label = "C8"] [ set-current-plot "C" set-current-plot-pen "C8" plot r]
    ask shed-nodes with [label = "C9"] [ set-current-plot "C" set-current-plot-pen "C9" plot r]
    let r-c1011 sum [r] of shed-nodes with [label = "C10" or label = "C11"] set-current-plot "C" set-current-plot-pen "C10-11" plot r-c1011
    ;ask shed-nodes with [label = "C10-11"] [ set-current-plot "C" set-current-plot-pen "C10-11" plot r]
    ask shed-nodes with [label = "C12"] [ set-current-plot "C" set-current-plot-pen "C12" plot r]
    
    ask shed-nodes with [label = "D1"] [ set-current-plot "D" set-current-plot-pen "D1" plot r]
    ask shed-nodes with [label = "D2"] [ set-current-plot "D" set-current-plot-pen "D2" plot r]
    ask shed-nodes with [label = "D3"] [ set-current-plot "D" set-current-plot-pen "D3" plot r]
    ask shed-nodes with [label = "D4-5"] [ set-current-plot "D" set-current-plot-pen "D4-5" plot r]
    ask shed-nodes with [label = "D6"] [ set-current-plot "D" set-current-plot-pen "D6" plot r]
    ask shed-nodes with [label = "D7"] [ set-current-plot "D" set-current-plot-pen "D7" plot r]
    ;ask shed-nodes with [label = "D8-10"] [ set-current-plot "D" set-current-plot-pen "D8-10" plot r]
    let r-d8910 sum [r] of shed-nodes with [label = "D8" or label = "D9" or label = "D10"] set-current-plot "D" set-current-plot-pen "D8-10" plot r-d8910
    ask shed-nodes with [label = "D11"] [ set-current-plot "D" set-current-plot-pen "D11" plot r]
    
    ask shed-nodes with [label = "E10"] [ set-current-plot "E" set-current-plot-pen "E10" plot r]
    ask shed-nodes with [label = "E9"] [ set-current-plot "E" set-current-plot-pen "E9" plot r]
    let r-e12 sum [r] of shed-nodes with [label = "E1,E2"] set-current-plot "E" set-current-plot-pen "E1-2" plot r-e12
    let r-e34 sum [r] of shed-nodes with [label = "E3" or label = "E4"] set-current-plot "E" set-current-plot-pen "E3-4" plot r-e34
    let r-e5678 sum [r] of shed-nodes with [label = "E5" or label = "E6" or label = "E7" or label = "E8"] set-current-plot "E" set-current-plot-pen "E5-8" plot r-e5678
  
   ;ask shed-nodes [if i > 0
   ;                 [set color yellow set size 20]
   ;]

end






to spread-virus
  ask mice-links [ let v [i] of end1 
                   if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-mice
                     [ if ticks mod 24 > 20 or ticks mod 24 < 5
                         [ifelse (ticks mod 24 > 5 and ticks mod 24 <= 6) or (ticks mod 24 >= 14 and ticks mod 24 <= 15)
                             [ask end2 [ set s s - int (2 * v * s * b-mice * dt)  
                                         set ex ex + int (2 * v * s * b-mice * dt) 
                                         set infected? true
                                         if s < 0 [set s 0]
                                         if ex < 0 [set ex 0]
                                         if i < 0 [set i 0]
                                       ]
                             ]
                             
                             [ask end2 [ set s s - int ( v * s * b-mice * dt)  
                                         set ex ex + int ( v * s * b-mice * dt) 
                                         set infected? true
                                         if s < 0 [set s 0]
                                         if ex < 0 [set ex 0]
                                         if i < 0 [set i 0]
                                       ]
                             ]
                         ]
                     ] 
                 ]
  
  ask bird-links [ let v [i] of end1 
                   if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
                       [ if ticks mod 24 > 5 and ticks mod 24 < 18
                         [ifelse (ticks mod 24 > 5 and ticks mod 24 <= 6) or (ticks mod 24 >= 14 and ticks mod 24 <= 15)
                             [ask end2 [ set s s - int (2 * v * s * b-bird * dt) 
                                         set ex ex + int (2 * v * s * b-bird * dt) 
                                         set infected? true
                                         if s < 0 [set s 0]
                                         if ex < 0 [set ex 0]
                                         if i < 0 [set i 0]
                                       ]
                             ]
                             
                             [ask end2 [ set s s - int ( v * s * b-bird * dt)  
                                         set ex ex + int ( v * s * b-bird * dt) 
                                         set infected? true
                                         if s < 0 [set s 0]
                                         if ex < 0 [set ex 0]
                                         if i < 0 [set i 0]
                                       ]
                             ]
                         ]
                       ]
                 ]
  
    ask blue-links [ let v [i] of end1 
                   if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird

                             [ask end2 [ set s s - int ( v * s * b-water * dt)  
                                         set ex ex + int ( v * s * b-water * dt) 
                                         set infected? true
                                         if s < 0 [set s 0]
                                         if ex < 0 [set ex 0]
                                         if i < 0 [set i 0]
                                       ]
                             ]
                   ]
                   
  ask shed-nodes with [label = "A1" or label = "A3" or label = "A4" or label = "B1" or label = "B5"] [if my-ticks = 24 [set size population / 100 set color grey stamp die] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-path-to
    let file user-new-file
  ;; We check to make sure we actually got a string just in case
  ;; the user hits the cancel button.
  if is-string? file
  [
    ;; If the file already exists, we begin by deleting it, otherwise
    ;; new data would be appended to the old contents.
    if file-exists? file
      [ file-delete file ]
    file-open file
    ;; record the initial turtle data
    write-to-file
  ]
end

to write-to-file
  file-print (word "*Vertices" " " count shed-nodes)
  foreach sort shed-nodes [
     ask ? [  
              file-print (word ID " " "\"" ID "\"" " "(xcor / max-pxcor) " " (ycor / max-pycor) " " 0.5)
           ]
  ]
  file-print ("*Arcs")
  ;let n count infect-links
  ;let i 1
  foreach sort links [
     ask ? [ 
              file-print (word [ID] of end1 " " [ID] of end2 )]
             
           ]
     
  file-print ""
end

to do-plotting ;; plotting procedure
  
  let max-degree max [count my-links] of shed-nodes

  set-current-plot "Degree Distribution"
  plot-pen-reset  ;; erase what we plotted before
  set-plot-x-range 0 (max-degree + 1)  ;; + 1 to make room for the width of the last bar
  histogram [count my-links] of shed-nodes
  

  ;; for this plot, the axes are logarithmic, so we can't
  ;; use "histogram-from"; we have to plot the points
  ;; ourselves one at a time
  set-current-plot "Degree Distribution (log-log)"
  plot-pen-reset  ;; erase what we plotted before
  ;; the way we create the network there is never a zero degree node,
  ;; so start plotting at degree one
  
  let degree 1
  while [degree <= max-degree]
  [
    let matches shed-nodes with [count my-links = degree]
    if any? matches
      [ plotxy log degree 10
               log (count matches) 10 ]
    set degree degree + 1
  ]
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
95
175
128
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

SLIDER
1125
315
1302
348
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
1127
350
1308
383
virus-spread-chance
virus-spread-chance
0
100
3
1
1
NIL
HORIZONTAL

SLIDER
1128
384
1303
417
virus-check-frequency
virus-check-frequency
0
20
6
1
1
NIL
HORIZONTAL

SLIDER
1129
418
1301
451
recovery-chance
recovery-chance
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
1126
455
1301
488
gain-resistance-chance
gain-resistance-chance
0
100
100
1
1
NIL
HORIZONTAL

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

MONITOR
1100
435
1170
484
death_num
count ducks with [resistant?]\n;count ducks with [situation = 1]
17
1
12

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

BUTTON
110
220
173
253
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

SLIDER
5
660
177
693
vision
vision
0
5
0
1
1
NIL
HORIZONTAL

SLIDER
5
690
177
723
minimum-separation
minimum-separation
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
5
720
177
753
max-align-turn
max-align-turn
0
10
9
1
1
NIL
HORIZONTAL

SLIDER
5
780
177
813
max-separate-turn
max-separate-turn
0
10
8.5
0.5
1
NIL
HORIZONTAL

SLIDER
5
750
177
783
max-cohere-turn
max-cohere-turn
0
10
8
1
1
NIL
HORIZONTAL

SLIDER
5
135
182
168
dt
dt
0
0.1
0.0417
0.0001
1
NIL
HORIZONTAL

SLIDER
5
175
97
208
b
b
0
1
0.33
0.01
1
NIL
HORIZONTAL

PLOT
390
580
590
730
A2
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
"E" 1.0 0 -1184463 true

PLOT
585
580
785
730
B3
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
"E" 1.0 0 -1184463 true

PLOT
790
580
990
730
B2
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
"E" 1.0 0 -1184463 true

BUTTON
5
290
102
323
initialize
setup\ndisplay-sheds\ndisplay-cesspools\nlink-for-water\nset-virus\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
5
225
100
258
c
c
0
24
0.14
0.01
1
NIL
HORIZONTAL

PLOT
380
580
625
760
B
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"B2" 1.0 0 -16777216 true
"B3" 1.0 0 -865067 true
"B4" 1.0 0 -2674135 true
"B5" 1.0 0 -1184463 true
"B6" 1.0 0 -8630108 true
"B7" 1.0 0 -817084 true
"B8" 1.0 0 -13791810 true
"B9-11" 1.0 0 -5825686 true

PLOT
135
580
380
760
A
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"A5" 1.0 0 -16777216 true
"A6" 1.0 0 -2674135 true
"A7" 1.0 0 -955883 true
"A8" 1.0 0 -13840069 true
"A9-11" 1.0 0 -13345367 true
"A2" 1.0 0 -5825686 true

TEXTBOX
10
260
160
278
患病到移出的时间 1/c  天
12
0.0
1

TEXTBOX
5
210
155
228
潜伏时间 1/b 天
12
0.0
1

MONITOR
125
430
175
479
r
sum [r] of shed-nodes
17
1
12

PLOT
625
580
885
770
C
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"C1" 1.0 0 -16777216 true
"C2-3" 1.0 0 -2674135 true
"C4" 1.0 0 -955883 true
"C5" 1.0 0 -6459832 true
"C6" 1.0 0 -1184463 true
"C7" 1.0 0 -10899396 true
"C8" 1.0 0 -13791810 true
"C9" 1.0 0 -8630108 true
"C10-11" 1.0 0 -5825686 true
"C12" 1.0 0 -2064490 true

PLOT
890
575
1135
760
D
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"D1" 1.0 0 -1184463 true
"D2" 1.0 0 -2064490 true
"D3" 1.0 0 -16777216 true
"D4" 1.0 0 -5825686 true
"D4-5" 1.0 0 -8630108 true
"D6" 1.0 0 -13345367 true
"D7" 1.0 0 -10899396 true
"D8-10" 1.0 0 -955883 true
"D11" 1.0 0 -2674135 true
"D12" 1.0 0 -7500403 true

PLOT
1135
575
1395
760
E
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"E1-2" 1.0 0 -16777216 true
"E3-4" 1.0 0 -13345367 true
"E5-8" 1.0 0 -955883 true
"E9" 1.0 0 -10899396 true
"E10" 1.0 0 -2674135 true

BUTTON
110
185
173
218
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

SLIDER
5
475
177
508
b-mice
b-mice
0
1
0.057
0.001
1
NIL
HORIZONTAL

SLIDER
5
505
177
538
b-bird
b-bird
0
1
0.146
0.001
1
NIL
HORIZONTAL

MONITOR
125
380
175
429
i
sum [i] of shed-nodes
17
1
12

MONITOR
125
330
175
379
e
sum [ex] of shed-nodes
17
1
12

MONITOR
125
280
175
329
s
sum [s] of shed-nodes
17
1
12

MONITOR
20
340
77
389
sum
sum [s] of shed-nodes + sum [ex] of shed-nodes + sum [i] of shed-nodes + sum [r] of shed-nodes
17
1
12

MONITOR
20
400
77
449
p
sum [population] of shed-nodes
17
1
12

MONITOR
25
570
75
619
B2的a
[a] of shed-nodes with [label = \"B2\"]
17
1
12

MONITOR
25
615
75
664
E2的a
[a] of shed-nodes with [label = \"B7\"]
17
1
12

SLIDER
5
540
177
573
b-water
b-water
0
1
0.287
0.001
1
NIL
HORIZONTAL

BUTTON
1290
75
1397
108
NIL
do-plotting
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
