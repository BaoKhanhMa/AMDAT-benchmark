# Introduction

This is a lightweight benchmarking system that I built for myself to compare results and calculate speed-up when parallelizing AMDAT. Frankly, I realize that currently there is no kernel for future developers to facilitate their software development workflow. This system is certainly not full-fledge due to how minimalistic it is at the moment, but I will try to improve it while developing AMDAT. In short, I think it can be beneficial to publish this to my Github.

## Summary

This system features a simple CLI that allows you to create your own configuration file, comprising a range of problem size, number of runs, and input/output destination for benchmarking process. You can run this benchmarking workflow automatically on SLURM, which is a plus.

## Usage
1. Set up AMDAT (public) as your stable version and name it "AMDAT-benchmark" in the same directory with your developing AMDAT.
2. Create inputs and outputs for both AMDAT (developing) and AMDAT-benchmark. You can name them whatever you want.
3. Create a directory that has strictly the same name with your input file's name.
4. Create 3 files:
   - <input_file_name>.config
   - <input_file_name>.csv
   - <input_file_name>_validation.csv
5. Open your configuration file. The format should be set up like this:
   
   timegaps array reflects your problem sizes
```
input=<input_file_name>
output=<output_file_name>
runs=<number_of_runs>
timegaps=(10 20 30)
```

6. Runs submit.sh

