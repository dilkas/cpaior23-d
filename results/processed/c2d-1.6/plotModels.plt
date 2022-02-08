
set terminal pdfcairo dashed fontscale 0.5
set termoption enhanced
#set terminal qt font "Helvetica,24"
set log x
set log y
set format y "10^{%T}"
set format x "10^{%T}"
set grid xtics ytics mxtics mytics lc rgb '#999999' lw 1 lt 0
#set xtics add (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000)
set xtics (1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000)
set xrange[15/1.1:31*1.1]
set yrange[0.58/10:500.0*10]
set key bottom right spacing 0.95

#set format x "%2.0tx10^{%L}"
#set format y "%2.0tx10^{%L}"

set ytics (0.0001, 0.001, 0.01, 0.1, 1, 10, 100, 1000, 10000, 1000000)
#set ytics add ("Censored" @@minNonZero@@/10.0, "Censored" @@cutoff@@)

set ylabel "CPU time [sec]"
set xlabel "n"

set style fill transparent solid 0.3 noborder

set arrow from 22,graph 0 to 22,graph 1 nohead lc 'black' dt 3 lw 2 
set output "fittedModels.pdf"
plot 'gnuplotTrainFile.txt' using 1:2 pt 1 lc "dark-grey" ps 1 title 'Support Data', \
'gnuplotTestFile.txt' using 1:2 pt 1 lc "light-grey" ps 1 title 'Challenge Data', \
x*0 + 500.0 lw 2 dt 2 lc 'black' title 'Running Time Cutoff', \
'gnuplotDataFile.txt' using 1:3:4 with filledcurves lc "blue" notitle,  \
'gnuplotDataFile.txt' using 1:5:6 with filledcurves lc "magenta" notitle,  \
'gnuplotDataFile.txt' using 1:7:8 with filledcurves lc "cyan" notitle,  \
'gnuplotDataFile.txt' using 1:2 smooth unique lc "blue" title 'Observed Median Scaling', \
0.002338478817538701*1.4282325958909183**x lc "magenta" title 'Exp Model', \
1.5911224340748983e-09*x**7.12552533032806 lc "cyan" title 'Poly Model', \
'' using (0):(0):(0) with filledcurves lc 'grey' title '95.0% Confidence Interval'