<div align="center">

![MSPEngine banner](docs/assets/banner.svg)

# MSPEngine

**MSP automation engine — PowerShell-based remote management, scripted deployments, monitoring checks, and client provisioning for managed service providers.**

[![GitHub release](https://img.shields.io/github/v/release/OneByJorah/MSPEngine?color=f97316&label=release&logo=github)](https://github.com/OneByJorah/MSPEngine/releases)
[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-MSPEngine-009FFD?style=flat-square&logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/MSPEngine)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?color=FFB300&logo=open-source-initiative&logoColor=FFB300)](https://opensource.org/licenses/MIT)

</div>

![MSPEngine screenshot](docs/assets/screenshot.png)

## What This Is

MSP automation engine — PowerShell-based remote management, scripted deployments, monitoring checks, and client provisioning for managed service providers.

## Quick Start

### PowerShell Gallery

```powershell
Install-Module -Name MSPEngine -Repository PSGallery
Import-Module MSPEngine
```

### Docker

```bash
git clone https://github.com/OneByJorah/MSPEngine.git
cd MSPEngine
docker compose up -d
```

### From Source

```bash
git clone https://github.com/OneByJorah/MSPEngine.git
cd MSPEngine
Import-Module ./MSPEngine/MSPEngine.psd1
```

## Features

- **Self-hosted** — run on your own hardware
- **Docker Compose** — full stack with one command
- **PowerShell Gallery** — install via PSGallery
- **Dark theme** — MSP-operations aesthetic

- **Remote management** — PowerShell-based host management
- **Scripted deployments** — automated software deployment
- **Monitoring checks** — scheduled health and status checks
- **Client provisioning** — new client onboarding automation
- **PowerShell Gallery** — publish as module
- **Dark theme** — MSP-operational aesthetic

## Functions

| Function | Description |
| -------- | ----------- |
| `Get-MSPHost` | Get host info from remote computer |
| `Invoke-MSPDeploy` | Deploy script to remote computer |
| `Test-MSPHealth` | Check host health (CPU, memory, status) |
| `New-MSPClient` | Create new client record |

## Package Badges

[![GitHub release](https://img.shields.io/github/v/release/OneByJorah/MSPEngine?color=f97316&label=release&logo=github)](https://github.com/OneByJorah/MSPEngine/releases)
[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-MSPEngine-009FFD?style=flat-square&logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/MSPEngine)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?color=FFB300&logo=open-source-initiative&logoColor=FFB300)](https://opensource.org/licenses/MIT)

## Contributing

[Open an issue](https://github.com/OneByJorah/MSPEngine/issues) to report a bug or request a feature.

## License

MIT — see [LICENSE](LICENSE).
