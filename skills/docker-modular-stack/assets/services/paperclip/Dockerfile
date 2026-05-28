FROM  ghcr.io/paperclipai/paperclip:latest

RUN apt-get update 
RUN apt-get install -y glab curl xz-utils

# # Install Nix (single-user mode for containers)
# RUN mkdir -m 0755 /nix && chown node /nix
# RUN curl -L https://nixos.org/nix/install | su node -c "sh -s -- --no-daemon"

# ENV PATH="/home/node/.nix-profile/bin:${PATH}"

# # Install direnv via Nix using the store path directly
# RUN NIX_ENV=$(find /nix -name nix-env | head -1) && \
#     su node -c "HOME=/home/node $NIX_ENV -iA nixpkgs.direnv"

# # Hook direnv into bash
# RUN echo 'eval "$(direnv hook bash)"' >> /home/node/.bashrc