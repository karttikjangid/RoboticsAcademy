# Keep Academy edits and image tags after workspace compilation

Location and evidence:

- [`scripts/RADI/Dockerfile.humble:43-73`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble#L43)
- [`scripts/RADI/Dockerfile.humble_offline:43-69`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble_offline#L43)

Current behaviour: IMAGE_TAG, application package installation, Academy input and frontend copies all precede the final workspace colcon build. These ancestors can invalidate compilation even though the workspace source comes from Infrastructure and the dependency base.

Proposed change: Move workspace compilation before unrelated Academy inputs and set IMAGE_TAG near the end, after validating that compilation does not depend on those inputs.

Metric affected: Rebuild cache hit behaviour and rebuild time after cache-policy work. No claimed image size or cold-build saving.

Benefit: UNKNOWN seconds. The layer ordering is verified, but independence of all compilation inputs needs a controlled build.

Confidence: medium. The source locations suggest separation; compilation could still rely on environment or package effects.

Complexity: ESTIMATED: move a small block and metadata instructions in each application Dockerfile. No new features. Low to medium review cost.

Risk: Confirm robotics_application_manager and moved environment variables are not required by colcon. Keep colcon and all symlink targets at runtime. This is conditional on cache-enabled builds.

How to measure in a deep-dive: With cache-policy safeguards in place, build baseline and reordered variants from identical fixed inputs. Change only IMAGE_TAG, then only a frontend source file. Compare colcon cache hits and startup behavior; inspect install symlinks without deleting build or source directories.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
