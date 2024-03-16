FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
    && apt-get install -qqy --no-install-recommends \
    ca-certificates \
    sudo \
    tzdata \
    wget \
    curl \
    unzip \
    git \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Update Ubuntu Software repository
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell

ARG USERNAME=vscode

RUN mkdir -p /tmp/fonts
COPY ../fonts/AurulentSans*.otf /tmp/fonts
RUN mkdir -p /usr/share/fonts/truetype/ \
    && install -m644 /tmp/fonts/AurulentSans*.otf /usr/share/fonts/truetype/ \
    && rm -rf /tmp/fonts

COPY ../init/profile.ps1 /tmp/profile.ps1

RUN adduser $USERNAME && chsh --shell /usr/bin/pwsh $USERNAME

RUN curl -s https://ohmyposh.dev/install.sh | bash -s

USER $USERNAME
WORKDIR /home/$USERNAME

RUN pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name PSReadLine -SkipPublisherCheck -Force -AllowPreRelease; \
    Install-Module -Name Pester -SkipPublisherCheck -Force -RequiredVersion 4.10.0; \
    Install-Module -Name PSScriptAnalyzer -SkipPublisherCheck -Force; \
    Install-Module -Name dbatools -SkipPublisherCheck -Force; \
    Install-Module -Name dbachecks -SkipPublisherCheck -Force; \
    Install-Module -Name ImportExcel -SkipPublisherCheck -Force; \
    Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -SkipPublisherCheck -Force; \
    Install-Module -Name Microsoft.PowerShell.SecretStore -SkipPublisherCheck -Force; \
    Install-Module -Name Microsoft.PowerShell.SecretManagement -SkipPublisherCheck -Force; \
    Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault; \
    Reset-SecretStore -Authentication None -Interaction None -Force; \
    "

FROM builder AS final

RUN export PATH="$HOME/.local/share/powershell/Modules:$PATH" \
    && mkdir -p ~/.config/powershell \
    && cp /tmp/profile.ps1 ~/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && curl -O https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME

CMD ["/bin/sh", "-c", "while sleep 1000; do :; done"]
