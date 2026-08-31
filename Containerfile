FROM docker.io/archlinux/archlinux:latest

# ensure sudo for make pkg
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed base-devel git sudo bubblewrap && \
    useradd -m -u 1001 -G wheel builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/builder && \
    echo "grok-build-boxed" > /etc/hostname

# install paru
USER builder
WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -rf paru

RUN paru -S --noconfirm grok-build-bin

# prepare running grok
USER root
RUN pacman -S --noconfirm --needed fish && \
    useradd -m -u 1000 -s /usr/bin/fish grokuser
USER grokuser
WORKDIR /home/grokuser
ENV HOSTNAME=grok-build-boxed

#ENTRYPOINT ["bash"]

CMD ["fish"]
