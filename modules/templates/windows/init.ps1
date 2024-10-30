<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install chocolateygui vscode googlechrome git Firefox github-desktop vault  softerraldapbrowser ldapadmin ldapexplorer beekeeper-studio -y

# Get the latest Boundary Desktop Version
$url = "https://api.releases.hashicorp.com/v1/releases/boundary-desktop/latest"
$response = Invoke-RestMethod -Uri $url
$build = $response.builds | Where-Object { $_.arch -eq "amd64" -and $_.os -eq "windows" }
$build.url

# Define the destination path for the downloaded file
$destinationPath = Join-Path -Path $env:TEMP -ChildPath "boundary-desktop.zip"

# Download the file
Invoke-WebRequest -Uri $build.url -OutFile $destinationPath

# Define the folder path where you want to extract the contents
$newFolderPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Boundary_desktop"

# Create the new folder if it does not exist
if (-Not (Test-Path -Path $newFolderPath)) {
    New-Item -ItemType Directory -Path $newFolderPath
}

# Unzip the file to the new folder path
Expand-Archive -Path $destinationPath -DestinationPath $newFolderPath

# Create a shortcut to Boundary.exe on the Desktop
$shortcutPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "Boundary Desktop.lnk"
$targetPath = Join-Path -Path $newFolderPath -ChildPath "Boundary.exe"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath
$Shortcut.Save()

# Remove the downloaded zip file if no longer needed
Remove-Item -Path $destinationPath

# add the a

# Confirm completion
Write-Output "Boundary Desktop downloaded and extracted to Desktop successfully."

git clone https://github.com/GuyBarros/ad-lab C:\ad-lab

</powershell>