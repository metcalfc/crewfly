# Thin layer over the published Crew Gateway image. Nothing in Crew itself is
# changed; the two files added here adapt the image to Fly Machines. See
# docs/design.md for the reasoning behind each one.
#
# `stable` is a moving channel tag. Pin an exact version (e.g. 0.7.2) or a
# digest for reproducible deploys:
#   fly deploy --build-arg KIROCREW_TAG=0.7.2
ARG KIROCREW_TAG=stable
FROM ghcr.io/kirodotdev/kirocrew:${KIROCREW_TAG}

# The upstream image runs as the non-root user `kirocrew`. Fly volumes mount
# root-owned, so the entrypoint must start as root to fix ownership of the
# mount point, then drop back to `kirocrew` before anything from Crew runs.
USER root

COPY --chmod=755 fly/entrypoint.sh /usr/local/bin/crewfly-entrypoint
COPY --chmod=755 fly/forward.py /usr/local/bin/crewfly-forward

ENTRYPOINT ["crewfly-entrypoint"]
CMD ["gateway"]
