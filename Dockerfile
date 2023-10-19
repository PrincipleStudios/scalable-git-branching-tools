FROM ubuntu AS base
RUN  apt-get update \
  && apt-get install -y wget apt-transport-https software-properties-common \
  && wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && rm packages-microsoft-prod.deb \
  && apt-get update \
  && add-apt-repository universe \
  && apt-get install -y git powershell \
  && apt-get clean
RUN  git config --global user.email "test@example.com" \
  && git config --global user.name "Integration Testing" \
  && git config --global init.defaultBranch "main"

WORKDIR /root/.config/powershell/
RUN echo "\$ErrorActionPreference = 'Stop'" > profile.ps1

ADD . /git-tools

WORKDIR /git-tools
RUN pwsh -c 'Install-Module Pester -Force; Import-Module Pester -PassThru; Invoke-Pester; exit $lastExitCode'

WORKDIR /repos/

FROM base AS demo-local
RUN /git-tools/demos/demo-local.ps1

FROM base AS demo-local-cd
RUN /git-tools/demos/demo-local-cd.ps1

FROM base AS demo-local-with-space
RUN /git-tools/demos/demo-local-with-space.ps1

FROM base AS demo-remote
RUN /git-tools/demos/demo-remote.ps1

FROM base AS demo-remote-without-config
RUN /git-tools/demos/demo-remote-without-config.ps1

FROM base AS demo-remote-release
RUN /git-tools/demos/demo-remote-release.ps1

FROM base as final

WORKDIR /results/
COPY --from=demo-local /repos/report.txt demo-local-report.txt
COPY --from=demo-local-cd /repos/report.txt demo-local-cd-report.txt
COPY --from=demo-local-with-space /repos/report.txt demo-local-with-space-report.txt
COPY --from=demo-remote /repos/report.txt demo-remote-report.txt
COPY --from=demo-remote-without-config /repos/report.txt demo-remote-report-without-config.txt
COPY --from=demo-remote-release /repos/report.txt demo-remote-report-release.txt
RUN /git-tools/demos/_report.ps1 > full-report.txt

CMD ["cat", "full-report.txt"]
