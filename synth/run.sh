#!/bin/sh

# Function to run the script in a directory
run_script() {
    if [ -d "$1" ]; then
        cd "$1" || exit
        if [ -x "run.sh" ]; then
            ./run.sh
        else
            echo "run.sh is not executable in directory $1"
        fi
        cd - > /dev/null || exit
    else
        echo "Directory $1 does not exist"
    fi
}

# Check the number of arguments
if [ "$#" -eq 0 ]; then
    # No arguments, iterate over directories starting with numbers
    for dir in $(ls -d [0-9][0-9]* 2>/dev/null | sort); do
        run_script "$dir"
    done
elif [ "$#" -eq 1 ]; then
    # One argument, ensure it's a number and navigate to the corresponding directory
    if [ "$1" -eq "$1" ] 2>/dev/null; then
        dir=$(ls -d $(printf "%02d" "$1")*)
        run_script "$dir"
    else
        echo "Argument must be a number"
        exit 1
    fi
elif [ "$#" -eq 2 ]; then
    # Two arguments, ensure they are numbers and iterate over directories
    if [ "$1" -eq "$1" ] 2>/dev/null && [ "$2" -eq "$2" ] 2>/dev/null; then
        start=$(printf "%02d" "$1")
        end=$(printf "%02d" "$2")
        for ((i = start; i <= end; i++)); do
            dir=$(ls -d $(printf "%02d" "$i")*)
            run_script "$dir"
        done
    else
        echo "Arguments must be numbers"
        exit 1
    fi
else
    echo "Usage: $0 [start] [end]"
    exit 1
fi
