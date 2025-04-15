import json
import sys

def modify_exec_config(json_file):
    with open(json_file, 'r') as f:
        config = json.load(f)

    # Change reportingBehavior if it exists
    if 'reportingBehavior' in config:
        config['reportingBehavior'] = 'DOES-NOT-REPORT-EXECUTION-STATE'

    # Iterate through each process and its startupConfigs to modify executionDependency
    if 'processes' in config:
        for process in config['processes']:
            if 'startupConfigs' in process:
                for startup_config in process['startupConfigs']:
                    if 'executionDependency' in startup_config:
                        startup_config['executionDependency'] = {}

    # Write the modified config back to the file
    with open(json_file, 'w') as f:
        json.dump(config, f, indent=4)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python modify_exec_config.py <path_to_exec_config.json>")
        sys.exit(1)

    modify_exec_config(sys.argv[1])
