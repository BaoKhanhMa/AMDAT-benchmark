#!/bin/bash
set -euo pipefail

compare_paths() {
    local lhs="$1"
    local rhs="$2"
    local out_csv="$3"
    local rc

    if [ -f "$lhs" ] && [ -f "$rhs" ]; then
        if diff <(tail -n +2 "$lhs") <(tail -n +2 "$rhs") > /dev/null; then
            echo -n 0 >> "$out_csv"
        else
            rc=$?
            if [ "$rc" -eq 1 ]; then
                echo -n 1 >> "$out_csv"
            else
                echo "diff failed with exit code $rc while comparing files '$lhs' and '$rhs'" >&2
                exit "$rc"
            fi
        fi

    elif [ -d "$lhs" ] && [ -d "$rhs" ]; then
        if compare_dirs_skip_first_line "$lhs" "$rhs"; then
            echo -n 0 >> "$out_csv"
        else
            rc=$?
            if [ "$rc" -eq 1 ]; then
                echo -n 1 >> "$out_csv"
            else
                echo "directory comparison failed with exit code $rc for '$lhs' and '$rhs'" >&2
                exit "$rc"
            fi
        fi

    else
        echo "Cannot compare '$lhs' and '$rhs': both must be files or both must be directories" >&2
        exit 2
    fi
}

compare_dirs_skip_first_line() {
    local dir1="$1"
    local dir2="$2"
    local rel file1 file2

    while IFS= read -r -d '' file1; do
        rel="${file1#$dir1/}"
        file2="$dir2/$rel"

        if [ ! -e "$file2" ]; then
            echo "Missing in second directory: $rel" >&2
            return 1
        fi

        if [ -f "$file1" ] && [ -f "$file2" ]; then
            if ! diff <(tail -n +2 "$file1") <(tail -n +2 "$file2") > /dev/null; then
                rc=$?
                if [ "$rc" -eq 1 ]; then
                    echo "Files differ: $rel" >&2
                    return 1
                else
                    return "$rc"
                fi
            fi
        fi
    done < <(find "$dir1" -type f -print0)

    while IFS= read -r -d '' file2; do
        rel="${file2#$dir2/}"
        file1="$dir1/$rel"

        if [ ! -e "$file1" ]; then
            echo "Missing in first directory: $rel" >&2
            return 1
        fi
    done < <(find "$dir2" -type f -print0)

    return 0
}

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
            compare_paths "$iOutput" "$bOutput" "$csv_validation"
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
