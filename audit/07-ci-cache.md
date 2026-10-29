# Persist dependency build cache across CI jobs

Location and evidence:

- [`.github/workflows/generate_Robotics_Academy.yml:73-114`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/generate_Robotics_Academy.yml#L73)
- [`.github/workflows/release.yml:11-53`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/.github/workflows/release.yml#L11)

Current behaviour: CI sets up Buildx but invokes plain docker build. The shown commands do not import or export an external build cache. The dependencies image is built locally before the application build.

Proposed change: Add a Docker-specific external cache path for the dependency build while preserving a locally usable dependency image for the following application build.

Metric affected: Rebuild cache hit behaviour across CI runs and rebuild time. No final image size saving. First cache population can add export time.

Benefit: UNKNOWN seconds, cache transfer size and cache hit rate. These workflows were read, not executed.

Confidence: medium. No cache import/export flags appear in the build commands; external runner caching behavior was not measured.

Complexity: ESTIMATED: several workflow lines and explicit builder/output configuration. No Dockerfile syntax change. Medium complexity, ranked below simpler local changes.

Risk: Buildx setup does not prove plain docker build uses the configured builder. Switching to buildx must load the dependency image or otherwise make it resolvable by the next build. Registry permissions and cache transfer overhead need testing. Do not copy Docker cache exporter flags into the Podman script.

How to measure in a deep-dive: Run an approved CI experiment against an isolated cache reference: first populate, then repeat with unchanged fixed inputs, then change an application input. Capture builder driver, dependency image availability, import/export time and cached steps. Compare with an otherwise identical uncached job.

Compatibility: This is a Docker CI change only. Podman build uses Buildah and has its own cache flag semantics. See [Podman versioned build documentation](https://docs.podman.io/en/v4.9.3/markdown/podman-build.1.html). No local Podman build-script change is proposed.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
