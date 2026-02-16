param(
    [Parameter(Mandatory = $true)]
    [string]$OutPath
)

$yaml = @'
name: Deploy to Hosting
on:
  push:
    branches: [ "main", "master" ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      - name: Copy files to server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          port: ${{ secrets.SSH_PORT }}
          key: ${{ secrets.SSH_KEY }}
          source: "."
          target: ${{ secrets.REMOTE_PATH }}
          strip_components: 0
          overwrite: true
'@

$dir = Split-Path -Parent $OutPath
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

Set-Content -Path $OutPath -Value $yaml -Encoding UTF8
