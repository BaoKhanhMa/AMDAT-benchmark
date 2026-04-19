#!/bin/bash
set -euo pipefail

environment=$1      #local or cluster
csvname=$2          
input=$3            #Input file name
output=$4
runs=$5             #Number of runs
shift 5
timegaps=("$@")         #Time gaps array

#Destination for executing AMDAT
iPath=~/AMDAT-internal
bPath=~/AMDAT-benchmark
#Destination for reading input
iInput=$iPath/testfiles/$input
bInput=$bPath/testfiles/$input
#Destination for comparing output
iOutput=$iPath/testfiles/$output
bOutput=$bPath/testfiles/$output
#Destination for analysing benchmarking results
csv=$iPath/benchmark/$csvname/$csvname.csv
csv_validation=$iPath/benchmark/$csvname/${csvname}_validation.csv
png=$iPath/benchmark/$csvname

if [ $environment = 'l' ]; then
    threads=(1 2 4 8)
    echo -e timegaps,serial,thread1,thread2,thread4,thread8 > $csv
    echo -e timegaps,thread1,thread2,thread4,thread8 > $csv_validation
else
    threads=(1 2 4 8 12 16 24)
    echo -e timegaps,serial,thread1,thread2,thread4,thread8,thread12,thread16,thread24 > $csv
    echo -e timegaps,thread1,thread2,thread4,thread8,thread12,thread16,thread24 > $csv_validation
fi

for((runii=1;runii<=$runs;runii++));
do 
    echo Running with run = $runii
    for timegapii in ${timegaps[@]};
    do
        echo Time gap = $timegapii
        echo -n $timegapii, >> $csv
        echo -n $timegapii, >> $csv_validation

        cd $bPath
        sed -i "s/^exponential [0-9]*/exponential $timegapii/" $bInput
        ./AMDAT -i $bInput > /dev/null 2>> $csv
        echo -n , >> $csv

        cd $iPath
        sed -i "s/^exponential [0-9]*/exponential $timegapii/" $iInput
        for thread in ${threads[@]};
        do
            echo Analyzing threads = $thread
            ./AMDAT -n $thread -i $iInput > /dev/null 2>> $csv
            echo -n , >> $csv
            diff <(tail -n +2 "$iOutput") <(tail -n +2 "$bOutput") > /dev/null && echo -n 0 >> "$csv_validation" || echo -n 1 >> "$csv_validation"
            echo -n , >> $csv_validation
        done

        truncate -s -1 $csv
        truncate -s -1 $csv_validation
        echo -e >> $csv
        echo -e >> $csv_validation

    done

    echo -e >> $csv
    echo -e >> $csv_validation

done

#Run plotting script
cd $iPath/benchmark
python3 benchplot.py $csv $environment $png
