# RADI optimization audit

Audited upstream `humble-devel`: `1d3594754f853d03fa223cee7e229aa27b940b1e`. Current branch remains `podman-compat-test`, HEAD `6e6de68b620825722dbb4714bed7e8863b9db5fa`. They differ (VERIFIED). Source was read through Git objects without checkout. Only audit reports were written. No image pulls or builds ran.

Linux image inspection was authorized in chat. No timing measurements were taken. Future Apple Silicon amd64 timings would be under emulation and not representative.

| Rank | Finding | Metric | Benefit + label | Confidence | Complexity |
| --- | --- | --- | --- | --- | --- |
| 1 | [Exclude discarded offline inputs before COPY](01-offline-copy.md) | Final image size and rebuild cache hit behaviour; context processing time. | UNKNOWN savings | high | ESTIMATED: a new ignore file and several COPY edits. No new builder features. Review must check every required runtime path. |
| 2 | [Clean database apt indexes in the installing layer](02-database-apt.md) | Final image size; cold build time may change with recommended packages, while apt index cleanup alone does not avoid package downloads. | UNKNOWN savings | high | ESTIMATED: one existing instruction. No new builder features. Easy to read. |
| 3 | [Replace unconditional no-cache with explicit source freshness](03-cache-policy.md) | Rebuild cache hit behaviour and rebuild time. No promised final image size reduction or first cold-build improvement. | UNKNOWN savings | high | ESTIMATED: several script and workflow lines plus Dockerfile source identity handling. No new instruction syntax. Medium review cost. |
| 4 | [Keep Academy edits and image tags after workspace compilation](04-compile-order.md) | Rebuild cache hit behaviour and rebuild time after cache-policy work. No claimed image size or cold-build saving. | UNKNOWN savings | medium | ESTIMATED: move a small block and metadata instructions in each application Dockerfile. No new features. Low to medium review cost. |
| 5 | [Separate frontend dependency installation from source changes](05-frontend-order.md) | Rebuild cache hit behaviour and rebuild time. Builder storage may change; no final image size saving is claimed because only selected frontend artifacts reach the final stage. | UNKNOWN savings | high | ESTIMATED: several frontend-stage instructions. The online clone path needs a way to retrieve matching manifests before the rest of the source, so it is more complex than the offline path. No new syntax is necessary. |
| 6 | [Evaluate apt recommendations package group by package group](06-apt-recommends.md) | Final image size and cold package download/install time. No guaranteed rebuild-cache improvement. | UNKNOWN savings | medium | ESTIMATED: one option per selected install instruction, with explicit runtime additions as needed. No new builder features. Runtime review cost can be substantial. |
| 7 | [Persist dependency build cache across CI jobs](07-ci-cache.md) | Rebuild cache hit behaviour across CI runs and rebuild time. No final image size saving. First cache population can add export time. | UNKNOWN savings | medium | ESTIMATED: several workflow lines and explicit builder/output configuration. No Dockerfile syntax change. Medium complexity, ranked below simpler local changes. |

Ranking weighs evidence, likely reuse or retained payload, runtime risk and review cost. It is qualitative, not a measured benefit score. Cache-policy work is a prerequisite for the layer-order findings. Existing multi-stage dependencies work is not proposed again. Runtime colcon and its filesystem symlinks are retained.

Files read in full are listed in [evidence/source-files.txt](evidence/source-files.txt). The list includes all tracked workflows, RADI Dockerfiles except the explicitly excluded Jazzy dependency file, both build scripts, support scripts and RADI README. No tracked ignore files were found. Binary GPU packages were inventoried, not executed. No upstream AGENTS.md appeared in the tree inventory.

Build chain:

- `Dockerfile.dependencies_humble:1` starts from NVIDIA OpenGL Ubuntu and produces dependencies-humble via `build.sh:102-126` and the image workflows.
- `Dockerfile.humble:1,16` uses a Node frontend stage and dependencies-humble as the final base. `build.sh:143-151` and the image workflows produce robotics-academy.
- `Dockerfile.humble_offline:1,16` uses the same bases with local input copies. `build.sh:139-151` selects the repository root context. The normal path uses the caller's current directory; CI explicitly changes to scripts/RADI.
- `Dockerfile.database:1` starts from postgres and produces robotics-database in the database workflow and release workflow.
- `release_Robotics_Academy.yml:38-57` delegates to the image and database workflows. `release.yml` builds both directly. Lint workflows do not build images.
- `jazzy.sh:96-115,128-136` selects the out-of-scope Jazzy dependency Dockerfile and the Humble application file. It is inventoried, not an optimization target.

See [layer mapping](layers.md), [verification](99-verification.md), and [open questions](open-questions.md).
