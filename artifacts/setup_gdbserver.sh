#!/bin/bash

# Define the base path to the build folder where all the executables are located
BASE_PATH="/workspaces/install/opt"

# Define the path for the gdbserver script creation.
# Preferably, this should be in the same directory as the executables.
GDBSERVER_PATH="/workspaces/install/start_gdbserver.sh"

# Define the path for the run.sh script if you have.
# You need to disable the integrity check for the manifest validation as you will be changing the reporting behavior of the executable.
RUN_SCRIPT_PATH="/workspaces/install/run.sh"

# Check if the BASE_PATH exists
if [[ ! -d "$BASE_PATH" ]]; then
    echo "Error: Directory $BASE_PATH does not exist."
    exit 1
fi

echo "BASE_PATH: $BASE_PATH"  # Print BASE_PATH for debugging

# List all executables in the bin folders
echo "======= Listing Available Executables ======="
executables=()
index=0

# Use find to look for executables in the bin folders
while IFS= read -r bin; do
    if [[ -x "$bin" ]]; then
        executable_name="${bin##*/}"
        executables+=("$executable_name")
        printf "%-3d : %s\n" "$index" "$executable_name"
        ((index++))
    fi
done < <(find "$BASE_PATH" -type f -path "*/bin/*" -executable)

# Check how many executables were found
echo "==============================================="
echo "Total executables found: ${#executables[@]}"
echo "==============================================="

# Function to prompt user with green background
prompt_with_bg() {
    local prompt_text="$1"
    read -p "$(echo -e "\e[42m$prompt_text\e[0m") " input_variable
    echo $input_variable
}

# Ask user for the executable to debug with validation loop
while true; do
    exec_number=$(prompt_with_bg "Enter the number of the executable to debug (0 to $((index - 1))): ")
    if [[ "$exec_number" =~ ^[0-9]+$ ]] && [[ "$exec_number" -ge 0 ]] && [[ "$exec_number" -lt "${#executables[@]}" ]]; then
        break
    else
        echo "Invalid selection! Please provide a valid number between 0 and $((index - 1))."
    fi
done

echo "==============================================="  # Separator line

# Full path to the selected executable
selected_executable="${executables[$exec_number]}"
executable_path="$BASE_PATH/exe_$selected_executable/bin/$selected_executable"

# Correct the path to remove the extra "exe_" if necessary
executable_path="${executable_path/exe_exe_/exe_}"

# Set the etc path correctly
etc_path="$BASE_PATH/$selected_executable/etc"

# Check if the executable exists
if [[ ! -f "$executable_path" ]]; then
    echo "Executable not found at path: $executable_path"
    exit 1
fi

# Function to list available network interfaces with IP addresses
list_network_adapters() {
    echo "Available Network Interfaces:"
    count=1
    ifconfig | awk '/^[a-z]/ { iface=$1 } /inet / { printf "%-3d : %s %s\n", count++, iface, $2 }'
}

# Ask user to select a network adapter
while true; do
    list_network_adapters
    total_adapters=$(ifconfig -s | wc -l)
    
    adapter_number=$(prompt_with_bg "Enter the number of the network adapter of the adaptive machine: ")
    
    # Check if the selected number is valid
    if [[ "$adapter_number" =~ ^[0-9]+$ ]] && [[ "$adapter_number" -ge 1 ]] && [[ "$adapter_number" -le $((total_adapters - 1)) ]]; then
        adapter_name=$(ifconfig -s | awk -v num="$adapter_number" 'NR==num+2 {print $1}') # Get the adapter name based on number
        ip_address=$(ifconfig "$adapter_name" | grep 'inet ' | awk '{print $2}')
        
        if [[ -z "$ip_address" ]]; then
            echo "No IP address found for the selected adapter. Please choose a different adapter."
        else
            echo "Selected IP address: $ip_address"
            break
        fi
    else
        echo "Invalid adapter number! Please enter a valid number."
    fi
done

# Function to check if a port is available
check_port() {
    local port=$1
    ss -lntu | grep -q ":$port"
}

# Get user input for port number with validation loop
while true; do
    port_number=$(prompt_with_bg "Enter port number for gdbserver: ")
    if [[ "$port_number" =~ ^[0-9]+$ ]] && ! check_port "$port_number"; then
        break
    else
        echo "Port $port_number is either not a valid number or is already in use. Please enter another port."
    fi
done

# Ask for debugging option
echo "Choose an option:"
echo "1. Debug at entry point"
echo "2. Attach to an already running process"

while true; do
    debug_option=$(prompt_with_bg "Enter option (1 or 2): ")
    if [[ "$debug_option" == "1" || "$debug_option" == "2" ]]; then
        break
    else
        echo "Invalid option! Please enter 1 or 2."
    fi
done

if [[ "$debug_option" == "1" ]]; then
    # Option 1: Debug at entry point
    echo "======= Moving Executable to Backup ======="
    mv "$executable_path" "$executable_path.debug"
    echo "Backup completed successfully."

    echo "======= Creating start_gdbserver.sh Script ======="
    cat <<EOL > "$GDBSERVER_PATH"
#!/bin/bash
gdbserver $ip_address:$port_number "$executable_path.debug" "\$@"
EOL
    echo "Script created successfully."

    echo "======= Making the gdbserver Script Executable ======="
    sudo chmod +x "$GDBSERVER_PATH"
    echo "Permissions set successfully."

    echo "======= Creating Symlink ======="
    sudo ln -s "$GDBSERVER_PATH" "$executable_path"
    echo "Symlink created successfully."

    echo "======= Adding AMSR_DISABLE_INTEGRITY_CHECK to run.sh ======="
    echo "export AMSR_DISABLE_INTEGRITY_CHECK=1" | cat - "$RUN_SCRIPT_PATH" > temp && mv temp "$RUN_SCRIPT_PATH"
    echo "Line added successfully."
    sudo chmod +x "$RUN_SCRIPT_PATH"
    echo "Permissions set successfully."

    exec_config_path="$etc_path/exec_config.json"
    if [[ -f "$exec_config_path" ]]; then
        echo "======= Calling Python script to modify exec_config.json ======="
        python3 modify_exec_manifest.py "$exec_config_path"
        echo "exec_config.json updated successfully."
    else
        echo "exec_config.json not found at path: $exec_config_path"
    fi

elif [[ "$debug_option" == "2" ]]; then
    # Option 2: Attach to an already running process
    echo "Please run the adaptive machine to determine the PID of the process."
    
    while true; do
        adaptive_running=$(prompt_with_bg "Is the adaptive machine running? (y/n): ")
        case $adaptive_running in
            [Yy]* ) 
                pids=($(pgrep -f "$selected_executable"))

                if [[ ${#pids[@]} -eq 0 ]]; then
                    echo "No running process found for $selected_executable. Please ensure it's running."
                    exit 1
                fi

                echo "Found the following PIDs for $selected_executable:"
                for index in "${!pids[@]}"; do
                    printf "%-3d : %s\n" "$index" "${pids[$index]}"
                done
                
                while true; do
                    pid_index=$(prompt_with_bg "Enter the number corresponding to the PID you want to attach to: ")
                    if [[ "$pid_index" =~ ^[0-9]+$ ]] && [[ "$pid_index" -ge 0 ]] && [[ "$pid_index" -lt "${#pids[@]}" ]]; then
                        pid="${pids[$pid_index]}"
                        break
                    else
                        echo "Invalid selection! Please enter a valid number corresponding to the listed PIDs."
                    fi
                done

                echo "======= Creating start_gdbserver.sh Script ======="
                cat <<EOL > "$GDBSERVER_PATH"
#!/bin/bash
sudo gdbserver --attach $ip_address:$port_number $pid
EOL
                echo "Script created successfully."

                echo "======= Making the gdbserver Script Executable ======="
                sudo chmod +x "$GDBSERVER_PATH"
                echo "Permissions set successfully."

                echo "======= Starting gdbserver... ======="
                sudo "$GDBSERVER_PATH" &
                echo "gdbserver is now running and attached to PID $pid."
                break
                ;;

            [Nn]* )
                echo "Please run the adaptive machine first."
                ;;

            * )
                echo "Invalid input! Please enter 'y' or 'n'."
                ;;
        esac
    done
fi

echo "======= Setup Complete. You Can Now Debug the Executable Using gdbserver ======="
