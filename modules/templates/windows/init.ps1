<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install chocolateygui vscode googlechrome git Firefox github-desktop vault  softerraldapbrowser ldapadmin ldapexplorer -y

git clone https://github.com/GuyBarros/ad-lab C:\ad-lab

</powershell>