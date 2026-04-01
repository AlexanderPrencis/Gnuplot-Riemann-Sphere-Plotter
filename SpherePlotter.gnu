# # Sphere ====================================================================
# # Initial File Setup
reset
set terminal pngcairo size 1440,1080 enhanced color font 'Helvetica,14'
filetype = "avi"        # Animation output filetype
                        # (ex. as specified in the ffmpeg scripts for .avi output, set filetype = "avi")
datafile = "DATA.dat"   # Input data file
N = 999999999           # Arbitrarily Large Number
ANIMATION = 1           # Set to 1 to enable Animation Rendering, set to 0 to disable Animation
MODEL = 0               # Set to 1 for Interactible 3D Model (Pops up in external window)
                        # May be slow depedning on the scale of the dataset
unset key

# # Axis Settings
set xrange[-1.1:1.1]
set yrange[-1.1:1.1]
set zrange[-1.1:1.1]

# # View / Color Settings
set xyplane relative 0
set angles radians
phi(x,y) = atan2(y,x)
H(x,y) = (phi(x,y) + 1.0)/(2.0*pi) + (1.0/3.0)   # Hue
S = 1.0                                # Saturation
V(z) = (z + 1.0)/2.0                   # Brightness

# # Color Key:                                          (+u) ^
# # w = -1 : Black,   w = 1 : Full Saturation                |    Cyan
# # u = -1 : Red,     u = 1 : Cyan               ==>         | Lime * Purple
# # v = -1 : Lime,    v = 1 : Purple        (on u-v plot)    |     Red

# # Plotted Sphere Settings                          (-u,-v) + ----------> (+v)
R = 1.0 # Radius of Sphere
set urange [-pi/2.0:pi/2.0]
set vrange [0.0:2*pi]
set trange [0.0:2*pi]
set parametric
set isosamples 20,20
#set hidden3d

# # Plotted data Settings
Min = 1     # For Full Sim Plot:
Max = 100   # Set Min = 1, Max = <Total Feval Calls>, (Set Max = N For Total Time)
            # (Use these vars for animation iteration too)

if (ANIMATION == 1) {
    plot datafile using 2:(LastPoint = $1)
    imax = int(LastPoint/(Max / 2.0)) + 1

    system("mkdir ./RSPlot/Palettes/")
    system("mkdir ./RSPlot/AnimationCacheRS")
    system("mkdir ./RSPlot/AnimationCacheXZ")

} else if (ANIMATION == 0) {
    MinPoint = Min
    MaxPoint = Max
    imax = 1

} else {
    print("Error - ANIMATION NEQ 0 or 1")
    exit
}

# # Plot
#  3D View ======================================================================
set xlabel "x"  # offset <left>, <right>, <up>, <down>      # Useful Offset Example
set xtics       # offset 0.5, 1, -4, 13.6
set ylabel "y"
set ytics
set zlabel "z"
set ztics

if ((ANIMATION == 0) && (MODEL == 1)) {
    set term qt
    set hidden3d
    set pm3d
}

do for [i = 1:imax] {
    print "Sphere ".i."/".imax.
    if (ANIMATION == 1) {
        MinPoint = (i-1)*(Max/2.0) + 1
        MaxPoint = (i+1)*(Max/2.0) + 1
    }
    set title = sprintf("Vector Time Progression (with color) [#%d]",i)
    set output = sprintf('./RS%04.0f.png',i)
    set view , # Plot Angles: set view ( , -> Default) / (xyz -> 3D) / (0,90 -> y,x) / (90,0 -> x,z) / (90,90 -> y,z)
    splot datafile u 2:3:4:(hsv2rgb(H($2,$3),S,V($4))) every ::MinPoint::MaxPoint w lp pt 15 ps 0 lc rgb variable, \
        R*cos(u)*cos(v),R*cos(u)*sin(v),sin(u) w l lw 0.5 lc rgb "grey"

    if ((ANIMATION == 0) && (MODEL == 1)) {
        pause
    }
}
# # Other View Angles Examples
# # XZ ==========================================================================
       set view 90,0                # (splot)
       unset ylabel                 # (splot)
       unset ytics                  # (splot)
       set xlabel "x" offset 0,-2   # (splot)
       set xtics                    # (splot)
       set zlabel "z"               # (splot)
       set ztics                    # (splot)

do for [i = 1:imax] {
    print "XZ ".i."/".imax.
    if (ANIMATION == 1) {
        MinPoint = (i-1)*(Max/2.0) + 1
        MaxPoint = (i+1)*(Max/2.0) + 1
    }
    set output sprintf('./XZ%04.0f.png',i)
    set title sprintf("XZ Parts Through Time [#%d]",i)
    splot datafile u 2:3:4:(hsv2rgb(H($2,$3),S,V($4))) every ::MinPoint::MaxPoint w lp pt 15 ps 0 lc rgb variable, \
        R*cos(u)*cos(v),R*cos(u)*sin(v),sin(u) w l lc rgb "grey"
}

# # FFMPEG ======================================================================
# Recomended Animation Settings for .avi and .gif outputs w/ corresponding ffmpeg scripts
if (ANIMATION == 1) {
    if (filetype == "avi") {
    # # .avi Outputs
    system("ffmpeg -framerate 30 -i ./RSPlot/AnimationCacheRS/RS%04d.png -vf scale=1440:1080 -preset slow -crf 18 ./RSPlot/RS.avi")
    system("ffmpeg -framerate 30 -i ./RSPlot/AnimationCacheUW/XZ%04d.png -vf scale=1440:1080 -preset slow -crf 18 ./RSPlot/XZ.avi")
    } else if (filetype == "gif") {
    # # .gif Outputs
    system('ffmpeg -framerate 10 -i ./RSPlot/AnimationCacheRS/RS%04d.png -vf "palettegen=stats_mode=full" ./RSPlot/Palettes/paletteRS.png')
    system('ffmpeg -framerate 10 -i ./RSPlot/AnimationCacheRS/RS%04d.png -i ./RSPlot/Palettes/paletteRS.png -filter_complex "paletteuse=dither=sierra2_4a" -loop 0 ./RSPlot/RS.gif')
    system('ffmpeg -framerate 10 -i ./RSPlot/AnimationCacheXZ/XZ%04d.png -vf "palettegen=stats_mode=full" ./RSPlot/Palettes/paletteXZ.png')
    system('ffmpeg -framerate 10 -i ./RSPlot/AnimationCacheXZ/XZ%04d.png -i ./RSPlot/Palettes/paletteXZ.png -filter_complex "paletteuse=dither=sierra2_4a" -loop 0 ./RSPlot/XZ.gif')
    } else {
        system("Incompatible filetype selected - Please change it in SpherePloter.gnu line 5 or add a new ffmpeg script past line 111")
    }
}
system("rm -rf ./RSPlot/Palettes/")
system("rm -rf ./RSPlot/AnimationCacheRS/")
system("rm -rf ./RSPlot/AnimationCacheXZ/")

# # Notes =======================================================================
# # The "warning: interal error -- stack not empty!" message comes from calling atan2(y,x),
# # I could not find a way to fix the issue, or hide the warning messages :/ sorry.
# # It works regardless though so dont worry.

# # There are also two ways to plot each of the 2-D plots, (UW/VW/UV) that being with the expected: plot x:y:(color),
# # but also splot x:y:z:(color) as used in the 3-D Bloch Sphere plot, while changing view angles to only see a single plane.
# # To activate, simply uncomment all lines that contain "# (splot)", change all "plot" to "splot", comment out
# # " cos(t), sin(t) w l lw 2 lc rgb "grey" ", and make sure x:y:z:(color) is formatted correctly. Plotting the 2-D plots in
# # this 3-D enviroment is heavier on the processor, but leads to clearer results, with clear seperation between low off axis values
# # (example: low and high w values in the u,v plot).

# # Attempt at Bloch Sphere Animation (Psuedocode)
# Create Directory for Animation Frames
# Create loop
    # Plot BlochSphere from Row(1) to Row(500)
    # Repeat for all Row(N*500 + 1) to Row((N+1)*500)
    # Untll Row((N+1)*500 + 1) >= Row(Max)
# End Loop
# Stitch frames together with ffmpeg into .mp4 or .gif
# Delete Cache
# END =========================================================================
