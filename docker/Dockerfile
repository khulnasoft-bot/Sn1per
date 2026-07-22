# Sn1per Docker — Multi-stage build
# Stage 1: Dependencies
FROM kalilinux/kali-rolling AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git zip unzip bzip2 \
    python3 python3-pip python3-requests python3-bs4 \
    nmap masscan whatweb nikto wafw00f ffuf gobuster wfuzz \
    dirsearch nuclei hydra medusa crowbar \
    apktool jadx \
    metasploit-framework postgresql \
    openssh-client openssl \
    aha jq dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Sn1per installation
FROM base AS sniper-build

WORKDIR /opt
COPY . /opt/sniper/
RUN chmod +x /opt/sniper/install.sh && \
    /opt/sniper/install.sh --docker --no-prompt && \
    ln -sf /opt/sniper/sniper /usr/local/bin/sniper

# Stage 3: Runtime
FROM base AS runtime
COPY --from=sniper-build /opt/sniper /opt/sniper

RUN ln -sf /opt/sniper/sniper /usr/local/bin/sniper && \
    mkdir -p /opt/sniper/loot /opt/sniper/loot/workspace && \
    chmod 777 /opt/sniper/loot

VOLUME ["/opt/sniper/loot", "/opt/sniper/conf"]
EXPOSE 8080

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sniper", "--help"]
