# Debugging with GDB and GDBserver: A Comprehensive Guide

Debugging is an essential part of software development, and tools like **GDB (GNU Debugger)** and its companion tool **GDBserver** make the process easier, especially in complex environments. This guide provides a detailed explanation of how to use these tools effectively, particularly in scenarios involving remote debugging or embedded systems.

---

## Table of Contents
1. [Introduction to GDB and GDBserver](#introduction-to-gdb-and-gdbserver)
2. [How to Debug in Vector MSRA](#how-to-debug-in-vector-msra)
3. [Remote Debugging with GDBserver](#remote-debugging-with-gdbserver)
4. [Step-by-Step Debugging Process](#step-by-step-debugging-process)
    - [Default Mode (Halt at Entry Point)](#default-mode-halt-at-entry-point)
    - [Attaching to an Already Running Process](#attaching-to-an-already-running-process)
5. [Common Issues and Fixes](#common-issues-and-fixes)
6. [Why Symlinks Are Used for Remote Debugging](#why-symlinks-are-used-for-remote-debugging)

---

## Introduction to GDB and GDBserver

### What is GDB?
- **GDB (GNU Debugger)** is a powerful tool that helps developers identify and fix bugs in their programs.
- It allows you to:
  - Run your program step-by-step.
  - Inspect variable values.
  - Identify where things go wrong during execution.

### What is GDBserver?
- **GDBserver** is a lightweight companion tool designed for remote debugging.
- Instead of running GDB directly on the target machine (e.g., an embedded device or remote server), you run GDBserver on the target machine and connect to it from your development machine using GDB over a network.
- This setup is particularly useful for systems where running a debugger directly is impractical, such as:
  - Embedded systems.
  - Remote servers with limited resources.

### Key Features of GDBserver
- **Attach to Running Processes**: You can attach GDBserver to an already running program. The program's execution will be suspended until GDB connects.
- **Remote Control**: GDB on your development machine controls the debugging session via GDBserver.

---

## How to Debug in Vector MSRA

In Vector MSRA, diagnostic and debugging tools like `strace` or `gdb` are classified as **Non-Reporting Processes**. These tools are used to monitor **Reporting Processes** (the processes being debugged). Here’s how it works:

amsr_em_daemon --> gdbserver --> adaptive executable

### Key Points
1. **Start GDBserver Together with the Execution Manager (EM)**:
   - The EM should not spawn the process to be debugged by itself.
   - Instead, **GDBserver** will spawn the process to be debugged.
2. **Automatic Suspension**:
   - Once the process is spawned, GDBserver automatically suspends its execution at the entry point (typically the `main` function).
   - It waits for a debugger (GDB) to connect and take control.
3. **Connect GDB**:
   - You can connect GDB remotely to GDBserver and resume the process.

---

## Remote Debugging with GDBserver

Remote debugging allows you to debug applications running on a target system (e.g., a remote server or Docker container) using GDBserver and GDB.

### Default Mode (Halt at Entry Point)
1. **GDBserver Starts the Application**:
   - GDBserver starts the application to be debugged and halts execution at the entry point.
   - It waits for GDB to connect and take control.
2. **Steps to Debug Remotely**:
   - Build the project with debug symbols.
   - Start Adaptive Machine and GDBserver on the target machine.
   - Connect GDB from your remote machine to GDBserver.

---

## Step-by-Step Debugging Process

### Default Mode (Halt at Entry Point)

#### Step 1: Build the Project with Debug Symbols
Ensure your project is compiled with debug symbols (`-g` flag in GCC/Clang).

#### Step 2: Make the Script Executable
Run the following command to make the setup script executable:
```bash
sudo chmod +x /path/to/setup_gdbserver.sh
```

#### Step 3: Run the Adaptive Machine
- Start the adaptive machine and ensure the application to be debugged is running together with GDBserver.
- **Note**: Adaptive applications often have a short startup timeout. For interactive debugging, extend the startup timeout to avoid timeouts.

#### Step 4: Connect GDB to GDBserver
- Use VS Code or any other IDE to connect GDB to GDBserver remotely (Use launch.json and change the parameters as per the need)
- Alternatively, connect via the terminal:
  ```bash
  gdb <path_to_executable>
  (gdb) target remote <target_ip>:<port>
  ```

---

### Attaching to an Already Running Process

#### Step 1: Ensure the Project is Built with Debug Symbols
As before, ensure the project is compiled with debug symbols.

#### Step 2: Run the Adaptive Machine
Start the adaptive machine and let the application run.

#### Step 3: Attach GDBserver to the Running Process
Run the same setup script to attach GDBserver to the process you want to debug.

#### Step 4: Connect GDB to GDBserver
Connect GDB remotely to GDBserver:
```bash
gdb <path_to_executable>
(gdb) target remote <target_ip>:<port>
```

---

## Common Issues and Fixes

### Issue 1: Execution Dependency
- **Problem**: GDBserver does not handle execution dependencies of the process to be debugged.
- **Fix**: Remove execution dependencies before debugging. This is already handled in the `setup_gdbserver.sh` script.

### Issue 2: Port Availability
- **Problem**: GDBserver will not start if the specified port is unavailable.
- **Fix**: Ensure the port is free before starting GDBserver.

### Issue 3: Reporting Behavior
- **Problem**: Other applications in the same functional group (FG) may terminate when GDBserver halts the debugged application.
- **Fix**: Change the reporting behavior of the process to `DOES-NOT-REPORT-EXECUTION-STATE` in its execution manifest.

---

## Why Symlinks Are Used for Remote Debugging

### Problem with Environment Variables
- Applications started by the Execution Manager (EM) inherit environment variables like `AMSR_*`.
- GDBserver cannot overwrite these variables, as only the EM has control over them.

### Solution: Use Symlinks
- A symlink is created for the process to be debugged, pointing to the GDBserver binary.
- This ensures:
  1. The EM starts GDBserver instead of the actual process.
  2. GDBserver then spawns the actual process to be debugged.
  3. The environment variables of the process are retained.

---

## Conclusion

Using GDB and GDBserver together simplifies the debugging process, especially in remote or embedded environments. By following the steps outlined above and addressing common issues, you can efficiently debug your applications and resolve bugs with ease.

If you encounter any issues or need further clarification, refer to the official GDB documentation or consult your team's debugging guidelines.