[[ $debug = true ]] && set -x
[[ $debug = true ]] && repeat=1 || repeat=10
version="ttmatvec-omp"
plot_dir=plot
plot_width=1080
plot_height=720
source_dir=.
output_dir=$BINARY_DIR/plot
ref=ttmatvec

mkdir -p $output_dir

echo "performing benchmarks .."

perf stat -o $BINARY_DIR/$ref-perf-report.txt -ddd -r $repeat ./$BINARY_DIR/$ref  -a $MAT -x $VECX -y $BINARY_DIR/ttvecy-$ref.bin
time_ms_ref=$(cat $BINARY_DIR/$ref-perf-report.txt | sed "s/^[ \t]*//" | grep "time elapsed" | cut -d" " -f1 | sed "s/,/\./")

echo > $output_dir/amdal.dat

for i in {1..40}
do
    OMP_NUM_THREADS=$i perf stat -o $BINARY_DIR/$version-perf-report.txt -ddd -r $repeat ./$BINARY_DIR/$version -a $MAT -x $VECX -y $BINARY_DIR/ttvecy-$version.bin
    time_ms=$(cat $BINARY_DIR/$version-perf-report.txt | sed "s/^[ \t]*//" | grep "time elapsed" | cut -d" " -f1 | sed "s/,/\./")
    speedup=$(echo "print($time_ms_ref/$time_ms)" | python3)
   echo "\"$i\" $speedup" >> $output_dir/amdal.dat
done


echo > $output_dir/amdal.conf
echo "set terminal png size $plot_width,$plot_height" >> $output_dir/amdal.conf
echo "set output \"$output_dir/amdal.png\"" >> $output_dir/amdal.conf 
echo "set xlabel \"threads nunmber\"" >> $output_dir/amdal.conf
echo "set ylabel \"speedup\"" >> $output_dir/amdal.conf
echo "set boxwidth 0.5" >> $output_dir/amdal.conf
echo "set style fill solid" >> $output_dir/amdal.conf
echo "plot \"$output_dir/amdal.dat\" using 2: xtic(1) with histogram notitle linecolor rgb \"green\"" >> $output_dir/amdal.conf

cat $output_dir/amdal.conf | gnuplot
cat $output_dir/amdal.dat

