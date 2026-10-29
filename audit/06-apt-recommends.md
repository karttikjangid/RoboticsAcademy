# Evaluate apt recommendations package group by package group

Location and evidence:

- [`scripts/RADI/Dockerfile.dependencies_humble:38-51`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L38)
- [`scripts/RADI/Dockerfile.dependencies_humble:54-77`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L54)
- [`scripts/RADI/Dockerfile.dependencies_humble:219-242`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L219)
- [`scripts/RADI/Dockerfile.dependencies_humble:270-338`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L270)

Current behaviour: Several dependency-image apt installs omit --no-install-recommends, while locales and VNC installs already use it. Most dependency-image apt installs already delete apt lists in the same RUN.

Proposed change: Test --no-install-recommends for selected installation groups and explicitly retain any recommended package required at runtime.

Metric affected: Final image size and cold package download/install time. No guaranteed rebuild-cache improvement.

Benefit: UNKNOWN bytes and seconds. No apt solver simulation or package diff was run. Large layers alone do not prove avoidable recommended packages.

Confidence: medium. The missing option is explicit, but the runtime necessity of recommended packages is untested.

Complexity: ESTIMATED: one option per selected install instruction, with explicit runtime additions as needed. No new builder features. Runtime review cost can be substantial.

Risk: ROS, Gazebo, VNC and GUI integrations can depend on implicitly installed tools. Keep colcon. Test GPU/CDI startup on suitable hardware and exercise representative simulations.

How to measure in a deep-dive: For each selected install group, compare apt simulated package sets against the same repositories and base. Build only promising variants after approval. Record package differences, per-layer size and cold-build time, then run the GUI, ROS, GPU and exercise checks.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
