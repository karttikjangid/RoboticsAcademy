# Multi-Stage Build Strategy — RADI Humble Images

Scope: design only. No Dockerfile syntax. All claims trace to the week-4 pre-refactoring
audit blog or to the eleven hard constraints in the task brief. Gaps are listed as
**Open Questions** rather than filled with assumptions.

> **Verification pass (against live images `robotics-academy:test` 18.2 GB and
> `robotics-applications:dependencies-humble` 12.8 GB).** Every size/path/classification below was
> re-checked with real `du`/`find`/`grep` output. The biggest result: the audit's claim that
> `--symlink-install` produces `.pth` files is **wrong** — it produces **symlinks from `install/`
> back into `src/`** (0 `.pth` files found), which overturns the "copy only 4 src dirs" premise.
> Corrections are marked **[CORRECTED]** inline; Open Questions 2 and 4 are now closed with
> evidence; Open Questions 1 and 3 remain open (architectural — need mentor input).

## Fixed facts that drive the whole design

- The pipeline is **two images built in sequence** (constraint 2):
  1. `Dockerfile.dependencies_humble` → `jderobot/robotics-applications:dependencies-humble`
  2. `Dockerfile.humble` → `jderobot/robotics-academy:$IMAGE_TAG`, built **`FROM` image 1**.
- Because image 2 is `FROM` image 1, **whatever the final stage of `Dockerfile.dependencies_humble`
  contains is simultaneously (a) the build base for `Dockerfile.humble` and (b) the transitive
  runtime base of the shipped image.** This single coupling is the central tension of the refactor
  and shapes every decision below.
- `colcon` (and `python3-colcon-common-extensions`) must remain in the **runtime** stage —
  `manager.py` runs `colcon build --symlink-install` at runtime in `/workspace/worlds/`
  (constraints 5, plus blog "runtime required" list).
- `--symlink-install` stays in every colcon invocation (constraint 1). **[CORRECTED]** The audit
  said this writes `.pth` files for the four `ament_python` packages and that only those four
  `src/` dirs (268 K) need to travel to runtime. Verified against the images this is **false**:
  there are **0 `.pth` files** in either workspace. `--symlink-install` instead creates **symlinks
  from `install/` back into `src/`** — `/home/ws/install/` holds **3206** such symlinks spanning
  **21 packages** (targets under `common_interfaces_cpp`, `CustomRobots`, `gz_ros2_control`,
  `Industrial`, `jderobot_drones_cpp`), and `/home/drones_ws/install/` holds **347** symlinks into
  `/home/drones_ws/src` (e.g. `as2_gazebo_assets` worlds/meshes/launch). So `install/` is **not**
  self-contained, and copying only the four 268 K dirs would leave thousands of **dangling
  symlinks** (broken worlds/meshes/launch/modules at runtime). The minimal set of `src/` to carry
  is therefore much larger and is an architectural call → **Open Question 1**.
- No `RPATH` is baked into the drone libs (`objdump -p` on `libdrone_lib_cpp.so`); resolution is
  purely via `LD_LIBRARY_PATH` from sourcing `/home/drones_ws/install/setup.bash`
  (constraint 10, blog). `/home/drones_ws/install/` (**52 M [CORRECTED]**, audit said ~72 M) is
  mandatory at runtime. **[CORRECTED]** Its `src/` is **also** required at runtime — not for
  `AEROSTACK2_PATH` (Open Question 2, now closed) but because of the 347 `install/`→`src/` symlinks
  above; the "drones_ws install-only" framing in the audit/constraint 10 does not hold.
- Build context is `scripts/RADI/` (constraint 11).

---

## Dockerfile.dependencies_humble

### Stages: 2

**Stage A — deps-builder.**
Full ROS Humble base + complete build toolchain. Responsibilities:
- Install build-time toolchain and SDK packages.
- Clone/stage and `colcon build --symlink-install` the Aerostack2 workspace at `/home/drones_ws/`
  (constraint 3).
- Install OMPL via `install-ompl-ubuntu.sh --github --python` (lines 388–391).
- Build `gz_ros2_control` into `/home/ws/` (lines 393–401 today **[CORRECTED line range]**):
  `git clone --depth 1 ... gz_ros2_control -b humble` into `/home/ws/src`, then
  `GZ_VERSION=harmonic colcon build --packages-select gz_ros2_control --allow-overriding gz_ros2_control`.
  Note this one build **omits `--symlink-install`** (so its own install is copy-based, not
  symlinked); the comment says it is required for the Pick Place Harmonic exercise controller
  loading. See Open Question 1 — this is the one place the prompt's "/home/ws/ is built in
  Dockerfile.humble" (constraint 4) does not match the current code, so I am not collapsing it.

**Stage B — deps-final (this is the published `dependencies-humble` image).**
Slim ROS Humble runtime base. It must be lean because it is the runtime base of the shipped image,
yet it must still let `Dockerfile.humble` compile `/home/ws/` on top of it. Responsibilities:
- ROS Humble runtime + `colcon` / `python3-colcon-common-extensions` (needed both for `humble`'s
  build and for runtime `colcon build`).
- Runtime-required tools the blog flags as counter-intuitive: `pylint`, `black`, `jedi`.
- Versioned **runtime** libs (not `-dev`): `libgeographic19`, `libpocofoundation80`,
  `libpcl-common1.12`, `libncurses6`, `libyaml-cpp0.7`.
- Receive `/home/drones_ws/install/` copied from Stage A.
- Append the `source` lines to `~/.bashrc` (`AEROSTACK2_PATH`, `source .../drones_ws/install/setup.bash`)
  so the `BASH_ENV` mechanism works downstream.

### In builder, NOT in runtime (Stage A only)

From the blog's "build-time only" list: `build-essential`, `cmake`, `rosdep`,
`ament-cmake` lint/test packages, `flake8`, `curl`, `wget`, `gnupg`, `lsb-release`, `git`,
`python3-pip`, `python-is-python3`, plus the colcon-mixin/lint/test extras. **[CORRECTED]** The
big source tree is `/home/ws/src` = **2.5 G** (the audit/earlier draft mis-attributed the 2.5 G to
`drones_ws`); `/home/drones_ws/src` is only **62 M**. Note that, per the symlink finding above,
neither `src/` tree can be dropped wholesale at runtime — only the sub-trees that no `install/`
symlink targets are safe to leave in Stage A (scope of Open Question 1).

### Must be explicitly copied builder → runtime

| What | Why |
|------|-----|
| `/home/drones_ws/install/` (**52 M [CORRECTED]**) | `LD_LIBRARY_PATH` resolution at runtime; no RPATH (constraint 10). |
| `/home/drones_ws/src/` targets of the 347 `install/`→`src/` symlinks (within the 62 M tree) **[CORRECTED — was "src not needed"]** | Without them the `install/` symlinks (worlds/meshes/launch) dangle at runtime. Exact minimal subset = Open Question 1. |
| (Open Q1) the `gz_ros2_control` portion of `/home/ws/install/` | So `Dockerfile.humble`'s `colcon build --packages-ignore gz_ros2_control` finds the already-built package. |

Everything else in Stage B is installed fresh in Stage B, not copied.

---

## Dockerfile.humble

### Stages: 2

This file is `FROM dependencies-humble`. Since Stage B above is deliberately slim (no
`build-essential`/`cmake`/`rosdep`), `Dockerfile.humble` cannot compile `/home/ws/` directly on it —
it needs a builder of its own.

**Stage A — humble-builder.** `FROM dependencies-humble`, then:
- Re-add the build toolchain (`build-essential`, `cmake`, `rosdep`, etc.) — temporarily, discarded
  with this stage. (Cost of this duplication is the subject of Open Question 3.)
- Clone `RoboticsInfrastructure` and `RoboticsAcademy` at the pinned refs; do the `mv` that lays out
  `/home/ws/src/` and the `/`-level scripts.
- `colcon build --symlink-install --packages-ignore gz_ros2_control gz_ros2_control_demos`
  in `/home/ws` (line 41, constraints 1 + 4).

**Stage B — humble-runtime (the shipped `robotics-academy:$IMAGE_TAG`).** `FROM dependencies-humble`
again (slim), then receive only the artifacts below from Stage A, and set runtime env.

### In builder, NOT in runtime (Stage A only)

- The re-added build toolchain (`build-essential`, `cmake`, `rosdep`, git/curl used for cloning).
- **[CORRECTED]** Only the parts of `/home/ws/src/` that **no** `install/` symlink targets are
  build-inputs-only and may stay in the builder. The earlier draft said "all of `src/` except four
  packages" — verification shows 3206 symlinks from `install/` into `src/` across 21 packages
  (targets under `common_interfaces_cpp`, `CustomRobots`, `gz_ros2_control`, `Industrial`,
  `jderobot_drones_cpp`), so far more than four packages' `src/` must be retained. The precise
  drop-safe set is Open Question 1.

### Must be explicitly copied builder → runtime

| What | Why |
|------|-----|
| `/home/ws/install/` (72 M, verified) | Built workspace the runtime sources/runs. |
| `/home/ws/src/` sub-trees targeted by the 3206 `install/`→`src/` symlinks **[CORRECTED]** | `--symlink-install` symlinks (not `.pth`) point from `install/` into these; dropping them dangles worlds/meshes/launch/modules. Spans 21 packages under `common_interfaces_cpp`, `CustomRobots`, `gz_ros2_control`, `Industrial`, `jderobot_drones_cpp` — **not** just the four below. |
| ↳ includes `jderobot_drones` (116 K), `tello_camera` (56 K), `tello_simple_teleop` (44 K), `platform_controller` (52 K) | The four `ament_python` packages the audit named — verified sizes correct, but they are a **subset**, not the whole requirement. |
| `/`-level scripts: `entrypoint.sh`, `ram_entrypoint.py`, `check_ram_version.sh`, `.env`, `start_vnc.sh`, `start_vnc_gpu.sh`, `kill_all.sh`, `set_dri_name.sh`, `check_device.py` | Constraints 7 + 8; `entrypoint.sh` is the ENTRYPOINT, `.env` is the `BASH_ENV` target. |
| `/RoboticsAcademy/` (academy app + `manager.py`) | Run at runtime by the manager. |

**[CORRECTED]** The "268 K of `src` is sufficient" figure from the blog is **wrong** — 268 K is
just the four named `ament_python` packages, while the symlink graph requires far more `src/`. The
exact minimal preserved set is Open Question 1.

### Runtime env that must be set in Stage B

- `NVIDIA_VISIBLE_DEVICES` as **ENV**, not ARG (constraint 6, blog NVIDIA finding). Pair it with the
  already-`ENV` `NVIDIA_DRIVER_CAPABILITIES` so the NVIDIA runtime sees both without relying on
  `docker run --gpus` injection.
- `BASH_ENV=/.env` (constraints 7/8). This is what makes the otherwise-redundant
  `source /home/drones_ws/install/setup.bash` (line 40) harmless and what auto-sources both
  workspaces in every non-interactive shell — including the runtime `colcon build`.

---

## Ordering constraints between the two Dockerfiles

1. **Stage B of deps = build base AND runtime base of humble.** It must be slim enough to ship yet
   complete enough to compile `/home/ws/` on top. The chosen resolution: keep deps Stage B slim and
   give `Dockerfile.humble` its own builder that re-adds the toolchain. Do **not** put
   `build-essential`/`cmake` back into deps Stage B to "make humble simpler" — that would reintroduce
   the bloat into the shipped image.
2. `dependencies-humble` must be built and tagged before `Dockerfile.humble` runs (already true in
   `build.sh`).
3. `/home/drones_ws/install/` must exist in deps Stage B before humble builds, because humble's
   `/home/ws` build and the runtime both rely on its `LD_LIBRARY_PATH` (sourced via `BASH_ENV`).
4. The `~/.bashrc` source lines added in deps Stage B must be in place before humble's build stage,
   otherwise humble's `colcon build` shells won't have the drones_ws environment.

---

## Open Questions (must resolve before implementation — not assumed)

1. **OPEN (architectural). Minimal `src/` to preserve + `gz_ros2_control` / `/home/ws` split.**
   Two coupled decisions:
   (a) Because `--symlink-install` links `install/` into `src/` (3206 links in `ws`, 347 in
   `drones_ws`), the runtime needs the *referenced* `src/` sub-trees, not just install/. The
   drop-safe subset must be derived from the symlink graph (or the image-build colcon must switch to
   copy-install for the shipping workspaces — but constraint 1 forbids removing `--symlink-install`).
   This is the central architectural call and needs mentor input.
   (b) Constraint 4 says `/home/ws/` is built in `Dockerfile.humble`, but
   `Dockerfile.dependencies_humble` (lines 393–401, verified) clones+builds `gz_ros2_control` into
   `/home/ws/` (that build omits `--symlink-install`) and `Dockerfile.humble` ignores it (line 41).
   Carry that partial `/home/ws/install/` forward from deps, or move the build entirely into
   `Dockerfile.humble`?

2. **CLOSED — `AEROSTACK2_PATH` is not a runtime dependency.** `~/.bashrc` exports
   `AEROSTACK2_PATH=/home/drones_ws/src/aerostack2` (deps line 383), but `grep -rn AEROSTACK2_PATH`
   across `/entrypoint.sh`, `/check_ram_version.sh`, `/opt/jderobot/Launchers/`, `dist-packages/`,
   `/RoboticsAcademy/exercises/`, and a broad `grep -rln` over `/RoboticsAcademy /opt/jderobot
   /home/ws` returns **only** the `export` line in the Dockerfile itself — no runtime code reads it.
   *However*, `/home/drones_ws/src` is still required at runtime for a different reason (the 347
   `install/`→`src/` symlinks), so the "install-only for drones_ws" rule is dropped regardless — see
   Open Question 1.

3. **Toolchain duplication.** With deps producing exactly one image (constraint 2), `humble-builder`
   must re-install `build-essential`/`cmake`/`rosdep`. Is the deps build allowed to publish or cache a
   second *builder* tag that `humble-builder` could use as `FROM` instead, avoiding the re-install —
   or is exactly one published deps image a hard requirement?

---

## Container-optimizer findings

Live baseline at audit time: `robotics-academy:test` **18.2 GB**, `robotics-applications:dependencies-humble`
**12.8 GB**. The multi-stage split above is the dominant lever (it removes the build toolchain and the
dev/test packages from the shipped layers, plus whatever portion of the 2.5 G `/home/ws/src` is **not**
pinned by `install/`→`src/` symlinks — see Open Question 1, which bounds how much `src/` can actually
be dropped). The items below are the
incremental wins, ordered by safety, and each is checked against the inter-container architecture
(Django :7164 / RAM :7163 / noVNC 6080–6090 / db_network) — none of them touch a port, a volume path,
or a runtime shared library.

### Tier 1 — safe, no functional risk

1. **Missing `--no-install-recommends` (12 sites in `Dockerfile.dependencies_humble`) — verified.**
   Lines 38, 56, 69, 87, 91, 119, 141, 156, 212, 229, 238, 289 run `apt-get install` without it
   (confirmed: the flag is absent across each full `RUN` block, not just the first line),
   pulling recommended extras into the base layers. `Dockerfile.humble` is already clean (0 sites).
   Add the flag everywhere except where a recommended package is actually required (verify the
   `lxde`/`nodejs`/i386 blocks, which sometimes rely on recommends).

2. **Unstripped C++ debug symbols.**
   - `/home/drones_ws` builds (lines 364, 371) set `-DCMAKE_BUILD_TYPE=Release` but **not**
     `-DCMAKE_EXE_LINKER_FLAGS="-s"` — symbols remain in the `.so`s that get copied into runtime
     (the **52 M** `drones_ws/install/`). Adding `-s` shrinks exactly the artifacts we carry forward.
   - `gz_ros2_control` (line 400) and the main `/home/ws` build (`Dockerfile.humble` line 41) pass
     **no** `--cmake-args` at all → default build type, symbols included. Add
     `-DCMAKE_BUILD_TYPE=Release` + `-s` there too. Keep `--symlink-install` (constraint 1) — it is
     orthogonal to cmake-args.

3. **Layer count.** `Dockerfile.dependencies_humble` has **51 `RUN`** instructions; `Dockerfile.humble`
   has 7. Post multi-stage split most of these land in the *builder* stage (discarded), so this is a
   build-cache/readability win, not a shipped-size win. Lower priority — consolidate only adjacent
   apt/pip RUNs to avoid wrecking layer-cache reuse during iteration.

4. **apt cache cleanup is already consistent** — every `apt-get install` block in deps is paired with
   `rm -rf /var/lib/apt/lists/*` (16 cleanup sites). No action needed; merged PR #3848
   ("apt cache purge normalization and pip `--no-cache-dir`") already normalized this. For context,
   PR #3856 (RoboticsInfrastructure ghost-layer removal) and PR #3863 (PyTorch → minimal CUDA
   wheels, −4.7 GB) are also merged and are already reflected in the 18.2 GB / 12.8 GB baseline.

### Tier 2 — moderate, verify with an integration run

5. **Aerostack2 source pruning** (`as2_platform_dji_matrice`, `as2_platform_pixhawk`, `mocap4ros2`,
   `as2_user_interfaces`, `as2_behaviors_*`). The runtime win is indirect: fewer packages built →
   smaller `/home/drones_ws/install/` (**52 M**, which *is* copied to runtime). **[CORRECTED]**
   Note `drones_ws/src` is 62 M (not 2.5 G — that figure is `/home/ws/src`), and the aerostack2
   Python packages are genuinely installed (verified: e.g. `as2_keyboard_teleoperation` is present
   in `install/`, not `COLCON_IGNORE`d). Verify nothing under `exercises/` or the drone solutions
   imports the pruned packages before dropping.

### Reconciliation with the audit — corrections to the generic multi-stage template

These override the skill's generic Tier-2 example where they conflict with verified findings:

- **Do NOT copy `/home/dev_ws/install` into runtime.** The audit found `/home/dev_ws` is build-time
  only — the `jderobot_drones_cpp/CMakeLists.txt:11` reference resolves at build time and leaves
  **no trace** (no RPATH) in the compiled output. The generic template copies it; we must not.
- **Two Dockerfiles, not one.** The generic template shows a single-file `builder`/`runtime` split
  off `nvidia/opengl…`. Our pipeline is fixed at two files with `Dockerfile.humble` `FROM
  dependencies-humble` (constraint 2). The split is applied *within each* file as described above;
  the deps base image stays `nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04`.
- **Patched MoveIt headers (`/opt/ros/humble/include/moveit/`) — resolved, no special COPY needed.**
  **[CORRECTED]** MoveIt/OMPL *are* used at runtime (`exercises/amazon_warehouse/cpp_template/
  CMakeLists.txt:23` → `find_package(ompl REQUIRED)`; `exercises/mobile_manipulation/*.launch` →
  `move_group`), and MoveIt is present in the image (139 `libmoveit*`, headers under
  `/opt/ros/humble/include/moveit*`). But since the runtime stage is `FROM dependencies-humble`
  (full ROS retained), those libs/headers are already there — no cross-stage COPY required. There is
  no evidence RoboticsAcademy ships *custom-patched* MoveIt headers, so the template's "or runtime
  crashes" caveat does not apply here. (See closed Open Question 4 below.)

### Must-not-touch (architecture guardrails confirmed against this design)

- `libGL`/`libGLX` and the VirtualGL/TurboVNC stack stay in runtime — noVNC/Gazebo rendering on
  6080–6090 depends on them.
- `colcon` + `python3-colcon-common-extensions`, `pylint`, `black`, `jedi` stay in runtime
  (manager.py uses them live) — already in deps Stage B above.
- No `.py`/`__pycache__` stripping; `/RoboticsAcademy/` Django app ships whole.
- Ports 7164 / 7163 / 6080–6090 and `db_network` are untouched by any item here.

### Verification (run before merging the refactor)

`curl -f http://localhost:7164/` (Django) · `curl -f http://localhost:6080/` (noVNC) ·
`ss -tlnp | grep 7163` (RAM ws) · `ldd` the copied `.so`s for `not found` ·
`docker images jderobot/robotics-academy` for the before/after size delta vs the 18.2 GB baseline.

### Open Question 4 — CLOSED

Does any shipped exercise load MoveIt/OMPL at runtime, and do patched headers need copying?
**Resolved.** `grep -rn 'ompl|move_group|planning_pipeline'` over `/RoboticsAcademy/exercises/`
confirms real usage — `amazon_warehouse/cpp_template/CMakeLists.txt:23 find_package(ompl REQUIRED)`
and `mobile_manipulation/*.launch` including `move_group`. MoveIt is present in the image (139
`libmoveit*`; `/opt/ros/humble/include/moveit*`). Because the humble runtime stage is `FROM
dependencies-humble`, which keeps the full ROS install, no explicit `/opt/ros/humble/...` COPY is
needed and no custom-patched headers were found. **Action: keep the ROS install in the runtime base
(already the case); no special handling.**
