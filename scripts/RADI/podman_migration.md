# Rootless Podman RADI GPU Passthrough Execution & Testing Plan

## Scope & Architectural Context

This plan establishes a **rootless Podman** GPU passthrough architecture for the RoboticsAcademy (RADI) stack. 
- **Primary Goal**: Fully functional rootless NVIDIA discrete GPU passthrough via CDI (Container Device Interface) on the host machine (GTX 1650, Podman 4.9.3).
- **Secondary Goal**: Intel iGPU DRI passthrough design (flagged as design-only since host lacks Intel iGPU hardware).
- **Security & User Model**: Daemonless, rootless container execution (`--userns=keep-id` + supplementary group retention for GPU access).
- **Out of Scope**: ARM architecture, Quadlets migration, `Dockerfile.dependencies_jazzy` maintenance files, non-rendering CUDA compute tests.

---

# Part 1 — Cited Investigation Findings

## 1. Compose File Selection in Shell Scripts

### [run_academy.sh](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/run_academy.sh)

The script defaults to CPU mode and uses `-g` / `-n` flags to select compose files.

**Defaults** ([L2–6](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/run_academy.sh#L2-L6)):
```bash
# Default: cpu and offline
gpu_mode="false"
nvidia="false"
base_path_offline="compose_cfg/"
compose_file="user_humble_cpu"
```

**Flag parsing** ([L59–66](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/run_academy.sh#L59-L66)):
```bash
while getopts ":gnh" opt; do
  case $opt in
    g) gpu_mode="true" ;;
    n) nvidia="true" ;;
    h) show_help; exit 0 ;;
    \?) echo "Error: Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
  esac
done
```

**Compose file selection** ([L74–80](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/run_academy.sh#L74-L80)):
```bash
# Set the compose file based on flags
if [ "$gpu_mode" = "true" ]; then
  compose_file="user_humble_gpu"
fi
if [ "$nvidia" = "true" ]; then
  compose_file="user_humble_nvidia"
fi
```

**Copy and launch** ([L83–105](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/run_academy.sh#L83-L105)):
```bash
if [ -d compose_cfg ]; then
  cp "$base_path_offline$compose_file.yaml" docker-compose.yaml
else
  curl -sL "$base_path_online$compose_file.yaml" -o docker-compose.yaml
fi

if [ "$nvidia" = "true" ]; then
  docker compose --compatibility up
else
  docker compose up
fi
```

### [develop_academy.sh](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/develop_academy.sh)

**Compose selection & launch** ([L183–196](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/develop_academy.sh#L183-L196)):
```bash
if [ "$gpu_mode" = "true" ]; then
  compose_file="dev_humble_gpu"
fi
if [ "$nvidia" = "true" ]; then
  compose_file="dev_humble_nvidia"
fi
cp compose_cfg/$compose_file.yaml docker-compose.yaml

if [ "$nvidia" = "true" ]; then
  docker compose --compatibility up
else
  docker compose up
fi
```

---

## 2. Compose Files Under `compose_cfg/`

There are 8 compose files under `compose_cfg/`:
- **CPU Files** (`user_humble_cpu.yaml`, `dev_humble_cpu.yaml`): Contain zero device mounts or GPU environment directives.
- **iGPU DRI Files** (`user_humble_gpu.yaml`, `dev_humble_gpu.yaml`): Contain `devices: ["/dev/dri:/dev/dri"]` ([L21–22](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/compose_cfg/user_humble_gpu.yaml#L21-L22)).
- **NVIDIA Docker Files** (`user_humble_nvidia.yaml`, `dev_humble_nvidia.yaml`): Rely on Docker Swarm/daemon flags `deploy.resources.reservations.devices` and `runtime: nvidia` ([L21–31](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/compose_cfg/user_humble_nvidia.yaml#L21-L31)). **Incompatible with Podman rootless CDI.**

---

## 3. Vendor Detection & Downstream Consumers

- **[entrypoint.sh L44–47](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/RoboticsInfrastructure/scripts/entrypoint.sh#L44-L47)**: Calls `set_dri_name.sh` if `DRI_NAME` is unset.
- **[set_dri_name.sh L22–28](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/RoboticsInfrastructure/scripts/set_dri_name.sh#L22-L28)**: Runs functional `nvidia-smi` check, resolves card node in `/sys/bus/pci/devices/.../drm/`, and exports `DRI_NAME` (e.g. `card1`) and `DRI_VENDOR` (`nvidia`).
- **[launcher_interface.py L27–28](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/src/robotics_application_manager/manager/launcher/launcher_interface.py#L27-L28)**: Returns `/dev/dri/{DRI_NAME}`.
- **[launcher_gzsim.py L44–55](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/src/robotics_application_manager/manager/launcher/launcher_gzsim.py#L44-L55)**: Executes `vglrun gz sim -g --gui-config ...` with `VGL_DISPLAY={DRI_PATH}` if GPU acceleration is active.
- **[vnc_server.py L79–84](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/src/robotics_application_manager/manager/vnc/vnc_server.py#L79-L84)**: Starts TurboVNC with `-vgl` for GPU rendering.

---

## 4. Dockerfile Env Bug Status

- **[Dockerfile.dependencies_humble L4–5](file:///home/kartik/Documents/RoboticsAcademy/RoboticsAcademy/scripts/RADI/Dockerfile.dependencies_humble#L4-L5)**: Uses `ENV NVIDIA_VISIBLE_DEVICES=all` and `ENV NVIDIA_DRIVER_CAPABILITIES=all`. (Correct persistence).

---

# Part 2 — Machine & Document Empirical Verification Summary

| Load-Bearing Claim | Verification Method | Empirical Result | Action Taken in Plan |
| :--- | :--- | :--- | :--- |
| **Rootless GPU Group Access** | MCP Probe: `groups` & `ls -la /dev/dri/` | Host user `kartik` is not in `video` (GID 44) or `render` (GID 992) groups. `card1` is `root:video` (44), `renderD128` is `root:render` (992). | Add user to host groups `video,render` in Step 0. |
| **OCI Runtime `keep-groups` Support** | Web Search & MCP Probe: `podman info` | Podman 4.9.3 uses `runc` v1.3.6. `--group-add keep-groups` is an annotation supported **only by `crun`**. `runc` ignores it. | Require `crun` installation as explicit Step 0 prerequisite. |
| **Podman CDI Spec Version** | MCP Probe: `podman run --device nvidia.com/gpu=all` & Web (podman `go.mod` @ v5.0.0/5.2.0/5.4.1) | `podman run` failed: `unresolvable CDI devices: unknown field "additionalGids"`. Podman **4.9.3** bundles CDI lib **v0.6.2** and rejects `cdiVersion: 0.7.0` specs. Crossover: **v5.0.0 still ships CDI v0.6.2 (insufficient)**; **v5.2.0+ ships CDI v0.8.0** (parses `additionalGids`); **v5.5.1 regressed** (stopped reading `/run/cdi`). | **Upgrade Podman to v5.4.1** (CDI v0.8.0 — keeps `additionalGids` group-injection, avoids the v5.5.1 regression). Local-only fallback: downgrade the spec to `cdiVersion: 0.6.0` + strip `additionalGids` (safe only where DRI access exists independently, e.g. the logind ACL on this host). |
| **NVIDIA Env Var Role in CDI** | Web Search | `NVIDIA_VISIBLE_DEVICES` is a legacy OCI hook variable and causes double-injection conflicts if present with CDI. `NVIDIA_DRIVER_CAPABILITIES=all` (or `graphics,utility,display`) is required. | Drop `NVIDIA_VISIBLE_DEVICES` from CDI config. Keep `NVIDIA_DRIVER_CAPABILITIES`. |
| **Literal Devices vs CDI for Rootless** | System Architecture Analysis | Literal device mounts (`/dev/dri/card1`) without GID injection pass device node without group rights, causing `Permission Denied` under rootless. CDI provides GID injection (`gid: 44`, `gid: 992`) automatically. | Keep CDI as primary device injection mechanism once CDI spec compatibility is patched. |

---

# Part 3 — Sequential Implementation & Testing Plan

The plan is structured as an ordered sequence of granular, independently testable, and revertable steps. The riskiest unknown (CDI spec compatibility and CDI-in-compose resolution under rootless Podman) is settled first.

---

### Step 0: Host Prerequisites Setup (Group Membership, `crun`, CDI Compatibility)

- **Single Change**:
  1. Add host user to `video` and `render` groups: `sudo usermod -aG video,render $USER`.
  2. Install `crun` runtime: `sudo apt-get update && sudo apt-get install -y crun`.
  3. **Upgrade Podman to v5.4.1** (bundles CDI library v0.8.0, which parses the `cdiVersion: 0.7.0` / `additionalGids` spec that 4.9.3 rejects). Do **not** stop at v5.0.0 — it still ships CDI v0.6.2 and fails identically. Avoid v5.5.1 (regressed `/run/cdi` loading). *Local-only fallback if the upgrade is deferred:* patch the system CDI spec to `cdiVersion: 0.6.0` without `additionalGids` at `/etc/cdi/nvidia.yaml`.
- **Test Command**:
  ```bash
  # Verify group membership (requires new login shell or sg)
  id -Gn | grep -E "video|render"
  
  # Verify crun presence
  which crun
  
  # Verify CLI rootless GPU access with crun + CDI
  podman run --rm --runtime crun --group-add keep-groups --device nvidia.com/gpu=all ubuntu nvidia-smi
  ```
- **Expected Green Result**: `nvidia-smi` outputs `NVIDIA GeForce GTX 1650` with driver 580.159.03 inside container.
- **Red Mitigation**:
  - If group membership missing: log out/in or run `exec sg video "sg render bash"`.
  - If `crun` missing: install `crun` package via apt.
  - If CDI device unresolvable: confirm `podman --version` ≥ 5.2.0 (upgrade path); or, on the fallback path, that `/etc/cdi/nvidia.yaml` has `cdiVersion: "0.6.0"` and no `additionalGids` fields.

---

### Step 1: CDI-in-Compose Rootless Resolution Probe

- **Single Change**: Test `podman compose` with a temporary minimal rootless CDI override file (`/tmp/test_cdi_compose.yaml`).
- **Test Command**:
  ```bash
  cat << 'EOF' > /tmp/test_cdi_compose.yaml
  services:
    gpu-test:
      image: ubuntu:latest
      userns_mode: "keep-id"
      security_opt:
        - label=disable
      devices:
        - nvidia.com/gpu=all
      environment:
        - NVIDIA_DRIVER_CAPABILITIES=all
      command: nvidia-smi
  EOF

  podman compose -f /tmp/test_cdi_compose.yaml up
  ```
- **Expected Green Result**: `podman compose` launches container, executes `nvidia-smi` showing GTX 1650, and exits 0.
- **Red Mitigation**:
  - If `podman compose` ignores `devices:` CDI string: pass `--device nvidia.com/gpu=all` via `podman-compose` or verify compose provider settings in `containers.conf`.
  - Revert: `rm /tmp/test_cdi_compose.yaml`.

---

### Step 2: Compose Architecture Refactoring (Base + Overrides)

- **Single Change**: Refactor compose files into non-duplicated modular fragments under `compose_cfg/`:
  - `user_base.yaml` / `dev_base.yaml`: Common services, ports, volumes, `userns_mode: keep-id`.
  - `override_nvidia.yaml`: Adds `devices: ["nvidia.com/gpu=all"]`, `security_opt: ["label=disable"]`, `NVIDIA_DRIVER_CAPABILITIES=all`.
  - `override_intel.yaml`: Adds `devices: ["/dev/dri:/dev/dri"]`, `security_opt: ["label=disable"]`. (Design-only).
  - `override_cpu.yaml`: Empty override structure.
- **Test Command**:
  ```bash
  # Validate compose config merging (dry-run)
  podman compose -f compose_cfg/user_base.yaml -f compose_cfg/override_nvidia.yaml config
  ```
- **Expected Green Result**: Valid YAML generated containing `userns_mode: keep-id` and `nvidia.com/gpu=all` device spec.
- **Red Mitigation**: Fix YAML indentation or key syntax errors. Revert: `git checkout compose_cfg/`.

---

### Step 3: Shell Script Refactoring (`run_academy.sh` & `develop_academy.sh`)

- **Single Change**: Update host shell scripts to perform host-side GPU preflight detection (`nvidia-smi` functional check + CDI spec validation), support `--cpu`, `--nvidia`, `--intel` flags (retaining `-g`/`-n` backward compatibility), and launch via `podman compose -f <base> -f <override> up`.
- **Test Command**:
  ```bash
  # Dry-run flag parsing and preflight
  ./scripts/run_academy.sh --nvidia --help
  ```
- **Expected Green Result**: Script correctly selects `user_base.yaml` and `override_nvidia.yaml`.
- **Red Mitigation**: Fix bash script logic. Revert: `git checkout scripts/run_academy.sh scripts/develop_academy.sh`.

---

### Step 4: End-to-End Container Rendering Verification

- **Single Change**: Execute RADI container stack using refactored script with `--nvidia` flag and verify OpenGL hardware rendering inside Gazebo/VirtualGL pipeline.
- **Test Command**:
  ```bash
  # 1. Start stack
  ./scripts/run_academy.sh --nvidia

  # 2. Exec into running container and test OpenGL renderer string
  podman exec -it robotics_academy bash -c "VGL_DISPLAY=/dev/dri/card1 vglrun glxinfo | grep 'OpenGL renderer'"
  ```
- **Expected Green Result**: Output displays `OpenGL renderer string: NVIDIA GeForce GTX 1650/PCIe/SSE2` (must **NOT** say `llvmpipe` or `softpipe`).
- **Red Mitigation**:
  - Check container `/dev/dri/` permissions and GID mapping.
  - Verify `set_dri_name.sh` identified `card1` as NVIDIA DRI node.
