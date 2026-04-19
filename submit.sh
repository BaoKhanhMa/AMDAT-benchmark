#!/bin/bash

resources_alloc() {
    read -p "*  Please enter your job's name: " name
    #read -p "Partition's name: " partition
    #read -p "QOS: " qos
    read -p "*  Estimated running time [dd-hh:mm:ss]: " time
    #read -p "Number of nodes: " n_node
    #read -p "Number of task per node: " n_task
    read -p "*  Number of allocated CPUs [max=24]: " cpu
    read -p "*  Memory per CPUs [Ex: 16G]: " mem
    #read -p "Activate conda environment on compute node (Name?): " conda

    partition=simmons_itn18
    qos=sim18
    acc=normal
    conda=amdat
    n_node=1
    n_task=1
    conda=amdat

    echo "                                   ------Resources successfully allocated on cluster------"
    echo "#     Job's name:         $name"
    echo "#     Partition [$partition] with QoS [$qos]."
    echo "#     Account:            $acc"
    echo "#     Conda environment:  $conda"
    echo "#     Number of node:     $n_node"
    echo "#     Number of task:     $n_task"
    echo "#     Number of CPUs:     $cpu"
    echo "#     Memory allocated:   $mem"
    echo "#                                 --------------------------------------------------------"
}





echo "                                          ---Welcome to job submission window---"
echo "#             This application will automatically handle the configuration for your benchmarking process."
echo "                                          --------------------------------------"

read -p "*  Please specify your working environment [local(l)/cluster(c)]: " environment
read -p "*  Please tell us your configuration destination (Not config file): "  workdir
read -p "*  Please enter the name of your config file (excluding extension): " config

if [ $environment = 'l' ]; then
    # Getting the configs and runs autorun.sh
    source $workdir/$config.config
    cd $workdir/..
    echo "---Started running benchmark locally---"
    ./autorun.sh $environment $config $input $output $runs ${timegaps[@]}
else
    resources_alloc
    # Create a temporary file including the configuration reader and launching autorun.sh when the environment is cluster
    temp=$(mktemp)
    trap 'rm -f "$temp"' EXIT

    echo "conda activate $conda" >> $temp
    echo "source $workdir/$config.config" >> $temp
    echo "cd $workdir/.." >> $temp
    echo "echo "---Started running benchmark locally---"" >> $temp
    echo './autorun.sh $environment $config $input $output $runs ${timegaps[@]}' >> $temp

    sbatch --job-name=$name --partition=$partition --qos=$qos --account=$acc --node=$n_node --ntasks=$n_task --cpus-per-task=$cpus --mem=$mem --time=$time $temp

    echo "                                         ------Submission Completed Successfully------"
fi




