<#
    .SYNOPSIS
    This script scans owner's repositories and downloads their template files.
    .DESCRIPTION
    All owner's repositories template files are downloaded to specified directory.
    .PARAMETER owner
    Owner of scanned repositories
    .PARAMETER pathToTemplate
    Path to template file in repository
    .PARAMETER outDir
    Directory to which all template files are saved
    .PARAMETER username
    username for GitHub API calls authentication
    .PARAMETER authToken
    token for GitHub API calls authentication
    .NOTES
    Written by Krzysztof Zajączkowski
    @krzysztofzajaczkowski
    #>
    param(
        [parameter(Mandatory = $true)]
        [string]$Owner,

        [parameter(Mandatory = $true)]
        [string]$PathToTemplate,

        [parameter(Mandatory = $true)]
        [string]$OutDir,

        [parameter(Mandatory = $true)]
        [string]$Username,

        [parameter(Mandatory = $true)]
        [string]$AuthToken
    )

    function Get-BasicAuthCreds {
        param([string]$Username,[string]$AuthToken)
        $AuthString = "{0}:{1}" -f $Username,$AuthToken
        $AuthBytes  = [System.Text.Encoding]::Ascii.GetBytes($AuthString)
        return [Convert]::ToBase64String($AuthBytes)
    }

    If(!(test-path -PathType container $OutDir))
    {
        New-Item -ItemType Directory -Path $OutDir
    }

    $headers = Get-BasicAuthCreds -Username $Username -AuthToken $AuthToken

    # get all user's repositories
    # https://api.github.com/users/{Owner}/repos
    $listReposUri = "https://api.github.com/users/$($Owner)/repos"
    $names = Invoke-RestMethod -Uri $listReposUri -Headers @{"Authorization"="Basic $headers"} | ForEach-Object { return $_.full_name }

    # for each name
    #   call https://api.github.com/repos/{full_name}/contents/{PathToTemplate}
    #   select name, download_url
    #   call download_url and and save to {OutDir}/{name}
    foreach ($name in $names) {
        $fileDetailsUri = "https://api.github.com/repos/$($name)/contents/$($PathToTemplate)"
        $response = Invoke-WebRequest -Uri $fileDetailsUri -Headers @{"Authorization"="Basic $headers"} -SkipHttpErrorCheck

        if ($response.StatusCode -eq 200) {
            $fileDetails = ConvertFrom-Json $response.Content | Select-Object name, download_url
            $fileName = $fileDetails | Select-Object -ExpandProperty name
            $fileDownloadUri = $fileDetails | Select-Object -ExpandProperty download_url

            Invoke-RestMethod -Uri $fileDownloadUri -Headers @{"Authorization"="Basic $headers"} -OutFile "$($OutDir)/$($fileName)"
        }
    }