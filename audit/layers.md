# Local layer evidence

Exact commands and complete real JSON outputs are in evidence/*-history.txt. All byte values below are VERIFIED history values, not removable bytes or compressed registry transfer sizes. These existing images are not proven builds of the pinned upstream revision. A matching command is only a command-level mapping.

| Local dependency layer bytes, VERIFIED | Mapping | Qualification |
| --- | --- | --- |
| 2707660800 | [`scripts/RADI/Dockerfile.dependencies_humble:171-178`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L171) | Matching command. |
| 1259639808 | [`scripts/RADI/Dockerfile.dependencies_humble:270-338`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L270) | Not an exact match: current upstream also lists navigation2 and nav2-bringup. No exact mapping claimed. |
| 1198273536 | [`scripts/RADI/Dockerfile.dependencies_humble:68-73`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L68) | Matching command. |
| 869928960 | [`scripts/RADI/Dockerfile.dependencies_humble:372`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L372) | Matching command. |
| 803793920 | [`scripts/RADI/Dockerfile.dependencies_humble:75-77`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L75) | Matching command. |
| 784403968 | [`scripts/RADI/Dockerfile.dependencies_humble:145-150`](https://github.com/JdeRobot/RoboticsAcademy/blob/1d3594754f853d03fa223cee7e229aa27b940b1e/scripts/RADI/Dockerfile.dependencies_humble#L145) | Not an exact match: package lists differ. No exact mapping claimed. |

The database curl-install command matches Dockerfile.database:6 and has VERIFIED history size 31960576 bytes. The indexes-only portion is UNKNOWN. The largest database layers are inherited postgres content; no removal is proposed. Both application and database full histories are saved. No exact source provenance or per-file contents were inferred from history.
