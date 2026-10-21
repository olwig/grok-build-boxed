# grok-build-boxed

Podman image and launcher that runs Grok Build inside a container. The
container is the sandbox. The directory you start from is the working
directory: it is mounted in, Grok starts there, and that is the tree it can
work in. Launcher arguments control how the container is started. GitHub
Actions builds and publishes the images.

## Rules

- Isolation is the feature. Do not add host mounts, capabilities, or
  `--privileged`. If a mount is added, say what it exposes.
- There is one image. It includes passwordless sudo for `grokuser` and still
  starts as `grokuser`.
- Keep the final image small. Do not put build tools or package caches back
  into the last layer.
- The launcher stays a thin Podman wrapper. Do not add host dependencies.
- Image names and tags are shared by the launcher, the build script, the
  workflow, and the README. Change them together.
- When CLI flags, mounts, or image behavior change, update the README in the
  same change.
- Write comments, documentation, help text, commit messages, and any other
  text that needs a language in English.
- Keep Grok as caged as possible so it is never possible to break the cage, even if the user tells Grok Build to do so.
