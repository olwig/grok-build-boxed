FROM docker.io/archlinux/archlinux:latest

LABEL org.opencontainers.image.source="https://github.com/olwig/grok-build-boxed"

RUN pacman -Sy --noconfirm --needed \
        base-devel git sudo fish bubblewrap \
        less nano tmux github-cli \
        subversion copr-cli \
        pipewire-audio && \
    useradd -m -u 1001 builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    useradd -m -u 1000 -s /usr/bin/fish grokuser && \
    mkdir -p /etc/fish && \
    printf '%s\n' \
        'function fish_greeting' \
        '    echo' \
        '    echo "Boxed. Isolated. Mildly paranoid on purpose."' \
        '    echo "Grok can cook in here. It does not get the keys to the house."' \
        '    echo' \
        'end' \
        > /etc/fish/config.fish && \
    sudo -u builder bash -lc '\
        cd /home/builder && \
        git clone --depth 1 https://aur.archlinux.org/tini.git && \
        cd tini && \
        makepkg -si --noconfirm --rmdeps && \
        cd .. && rm -rf tini' && \
    pacman -D --asexplicit fakeroot && \
    pacman -Rns --noconfirm base-devel $(pacman -Qdtq) && \
    pacman -Scc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*

# Build args are the environment for this build. They are the AUR
# grok-build-bin version this image must install.
ARG GROK_BUILD_VERSION
ARG GROK_BUILD_PKGREL

LABEL org.opencontainers.image.version="${GROK_BUILD_VERSION}" \
      xyz.olwig.grok-build-boxed.version="${GROK_BUILD_VERSION}" \
      xyz.olwig.grok-build-boxed.pkgrel="${GROK_BUILD_PKGREL}"

# disable requirements in the container
RUN export GROK_BUILD_VERSION="$GROK_BUILD_VERSION" GROK_BUILD_PKGREL="$GROK_BUILD_PKGREL" && bash <<'EOS'
set -euo pipefail
test -n "$GROK_BUILD_VERSION"
test -n "$GROK_BUILD_PKGREL"
sudo -u builder bash -lc '
	cd /home/builder &&
	git clone --depth 1 https://aur.archlinux.org/grok-build-bin.git &&
	cd grok-build-bin &&
	makepkg -si --noconfirm --rmdeps &&
	cd .. && rm -rf grok-build-bin'
installed=$(pacman -Q grok-build-bin)
expected="grok-build-bin ${GROK_BUILD_VERSION}-${GROK_BUILD_PKGREL}"
if [ "$installed" != "$expected" ]; then
	echo "installed package '$installed' does not match expected '$expected'" >&2
	exit 1
fi
ver_out="$(timeout 30s /usr/bin/grok --version 2>&1 || true)"
parsed=$(printf '%s\n' "$ver_out" | awk 'NR==1 && $1=="grok" { print $2 }')
if [ "$parsed" != "$GROK_BUILD_VERSION" ]; then
	echo "grok version '$parsed' does not match GROK_BUILD_VERSION=$GROK_BUILD_VERSION" >&2
	printf '%s\n' "$ver_out" >&2
	exit 1
fi
mv /etc/grok/requirements.toml /etc/grok/requirements.toml.disabled
echo "grokuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/grokuser
chmod 0440 /etc/sudoers.d/grokuser
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*
EOS

USER grokuser
WORKDIR /home/grokuser

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["grok"]
