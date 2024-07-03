ARG STEAM_LINK="https://aur.archlinux.org/cgit/aur.git/snapshot/steamcmd.tar.gz"
ARG STEAM_PACKAGE_NAME="steamcmd.pkg.tar.zst"
ARG STEAM_PACKAGE_PATH="/artifacts/$STEAM_PACKAGE_NAME"

FROM archlinux:base-devel AS devel

ARG STEAM_LINK
ARG STEAM_PACKAGE_PATH

RUN printf "nobody   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syyu --noconfirm && \    
    mkdir -p /artifacts && \    
    chown -R nobody /artifacts && \
    cd /artifacts && \
    sudo -u nobody curl ${STEAM_LINK} --output steamcmd.tar.gz && \
    sudo -u nobody tar -xvpf steamcmd.tar.gz && \
    cd steamcmd && \
    sudo -u nobody makepkg --noconfirm -rcCs && \
    sudo -u nobody mv -v $(ls steamcmd-latest*pkg.tar.zst) $STEAM_PACKAGE_PATH

FROM golang:1.21 as godevel
WORKDIR "/go/src"
COPY ["main.go", "go.mod", "go.sum", "./"]

RUN go build -o  env-helper ./main.go

FROM archlinux:latest

ARG STEAM_PACKAGE_PATH

COPY --from=devel $STEAM_PACKAGE_PATH  $STEAM_PACKAGE_PATH

COPY --from=godevel /go/src/env-helper /usr/local/bin/ 

RUN useradd -u 1000 -m steamcmd && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && \
    echo "en_US.UTF-8" > /etc/locale.conf && \
    mkdir -p /runtime && \
    chown steamcmd:nobody -R /runtime &&\
    cd /home/steamcmd && \
    printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Sy wget wine xorg-server-xvfb --noconfirm && \
    pacman -U $STEAM_PACKAGE_PATH --noconfirm && \
    rm $STEAM_PACKAGE_PATH

COPY ["entrypoint.sh", "install_reforged_eden.sh", "install_reforged_eden_2.sh", "/usr/local/bin/"]
WORKDIR /runtime
USER steamcmd
VOLUME ["/runtime"]
ENTRYPOINT [ "entrypoint.sh" ]
