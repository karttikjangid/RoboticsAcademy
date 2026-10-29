# Future command plan

These commands have NOT been run. They are not permission to pull or build. Run them only after separate approval, in an isolated test directory containing baseline and candidate Dockerfiles and matching fixed inputs. Image savings and time remain UNKNOWN. Variant filenames refer to future files, not files created in this audit.

For each selected Dockerfile pair, use the same builder, resolved base digest, build args, package index snapshot and populated local input tree. Replace mutable branch retrieval with a tested fixed-commit mechanism before cache experiments. Confirm all required images are local or obtain pull approval. BuildKit progress and timing logs do not prove correctness of runtime outputs.

Database cleanup experiment:

```sh
/usr/bin/time -p podman build --pull=never --no-cache -f baseline/Dockerfile.database --build-arg ROBOTICS_ACADEMY=humble-devel --build-arg ROBOTICS_INFRASTRUCTURE=database -t localhost/radi-audit-db:baseline scripts/RADI
/usr/bin/time -p podman build --pull=never --no-cache -f candidate/Dockerfile.database --build-arg ROBOTICS_ACADEMY=humble-devel --build-arg ROBOTICS_INFRASTRUCTURE=database -t localhost/radi-audit-db:candidate scripts/RADI
podman image inspect localhost/radi-audit-db:baseline localhost/radi-audit-db:candidate --format '{{.Id}} {{.Size}}'
podman history --no-trunc localhost/radi-audit-db:candidate
```

Freeze SQL inputs before execution if comparing the outputs. The displayed branch defaults alone do not freeze them.

Offline COPY experiment, from an isolated populated repository root:

```sh
/usr/bin/time -p podman build --pull=never --no-cache -f baseline/Dockerfile.humble_offline -t localhost/radi-audit-offline:baseline .
/usr/bin/time -p podman build --pull=never --no-cache -f candidate/Dockerfile.humble_offline -t localhost/radi-audit-offline:candidate .
podman image inspect localhost/radi-audit-offline:baseline localhost/radi-audit-offline:candidate --format '{{.Id}} {{.Size}}'
```

Cache, compilation order and frontend order experiments use the selected offline variant after source-freshness work. Populate cache and repeat this exact invocation without cleaning storage:

```sh
/usr/bin/time -p podman build --pull=never --layers -f candidate/Dockerfile.humble_offline --build-arg IMAGE_TAG=audit-a -t localhost/radi-audit-cache:test .
```

Repeat after a controlled frontend-only edit with unchanged lockfile, then with a lockfile edit. For the tag-only test change IMAGE_TAG to audit-b. Save complete output and identify executed versus cached yarn and colcon instructions. Compare with baseline using the same sequence. Run the Docker equivalents separately; do not infer Docker results from Podman.

For apt recommendations, use the selected fixed dependency variant and identical package indexes:

```sh
/usr/bin/time -p podman build --pull=never --no-cache --build-arg TARGETARCH=amd64 -f baseline/Dockerfile.dependencies_humble -t localhost/radi-audit-deps:baseline scripts/RADI
/usr/bin/time -p podman build --pull=never --no-cache --build-arg TARGETARCH=amd64 -f candidate/Dockerfile.dependencies_humble -t localhost/radi-audit-deps:candidate scripts/RADI
podman image inspect localhost/radi-audit-deps:baseline localhost/radi-audit-deps:candidate --format '{{.Id}} {{.Size}}'
```

The CI cache experiment needs a chosen writable isolated registry cache reference and builder output plan before exact runnable CI commands can be supplied. No registry write is authorized. Proposed Docker invocations must explicitly preserve the dependency image for the application build. This is unresolved experiment configuration, not a measured result.

Any timing collected on an Apple Silicon host for amd64 builds is under emulation and not representative. Linux timings must record architecture and hardware separately.
