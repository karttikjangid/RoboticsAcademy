# Independent verification

The verifier read the draft reports and reopened their source citations independently from pinned Git objects at `1d3594754f853d03fa223cee7e229aa27b940b1e`.

# Passed

- All full source ranges cited in finding reports were reopened. They support the stated current behaviour.
- Summary base-image, build-script and workflow-delegation citations were reopened.
- Every command in `evidence/commands.json` was rerun. All exited successfully. Their stdout exactly matched the original evidence after removing the original `$ command` heading. Repeated real outputs are saved in `evidence/verify-*.txt`.
- Branch, HEAD and upstream tracking SHA match the summary. Working tree status remains `?? audit/`.
- Layer history byte values in `layers.md` match the repeated JSON outputs. The database curl layer size also matches.
- CUDA wheel, Gazebo, ROS Gazebo bridge and OMPL commands match the cited upstream instructions at the command level. Source provenance remains unproven.
- The large ROS package layer lacks upstream navigation packages. The Python package layer includes a different PyYAML placement. Both are correctly qualified as differing commands.
- The tracked tree contains no `.dockerignore`, `.containerignore` or `AGENTS.md`. Its Dockerfile inventory matches the summary.
- No report proposes removing runtime colcon, its source or build symlink targets, GPU libraries, or the shelved dependency multi-stage experiment.

# Required editorial completion

The updated `open-questions.md` resolves the superseded revision and host blockers. Its added GPU archive and OMPL apt claims were checked against the pinned source.

`experiments.md` provides explicit future command templates. None was executed. They require future candidate files, fixed source retrieval, fixed bases and package inputs. The database commands explicitly still show mutable branch defaults; the report requires freezing SQL before execution. The CI cache experiment still lacks an exact runnable command because the cache destination and builder output plan remain unresolved. These are documented experiment limits, not verified measurements.

# Verification helper failure

A helper assumed the JSON property was `createdBy`. It failed with `KeyError: 'createdBy'` after all output comparisons and source-range reads had completed. Schema inspection showed `CreatedBy`. The layer review then succeeded with the actual schema. No evidence command failed and no image was built or pulled.

# Dropped claims

None of the source or measurement claims failed verification. Optimization savings remain UNKNOWN. No compatibility claim for cache mounts, COPY --link or heredocs was verified here.
