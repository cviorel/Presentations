<#
.SYNOPSIS
    Cleans up Docker containers and images, and removes specific directories and files.

.DESCRIPTION
    This script is used to clean up Docker containers and images, as well as remove specific directories and files.
    It performs the following actions:
    1. Kills all running Docker containers.
    2. Deletes untagged Docker images.
    3. Deletes stopped Docker containers.
    4. Removes stopped Docker containers.
    5. Stops all Docker containers.
    6. Deletes dangling Docker images.
    7. Removes specific directories and files.

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    Start-Clean.ps1
    Cleans up Docker containers and images, and removes specific directories and files.

.NOTES
    Author: Viorel Ciucu
#>

Write-Output ":: Kill all"
docker kill $(docker ps -q)

Write-Output ":: Deleting untagged images"
docker rmi $(docker images -q -f dangling=true)

Write-Output ":: Deleting stopped containers"
docker rm $(docker ps -a -q)

Write-Output ":: Remove stopped containers"
docker rm $(docker ps -a -q)

Write-Output ":: Stop all containers"
docker stop $(docker ps -a -q)

docker rmi $(docker images -f "dangling=true" -q)

Remove-Item .\.devcontainer\.sql2017\ -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\.devcontainer\.sql2019\ -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\.devcontainer\.sql2022\ -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\.devcontainer\.shared\ -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\dbachecks\ -Recurse -Force -ErrorAction SilentlyContinue

Push-Location -Path .devcontainer

Write-Output ":: Build"
docker build --target final .

Pop-Location

# Cleanup
docker rmi $(docker images -f "dangling=true" -q)
