# Separate frontend dependency installation from source changes

Location and evidence:

- [`scripts/RADI/Dockerfile.humble:9-13`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble#L9)
- [`scripts/RADI/Dockerfile.humble_offline:9-13`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble_offline#L9)

Current behaviour: The complete application clone or COPY precedes a combined yarn install and yarn run build instruction. A source change that invalidates that input also invalidates dependency installation.

Proposed change: Install dependencies from package manifests and the lockfile before introducing the remaining frontend sources, then run the frontend build separately.

Metric affected: Rebuild cache hit behaviour and rebuild time. Builder storage may change; no final image size saving is claimed because only selected frontend artifacts reach the final stage.

Benefit: UNKNOWN seconds and download bytes. No frontend installation was timed.

Confidence: high. The manifest-independent source COPY is before the combined dependency and build instruction.

Complexity: ESTIMATED: several frontend-stage instructions. The online clone path needs a way to retrieve matching manifests before the rest of the source, so it is more complex than the offline path. No new syntax is necessary.

Risk: Check Yarn lifecycle scripts and local dependencies before copying manifests alone. All manifests and lockfiles must come from the same source identity. This depends on cache-policy work.

How to measure in a deep-dive: In a future approved test, compare cached baseline and split-install variants with unchanged manifests and a single frontend code edit. Record yarn install cache hits, build output differences and elapsed time. Repeat with a lockfile edit to confirm dependency installation invalidates.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
