# Replace unconditional no-cache with explicit source freshness

Location and evidence:

- [`scripts/RADI/build.sh:114-126`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/build.sh#L114)
- [`scripts/RADI/build.sh:143-151`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/build.sh#L143)
- [`.github/workflows/generate_Robotics_Academy.yml:105-114`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/generate_Robotics_Academy.yml#L105)
- [`.github/workflows/generate_Robotics_Academy_Database.yml:78-84`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/generate_Robotics_Academy_Database.yml#L78)
- [`.github/workflows/release.yml:40-53`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/release.yml#L40)
- [`.github/workflows/release.yml:91-97`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/release.yml#L91)
- [`scripts/RADI/Dockerfile.humble:9-13`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble#L9)
- [`scripts/RADI/Dockerfile.humble:25-26`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble#L25)
- [`scripts/RADI/Dockerfile.humble:47-54`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble#L47)
- [`scripts/RADI/Dockerfile.database:14-16`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.database#L14)

Current behaviour: The application build always passes --no-cache in build.sh. CI also passes it for application and database builds. Inputs include mutable Git branches, raw SQL URLs, and an unpinned pip package. Reusing an unchanged RUN instruction alone would not establish that remote inputs are current.

Proposed change: Introduce explicit immutable source and package identities before making normal builds cache-enabled, while keeping a deliberate fresh-build option.

Metric affected: Rebuild cache hit behaviour and rebuild time. No promised final image size reduction or first cold-build improvement.

Benefit: UNKNOWN seconds and cache hit counts. Static evidence proves cache reuse is disabled by these invocations, not the amount of time it costs.

Confidence: high. The flags are explicit. A safe replacement requires source freshness to be addressed.

Complexity: ESTIMATED: several script and workflow lines plus Dockerfile source identity handling. No new instruction syntax. Medium review cost.

Risk: Simply removing --no-cache can silently retain old branch content, SQL, and robotics_application_manager. The Dockerfiles clone branch names, so a commit cannot just be substituted into the existing -b argument. Docker and Podman need separate cache-enabled rebuild checks.

How to measure in a deep-dive: In a future isolated test, use fixed source commits, SQL digests, base digests and package versions. Build the baseline with its current flags, then a cache-enabled variant twice. Change only the Academy source identity and then only Infrastructure identity. Record cached steps and elapsed time separately. Verify the intended commits and SQL are inside each image.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
