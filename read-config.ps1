param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,
    [Parameter(Mandatory = $true)]
    [string]$OutPath
)

$ErrorActionPreference = "Stop"

$raw = Get-Content -Raw -Path $ConfigPath

function Get-LooseValue {
    param(
        [string]$Text,
        [string]$Key
    )
    $m = [regex]::Match($Text, '"' + [regex]::Escape($Key) + '"\s*:\s*"(?<v>(?:\\.|[^"\\])*)"')
    if (-not $m.Success) { return "" }
    $v = $m.Groups["v"].Value
    $v = $v -replace '\\"', '"'
    $v = $v -replace '\\\\', '\'
    return $v
}

$parsed = $null
try {
    $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    $parsed = $null
}

$vars = [ordered]@{
    PROJECT_NAME = ""
    REPO_URL     = ""
    BRANCH       = ""
    SSH_HOST     = ""
    SSH_PORT     = ""
    SSH_USER     = ""
    SSH_PASS     = ""
    SSH_KEY_PATH = ""
    REMOTE_PATH  = ""
}

$map = [ordered]@{
    PROJECT_NAME = "name"
    REPO_URL     = "repository_url"
    BRANCH       = "branch"
    SSH_HOST     = "ssh_host"
    SSH_PORT     = "ssh_port"
    SSH_USER     = "ssh_user"
    SSH_PASS     = "ssh_password"
    SSH_KEY_PATH = "ssh_key_path"
    REMOTE_PATH  = "remote_path"
}

if ($null -ne $parsed) {
    $vars.PROJECT_NAME = $parsed.project.name
    $vars.REPO_URL     = $parsed.github.repository_url
    $vars.BRANCH       = $parsed.github.branch
    $vars.SSH_HOST     = $parsed.hosting.ssh_host
    $vars.SSH_PORT     = $parsed.hosting.ssh_port
    $vars.SSH_USER     = $parsed.hosting.ssh_user
    $vars.SSH_PASS     = $parsed.hosting.ssh_password
    $vars.SSH_KEY_PATH = $parsed.hosting.ssh_key_path
    $vars.REMOTE_PATH  = $parsed.hosting.remote_path
} else {
    foreach ($k in $vars.Keys) {
        $vars[$k] = Get-LooseValue -Text $raw -Key $map[$k]
    }
}

$lines = foreach ($item in $vars.GetEnumerator()) {
    $value = [string]$item.Value
    $value = $value.Replace('"', '\"')
    "set `"$($item.Key)=$value`""
}

Set-Content -Path $OutPath -Value $lines -Encoding Ascii
