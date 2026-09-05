FROM docker.io/archlinux/archlinux:latest

LABEL org.opencontainers.image.source="https://github.com/olwig/grok-build-boxed"

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed base-devel git sudo fish && \
    useradd -m -u 1001 -G wheel builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    useradd -m -u 1000 -s /usr/bin/fish grokuser

RUN mkdir -p /etc/fish && \
    printf '%s\n' \
        'function fish_greeting' \
        '    echo' \
        '    echo "Boxed. Isolated. Mildly paranoid on purpose."' \
        '    echo "Grok can cook in here. It does not get the keys to the house."' \
        '    echo' \
        'end' \
        > /etc/fish/config.fish

USER builder
WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -rf paru && \
    paru -S --noconfirm grok-build-bin


USER root
RUN pacman -S --noconfirm --needed bubblewrap
RUN pacman -S --noconfirm --needed fish
RUN pacman -S --noconfirm --needed less
RUN pacman -S --noconfirm --needed nano
RUN pacman -S --noconfirm --needed tmux 
RUN pacman -S --noconfirm --needed github-cli 
RUN pacman -S --noconfirm --needed copr-cli

# disable requirements in the container
RUN mv /etc/grok/requirements.toml /etc/grok/requirements.toml.disabled

USER grokuser
WORKDIR /home/grokuser

CMD ["fish"]
