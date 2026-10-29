# Open questions and limits

No blocking repository question remains. The upstream ref and Linux host were authorized in chat. All findings are candidates, not measured savings.

- The upstream Git fetch emitted duplicate submodule configuration warnings for historical object c62d9d8dca48b5ca14169e8b8d1e6eb075c06804 and entered a recursive submodule fetch. Its final completion was not confirmed. The main upstream revision was fetched successfully. No submodule content was used for measurements or modified deliberately.
- The sandbox initially failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`. Later commands used approved escalation. An interrupted execution cell was unavailable on resume.
- A direct documentation request to https://raw.githubusercontent.com/containers/buildah/v1.33.7/docs/Containerfile.5.md returned HTTP 404. BuildKit feature evaluation stopped at this failure. No support claim is made for cache mounts, bind mounts, COPY --link, heredocs or syntax directives on the target Podman/Buildah package. These techniques remain deferred, not ranked recommendations. A version-correct official Containerfile reference is needed to resume that part.
- The read-docs skill was read for compatibility research. Its Firecrawl retrieval workflow was not completed. The cited Docker cache and versioned Podman build pages were retrieved through the web tool. Documentation research is limited to those successful pages.
- Local layer commands include historical NVIDIA_VISIBLE_DEVICES build arguments. Current upstream Humble uses ENV at Dockerfile.dependencies_humble:4. These local images are historical evidence, not proof the known bug remains upstream.
- The current upstream dependency Dockerfile already uses pip --no-cache-dir. No pip-cache hygiene finding is proposed. Reusable pip download caches are deferred with the unverified mount compatibility work.
- No build-only package was proven safe to remove. Runtime colcon, workspace sources and symlink targets were not proposed for removal. The supplied multi-stage savings and symlink counts were not remeasured and are not used as measured benefits here.
- Dependency Dockerfile COPY at line 101 adds GPU deb archives and later RUN lines 111-122 delete them. This is another retained-lower-layer candidate. It is not ranked because the simplest transient-input alternative requires the deferred bind-mount compatibility check or extra stage complexity. No bytes saved were measured.
- The OMPL helper installs packages and runs apt update/upgrade without a final list cleanup. Dockerfile.dependencies_humble:372 invokes it without list cleanup. This is another apt hygiene candidate, but the dependency base already contains package state and the removable list bytes were not measured. It is not ranked separately from the package hygiene work.
- Registry cache benefits depend on actual cache transfer and builder output behavior. No CI job was run.

Select a candidate before any pull or build. Exact commands, input identities and expected resource use must be presented for approval at that point.
