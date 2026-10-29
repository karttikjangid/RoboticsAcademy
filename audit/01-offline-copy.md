# Exclude discarded offline inputs before COPY

Location and evidence:

- [`scripts/RADI/Dockerfile.humble_offline:9-13`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble_offline#L9)
- [`scripts/RADI/Dockerfile.humble_offline:25-41`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble_offline#L25)
- [`scripts/RADI/Dockerfile.humble_offline:47-57`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.humble_offline#L47)
- [`scripts/RADI/build.sh:139-151`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/build.sh#L139)

Current behaviour: The offline build copies the repository into both stages and copies RoboticsInfrastructure into the final stage. Later RUN commands delete files already recorded by COPY. The root repository COPY also includes RoboticsInfrastructure if populated. The upstream inventory contains no tracked .dockerignore or .containerignore.

Proposed change: Add carefully scoped ignore rules and narrow final-stage copies so files discarded by cleanup never enter final-stage COPY layers.

Metric affected: Final image size and rebuild cache hit behaviour; context processing time.

Benefit: UNKNOWN bytes and seconds. The lower-layer retention mechanism is confirmed by the COPY and later deletion instructions. No transmitted context size was measured.

Confidence: high. The COPY and cleanup boundaries are explicit. Actual payload depends on local files and the populated submodule.

Complexity: ESTIMATED: a new ignore file and several COPY edits. No new builder features. Review must check every required runtime path.

Risk: An ignore rule applies to both stages. It must retain common interfaces, frontend build inputs, local src, and required RoboticsInfrastructure assets. Do not exclude all scripts globally because the offline stage needs infrastructure entrypoints.

How to measure in a deep-dive: In an isolated future test checkout, build unchanged offline input and a narrowed-copy variant with identical populated submodules. Compare podman image inspect sizes and history. Compare each runtime path and exercise startup. Rebuild after changing only docs and observe which COPY and yarn steps rerun.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
