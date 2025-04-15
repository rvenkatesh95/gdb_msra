#!/bin/bash

## Change the path as per your need

# Define the base path to the build folder where all the executables are located
BASE_PATH="/workspaces/install/opt"

# Define the path for the gdbserver script creation.
# Preferably, this should be in the same directory as the executables.
GDBSERVER_PATH="/workspaces/install/start_gdbserver.sh"

# Define the path for the run.sh script if you have.
# You need to disable the integrity check for the manifest validation as you will be changing the reporting behavior of the executable.
RUN_SCRIPT_PATH="/workspaces/install/run.sh"

## Continue the other part as it is ....