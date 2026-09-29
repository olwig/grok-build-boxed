FROM docker.io/archlinux/archlinux:latest

LABEL org.opencontainers.image.source="https://github.com/olwig/grok-build-boxed"

RUN pacman -Sy --noconfirm --needed \
        base-devel git sudo fish bubblewrap \
        less nano tmux github-cli \
        subversion copr-cli && \
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
        cd .. && rm -rf tini && \
        git clone --depth 1 https://aur.archlinux.org/grok-build-bin.git && \
        cd grok-build-bin && \
        makepkg -si --noconfirm --rmdeps && \
        cd .. && rm -rf grok-build-bin' && \
    pacman -Rns --noconfirm base-devel $(pacman -Qdtq) && \
    pacman -Scc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*

# disable requirements in the container
USER root
RUN mv /etc/grok/requirements.toml /etc/grok/requirements.toml.disabled

USER grokuser
WORKDIR /home/grokuser

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["fish"]
