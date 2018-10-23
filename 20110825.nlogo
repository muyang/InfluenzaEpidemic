extensions [ gis ]
globals [ foods-dataset
          points-dataset
          roads-dataset
          pools-dataset
          image-dataset
          sheds-dataset
          sheds-line-dataset 
          elevation-dataset
          cesspool-dataset
          mice-dataset
          cesspoint-dataset
          
          channel-dataset
                              
          clustering-coefficient               
          average-path-length                  
          clustering-coefficient-of-lattice   
          average-path-length-of-lattice       
          infinity                             
                              
          case
          black-patches
          water-patches
          foods-patches
          ]
breed [ nodes node ]

breed [ ducks duck ]
ducks-own [s-i-r m-f-d situation host keeper-num shed-name duck-weight age l-o-r virus-per-day water-time eat-time ID rate e-day]

breed [ shed-nodes shed-node ]
shed-nodes-own [val new-val end-node target keeper shed-node-weight s ex i r death my-ticks a my-ducks shed-infected?]
breed [ houses house]
breed [ cesspools cesspool ]

breed [ birds bird]
birds-own [ virus-tick2 location target flockmates nearest-neighbor]

breed [ mices mice ]
mices-own [virus-tick ]
breed [ cesspoints cesspoint ]
breed [ road-vertices road-vertice ]
breed [ spinners spinner]
patches-own [ population long country-name elevation lake? cess? house? sheds? chemical air-chemical]
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
directed-link-breed [duck-links duck-link]

directed-link-breed [infect-links infect-link]
infect-links-own [ weight weight2]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ca
  ask patches [set pcolor 1.5]
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
  set channel-dataset gis:load-dataset "data/WaterLine.shp"
  set sheds-line-dataset gis:load-dataset "data/shed2_PolygonToLine1.shp"
  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of points-dataset)
                                                (gis:envelope-of mice-dataset)
                                                (gis:envelope-of pools-dataset)
                                                (gis:envelope-of sheds-dataset)
                                                (gis:envelope-of cesspool-dataset)
                                                (gis:envelope-of image-dataset)
                                                (gis:envelope-of roads-dataset)
                                                (gis:envelope-of foods-dataset)
                                                (gis:envelope-of channel-dataset)
                                                (gis:envelope-of sheds-line-dataset)
                                                )

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to display-point_h
    ask patches gis:intersecting points-dataset
    [ set pcolor yellow ]
end
to display-channel
  ask patches gis:intersecting channel-dataset
    [ set pcolor blue ]
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
  ask patches gis:intersecting sheds-dataset [set pcolor black]
  ask patches gis:intersecting sheds-line-dataset [set pcolor grey]
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
              set num population / 20
              set s population 
              set ex 0
              set i 0
              set r 0
              set my-ticks 0
              set shed-infected? false
              
              ]
         create-ducks num  [  set xcor item 0 centroid 
                              set ycor item 1 centroid
                              set size 1 
                              set color green 
                              set heading random 360
                              set infected? false
                              set resistant? false
                              set keeper-num gis:property-value ? "Keeper2" 
                              set shed-name gis:property-value ? "Name" 
                              set hidden? false
                              set water-time random 2880  ;;2 hours
                              set eat-time random 2880
                              set ID who + 1
                              set e-day random 4320] 
         ask shed-nodes    [set my-ducks ducks-here]
            
        ]
     ] 
end
to set-pcolor
  set black-patches patches with [pcolor = black]
  set water-patches patches with [pcolor = blue]
  set foods-patches patches with [pcolor = yellow]
end
;;;;;;;;;;;;;;;;  go 3  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to left-or-right
  ask shed-nodes [let lor xcor 
                  ask ducks [ifelse xcor > lor [set l-o-r 0]
                                               [set l-o-r 1]]
  ]
end

to count-infect-day
  ask ducks [if infected? [set age age + 1 
                           set virus-per-day 36.785 * 3.6 * (age / (60 * 24)) / (94.954 + (age / (60 * 24)) ^ 4) / 2.45 * 3.6]]   ;; max=3.6 
end

to go3
  count-infect-day
  walk
  link-node
  tick
  ask ducks with [hidden? = false and water-time = 0] 
    [move-to min-one-of water-patches [distance myself]]
  
  ask ducks with [hidden? = false and eat-time = 0] 
    [move-to min-one-of foods-patches [distance myself]]  
    
  virus-diffuse
  diffuse air-chemical 8 / 9
  spread-virus2
  do-virus-checks
  count-sir
  spread-between-sheds
  if ticks mod 1440 = 0 [ 
    ask shed-nodes with [label = "B2"] [ set-current-plot "B" set-current-plot-pen "B2" plot count my-ducks with [color = black]]
    ask shed-nodes with [label = "B4"] [ set-current-plot "B" set-current-plot-pen "B4" plot count my-ducks with [color = black]]
    ask shed-nodes with [label = "B1"] [ set-current-plot "B" set-current-plot-pen "B6" plot count my-ducks with [color = black]]
    ask shed-nodes with [label = "B3"] [ set-current-plot "B" set-current-plot-pen "B3" plot count my-ducks with [color = black]]
  ]
end

to walk
  ask ducks with [hidden? = false]
  [if ticks mod 1440 < 1380 and ticks mod 1440 >= 300   ;;[5-23]
                [;let duck-xy patch-ahead 2
                  ifelse [pcolor] of patch-ahead 1 = grey or [pcolor] of patch-ahead 1 = 1.5
                  ;ifelse [population] of duck-xy = nobody
                    [rt random 180 + 90]
                    [ifelse age < 24 * 60 * 2 [fd 0.5 rt random 360]    
                                              [fd 0.1 rt random 360]  ;;if infected-time > 1 day ,v slow 
                    ]
                  set water-time water-time + 1 if water-time > 2880 [set water-time 0]
                  set eat-time eat-time + 1 if eat-time > 2880 [set eat-time 0]
                ]
  ]
end

to virus-diffuse 
  ask ducks [if infected? [
        let v virus-per-day
        ask patch-here [set air-chemical (air-chemical + v / 24 / 60) ]]  
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
                     set chemical (chemical + ch) * (1 - 0.15 / 10 / 3 / 16)]
  ask foods-patches [ifelse chemical > 0 
                       [set pcolor red] 
                       [set pcolor yellow]
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

to spread-between-sheds
  ask blue-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected set color red] ]
      ]
      ]
  ]
      
  ask mice-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected set color red ] ]
      ]
      ]
  ]
  ask bird-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected set color red ] ]
      ]
      ]
  ]
end








































;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;                               go 2                                                       ;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to layout-ducks
 ask ducks [ifelse color = grey and (ticks mod 24 >= 23 or ticks mod 24 < 5)
              [stamp]
              [let duck-xy patch-ahead 2 
                ifelse [population] of duck-xy > 0 
                     [fd 1]
                     [rt 90 rt random 360]    
              ]
           ]  
end
;;;;;;;;;;;;;;;;;;     individual      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

to set-virus2
  ask shed-nodes with [label = "B2"] [ask n-of 36 my-ducks [set infected? true set color red]]
end

to just-b23
  ask shed-nodes [if not (label = "B2") ;or label = "B4" or label = "B3" or label = "B1")
                     [ask my-ducks [die]]
  ]    
end

to go2
  tick-advance dt
  layout-ducks
  link-node
  ask ducks with [infected? = true]
               [create-duck-links-to other ducks with [distance myself < 2][set hidden? true]
                ask my-links [if link-length >= 2 [ask self [die]]]
               ]
  ;re-display
  spread-virus2
  
  ask duck-links [ask end2 [ 
        if random-float 100 < virus-spread-chance
              [ become-infected ]
        ]
  ]
  virus-diffuse
  do-virus-checks
  count-sir
  ask blue-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
      
  ask mice-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
  ask bird-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
  tick
  ask shed-nodes with [label = "B2"] [ set-current-plot "B" set-current-plot-pen "B2" plot r]
  ask shed-nodes with [label = "B4"] [ set-current-plot "B" set-current-plot-pen "B4" plot r]
  ask shed-nodes with [label = "B1"] [ set-current-plot "B" set-current-plot-pen "B6" plot r]
  ask shed-nodes with [label = "B3"] [ set-current-plot "B" set-current-plot-pen "B3" plot r]
end

to become-infected22  ;; turtle procedure
  set infected? true
  set resistant? false
  set color red
end

to become-susceptible22  ;; turtle procedure
  set infected? false
  set resistant? false
  set color green
end

to become-resistant22  ;; turtle procedure
  set infected? false
  set resistant? true
  set color gray 
  set hidden? true
  ask my-links [ die set color gray - 2 set hidden? true]
end

to spread-virus22
  ask ducks with [infected?]
    [ ask link-neighbors with [not resistant?]
        [ if random-float 100 < virus-spread-chance
            [ become-infected ] ] ]
    
   ;diffuse chemical (80 / 100) 
   ;ask patches
   ;[ set chemical chemical * (100 - 10) / 100  ;; slowly evaporate chemical
   ; set pcolor scale-color green chemical 0.1 5 ] 
end

to do-virus-checks22
  ask ducks with [infected? and virus-check-timer = 0]
  [
    if random 100 < recovery-chance
    [
      if random 100 < gain-resistance-chance
        [ become-resistant ]
        ;[ become-susceptible ]
    ]
  ]
end


to count-sir
  ask shed-nodes [set s count my-ducks with [color = green] ;;[infected? = false and resistant? = false]
                  set i count my-ducks with [color = red]   ;;[infected? = true]
                  set r count my-ducks with [color = grey]  ;;[infected? = false and resistant? = true]
  
  ]
end

to behavior
  ask shed-nodes [ask n-of 100 my-ducks [move-to one-of patches with [pcolor = blue]]]
  ask shed-nodes [ask my-ducks [move-to one-of patches with [pcolor = yellow]]]
  if ticks mod 24 = 5 or ticks mod 24 = 14 or ticks mod 24 = 22 []
  
   ask ducks [ifelse color = grey and (ticks mod 24 >= 23 or ticks mod 24 < 5)
              [stamp]
              [let duck-xy patch-ahead 2 
                ifelse [population] of duck-xy > 0 
                     [fd 1]
                     [rt 90 rt random 360]    
              ]
           ]
end

to water-spread
  ask ducks with [infected?] [if random-float 1 < virus-water [ become-infected ]]
end

to feed-spread
  ask ducks with [infected?] [if random-float 1 < virus-feed [ become-infected ]]
end

to air-spread
  ask ducks with [infected?] [if random-float 1 < virus-air [ become-infected ]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to link-for-bird
    ask shed-nodes with [i > 0]
                    [ let nn other shed-nodes ;with [distance myself < 1000];;650
                      ;let p population
                      ;let pp sum [population] of shed-nodes
                     create-bird-links-to nn 
                    [ ;let min-length min [link-length] of bird-links
                      ifelse random-float 1 < 0.027 * (120 / link-length) ;;exp(1 - link-length / 160) ;* p ^ 2 / pp * exp(1 - link-length / 30)   ; 18 / 55 / 12;;; (150 ^ 3 / link-length ^ 3 - link-length);;
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
                      if (ticks mod 1440 > 300 and ticks mod 1440 <= 300) or (ticks mod 1440 >= 1260 and ticks mod 1440 <= 1320)
                        [create-mice-links-to other shed-nodes with [ tmp-keeper = keeper]
                           [ set color green set thickness 5
                             set weight 0.5 / link-length
                             ;set label weight
                             set life 1
                           ]  
                        ]
                     if (ticks mod 1440 >= 840 and ticks mod 1440 <= 900)
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
                   [ let nn other shed-nodes with [distance myself < 120]
                     create-mice-links-to nn 
                    [ifelse random-float 1 < 0.18      ;;;20 / 8 / 14 ;1 - exp((link-length - 150) / link-length)
                     
                     [ set color pink
                      set weight 0.4 / link-length
                      ;set label weight
                      set life 1] 
                     [die]
                    ]
                    
                 ]
end

to link-for-water-net
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

to link-node
  link-for-water-net
  
  if (ticks mod 1440 > 300 and ticks mod 1440 <= 360) or (ticks mod 1440 >= 840 and ticks mod 1440 <= 900) or (ticks mod 1440 >= 1260 and ticks mod 1440 <= 1320) [link-for-feed]
  
  if ticks mod 1440 > 1200 or ticks mod 1440 < 300 [link-for-mice]
 
  if ticks mod 1440 > 300 and ticks mod 1440 < 1080  [link-for-bird]
  
  
  ask links [ifelse life <= 0 
                    [die]
                    [set life life - 1]]
end

to set-virus
  ask shed-nodes with [label = "B2"] [set infected? true set s 1486 set i 36 set ex 1260 set r 18 set color yellow] 
end


to re-display
  ;ask patches [set pcolor (pcolor + 5 / 12) mod 10]
  ask shed-nodes with [r > 0] [set color red 
                               set val i ;/ population
                               set size r / 50]
end

to go
  ;tick-advance dt
  layout-ducks ;;ask ducks [walk]
  link-node
  virus-diffuse
  recolor-patches
  ;ask ducks with [infected? = true]
  ;  [create-duck-links-to other ducks with [distance myself < 2][set hidden? true]
  ;    ask my-links [if link-length >= 2 [ask self [die]]]
  ;  ]
  ask ducks [if not infected? and [chemical] of patch-here > 0 and random-float 100 < virus-spread-chance [become-infected ]]
  ask ducks [if infected? [set age age - 1 if age <= -3 [die]]]
    count-sir
  ask blue-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
      
  ask mice-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
  ask bird-links [ let v [i] of end1 
    if v > 0 and [s] of end2 > 0 ;and random-float 1 <  b-bird
    
      [ask end2 [ 
        if random-float 100 < 50
          [ ask n-of 5 my-ducks [become-infected ] ]
      ]
      ]
  ]
  tick
  ask shed-nodes with [label = "B2"] [ set-current-plot "B" set-current-plot-pen "B2" plot r]
  ask shed-nodes with [label = "B4"] [ set-current-plot "B" set-current-plot-pen "B4" plot r]
  ask shed-nodes with [label = "B1"] [ set-current-plot "B" set-current-plot-pen "B6" plot r]
  ask shed-nodes with [label = "B3"] [ set-current-plot "B" set-current-plot-pen "B3" plot r]
end

to recovered-or-death
end

to recolor-patches  ;; color patches according to heat
  ask patches [ set pcolor chemical ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-network
  ask ducks with [color = red]
      [create-infect-links-to other ducks with [distance myself < 5 and color = green]
        [set color red 
         set weight 1 - link-length / 5 
         set weight2 1 - weight * 0.0052]
      ]
  ask links [if link-length >= 5 [die]]
end

to be-infected
  ask ducks with [color = green]
       [ let rr 1
         if count my-links > 0 [foreach sort my-links [ask ? [set rr rr * weight2]] 
                                set rate 1 - rr
                                if  random 100 <= rate [set color red set rate 0]
         ]
         
       ]
end

to recover-or-dead
  ask ducks with [color = red]
  [ ifelse  e-day > 0 [set e-day e-day - 1]
                      [ifelse random 100 <= 36 [die]
                                               [set color grey]
                      ]
  ]
end

to gogogo
  layout-ducks
  link-node2
    ask ducks with [hidden? = false and water-time = 0] 
    [move-to min-one-of water-patches [distance myself]]
  
  ask ducks with [hidden? = false and eat-time = 0] 
    [move-to min-one-of foods-patches [distance myself]]  
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
  create-network
  be-infected
  recover-or-dead
  count-sir
  spread-between-sheds
  tick

end
to link-node2
  link-for-water-net
  if (ticks mod 24 > 5 and ticks mod 24 <= 6) or (ticks mod 24 >= 14 and ticks mod 24 <= 15) or (ticks mod 24 >= 21 and ticks mod 24 <= 22) [link-for-feed]
  
  if ticks mod 24 > 20 or ticks mod 24 < 5 [link-for-mice]
 
  if ticks mod 24 > 5 and ticks mod 24 < 18 [link-for-bird]
  
  
  ask links [ifelse life <= 0 
                    [die]
                    [set life life - 1]]
end
@#$#@#$#@
GRAPHICS-WINDOW
245
25
1048
745
-1
-1
1.5221
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
520
0
452
0
0
1
ticks

BUTTON
5
440
175
473
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
185
15
240
48
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
0
290
181
323
virus-spread-chance
virus-spread-chance
0
100
2.371995020620689E-5
1
1
NIL
HORIZONTAL

SLIDER
1
324
176
357
virus-check-frequency
virus-check-frequency
0
20
12
1
1
NIL
HORIZONTAL

SLIDER
2
358
174
391
recovery-chance
recovery-chance
0
100
34
1
1
NIL
HORIZONTAL

SLIDER
-1
395
174
428
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
10
585
180
725
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

SLIDER
0
195
172
228
virus-water
virus-water
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
0
225
172
258
virus-feed
virus-feed
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
0
255
172
288
virus-air
virus-air
0
1
0.09
.01
1
NIL
HORIZONTAL

SLIDER
0
55
177
88
dt
dt
0
0.1
0.0417
0.0001
1
NIL
HORIZONTAL

BUTTON
5
505
102
538
initialize
setup\ndisplay-sheds\ndisplay-cesspools\nlink-for-water\nset-virus2\ndisplay-point_h\ndisplay-channel\nset-pcolor
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
1370
10
1630
170
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
1365
355
1630
480
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

PLOT
1370
170
1630
355
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
1365
605
1630
790
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
1365
485
1630
605
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

SLIDER
0
90
172
123
b-mice
b-mice
0
1
0.175
0.001
1
NIL
HORIZONTAL

SLIDER
0
120
172
153
b-bird
b-bird
0
1
0.2866
0.0001
1
NIL
HORIZONTAL

SLIDER
0
155
172
188
b-water
b-water
0
1
0
0.0001
1
NIL
HORIZONTAL

BUTTON
5
475
68
508
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
70
475
167
508
NIL
set-virus2
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
535
175
568
NIL
just-b23
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
90
505
177
538
NIL
behavior
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
535
117
568
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
15
735
78
768
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
1170
50
1233
83
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

BUTTON
125
740
230
773
set-ducks
ask ducks with [[pcolor] of patch-here = grey][move-to one-of foods-patches]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
1060
320
1132
353
NIL
gogogo
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
