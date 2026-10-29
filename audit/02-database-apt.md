# Clean database apt indexes in the installing layer

Location and evidence:

- [`scripts/RADI/Dockerfile.database:1-6`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.database#L1)

Current behaviour: The database image installs curl after apt-get update without deleting apt lists in that RUN.

Proposed change: Delete apt indexes in the same RUN that installs curl and evaluate --no-install-recommends for that install.

Metric affected: Final image size; cold build time may change with recommended packages, while apt index cleanup alone does not avoid package downloads.

Benefit: UNKNOWN saving. VERIFIED local curl-install layer is 31960576 bytes, including installed packages and indexes. This is not the removable amount. See evidence/database-history.txt.

Confidence: high. The missing cleanup is visible in the complete install instruction.

Complexity: ESTIMATED: one existing instruction. No new builder features. Easy to read.

Risk: Keep curl available for the later SQL downloads. Test SQL initialization after changing recommended-package behavior. No colcon or GPU path is involved.

How to measure in a deep-dive: Build baseline and cleanup variant from the same resolved postgres base and package indexes in a future approved experiment. Compare image sizes and the curl layer. Inspect /var/lib/apt/lists in each resulting image and initialize the database with the same SQL inputs.

Compatibility: No BuildKit-specific syntax is proposed. Use existing COPY, RUN, ARG and ENV instructions or package-manager options. Validate on Docker and the target Podman/Buildah package versions during the deep-dive.

Cache mechanism reference: [Docker cache optimization documentation](https://docs.docker.com/build/cache/optimize/).

Source evidence is pinned to the upstream SHA recorded in the summary. Numbered copies are in evidence/source/. All numeric complexity counts are ESTIMATED. Experiment descriptions are proposals, not executed commands. Exact runnable commands require the selected variant and input identities; no builds are authorized in this phase.

Planned command templates: [experiments.md](experiments.md). They require the stated fixed inputs and approval before execution.
