# 29th July GPU Testing

## Overview
This document summarizes the testing and debugging efforts to migrate RoboticsAcademy to rootless Podman while enabling GPU acceleration via CDI (Container Device Interface). 
The initial work involved modifying the `dev-test-compose.podman.nvidia.yaml` file to translate Docker's GPU passthrough mechanisms into Podman-compatible CDI mappings (adding the `devices: ["nvidia.com/gpu=all"]` and `NVIDIA_DRIVER_CAPABILITIES=all` environment variables).

## Problems Encountered

1. **Network Namespace Issues (`aardvark-dns`)**
   - **Issue:** When running the container attached (`podman-compose up`) and stopping it via `Ctrl+C`, the shutdown process often timed out and resulted in a forceful `SIGKILL`. 
   - **Impact:** This forceful termination corrupted the networking namespace, leading to `aardvark-dns` errors ("runs in a different netns") on subsequent container startups, breaking internal DNS resolution (like connecting to the Postgres database).

2. **The Detached Mode (`-d`) "Buffering" Bug**
   - **Issue:** When running the container in detached mode (`podman-compose up -d`), refreshing the browser tab caused the Gazebo VNC viewer to get stuck on an infinite "Connecting..." spinner or display a black screen, appearing as if the rendering was endlessly buffering.
   - **Root Cause:** 
     - Refreshing the page triggers a websocket disconnect. During this disconnect, an unhandled Django error in `save_file` interrupted the backend cleanup sequence (`terminate_tools()`) in `manager.py`.
     - Because cleanup was aborted, the original `Xvnc` and `websockify` processes were never killed and became "zombies" holding onto port `6080`.
     - Upon reconnecting, a new Gazebo simulation and a new `Xvnc` session spawned on the next available port (`6082`). However, the React frontend (`tools.tsx`) has **hardcoded ports** and always attempts to connect Gazebo to `6080`. The UI effectively connected to the dead/leaked session, causing the infinite buffering.

3. **Camera Failure ("No image available")**
   - **Issue:** The camera widget reported "No image available" and `HAL.getImage()` returned `None`. This occurred both with and without GPU passthrough enabled, proving it was not a GPU issue.
   - **Root Cause:** A code version mismatch. The local repository had recently been updated to include namespace prefixes in ROS2 topics (e.g., `/f1/camera/image_raw`), but the Docker image (`jderobot/robotics-academy:test`) was built before this rename. Since the compose files did not bind-mount the `RoboticsInfrastructure` submodule, the built-in Gazebo models and launch files were still publishing to the old topic names, while the local Python exercise code was listening to the new names.

## Solutions & Best Practices

- **Proper Shutdown:** To avoid `aardvark-dns` and zombie process issues, always stop the environment gracefully by running `podman-compose down`. This fully wipes the container and its networking configuration, guaranteeing a clean slate for the next run.
- **Avoiding the Port Leak Bug:** Until the frontend is patched to dynamically assign ports (instead of hardcoding `6080`) and the backend `save_file` exception is caught, **never refresh the browser tab while connected**. If a refresh accidentally happens, perform a full `down` and `up` cycle to wipe the leaked processes.
- **GPU Validation:** We successfully proved GPU passthrough works under rootless Podman. Running `vglrun glxinfo` inside the container correctly reported the NVIDIA GTX 1650. While the simulation still runs very smoothly on the CPU without passthrough, enabling the GPU successfully offloads the 3D rendering workload and reduces CPU overhead.
