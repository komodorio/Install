![komodor logo](https://avatars.githubusercontent.com/u/60484489?s=200&v=4)

# Komodor Installer

## Install Komodor (on macOS / Linux / WSL)

`HELM_API_KEY=<komodor_agent_api_key> USER_EMAIL=<user_email> bash <(curl -s -Ls https://raw.githubusercontent.com/komodorio/Install/ master/install.sh)

## Install komodor (on windows)

`[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls'; (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/komodorio/Install/master/install.ps1", "$env:TEMP\install.ps1"); & PowerShell.exe -ExecutionPolicy Bypass -File $env:TEMP\install.ps1 <komodor_agent_api_key> <user_email>;`

## Go to https://app.komodor.com to generate your command !
