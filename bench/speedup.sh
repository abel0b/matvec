[[ $debug = true ]] && set -x
[[ $debug = true ]] && repeat=1 || repeat=10
versions="ttmatvec ttmatvec-baseline ttmatvec-seq ttmatvec-omp"
plot_dir=plot
plot_width=1080
plot_height=720
source_dir=.
output_dir=$BINARY_DIR/plot

mkdir -p $output_dir

echo "performing benchmarks .."

echo > $output_dir/speedups.dat
time_ms_ref=none
for version in $versions
do
    echo "$version"
    perf stat -o $BINARY_DIR/$version-perf-report.txt -ddd -r $repeat ./$BINARY_DIR/$version  -a $MAT -x $VECX -y $BINARY_DIR/ttvecy-$version.bin
    time_ms=$(cat $BINARY_DIR/$version-perf-report.txt | sed "s/^[ \t]*//" | grep "time elapsed" | cut -d" " -f1 | sed "s/,/\./")
    if [[ $time_ms_ref = none ]]
    then
        time_ms_ref=$time_ms
    fi
    version_name=$(echo $version | sed "s/ttmatvec-//")
    speedup=$(echo "print($time_ms_ref/$time_ms)" | python3)
   echo "\"$version_name\" $speedup" >> $output_dir/speedups.dat
done

echo > $output_dir/speedups.conf
echo "set terminal png size $plot_width,$plot_height" >> $output_dir/speedups.conf
echo "set output \"$output_dir/speedups.png\"" >> $output_dir/speedups.conf 
echo "set xlabel \"version\"" >> $output_dir/speedups.conf
echo "set ylabel \"speedup\"" >> $output_dir/speedups.conf
echo "set boxwidth 0.5" >> $output_dir/speedups.conf
echo "set style fill solid" >> $output_dir/speedups.conf
echo "plot \"$output_dir/speedups.dat\" using 2: xtic(1) with histogram notitle" >> $output_dir/speedups.conf

cat $output_dir/speedups.conf | gnuplot
cat $output_dir/speedups.dat

