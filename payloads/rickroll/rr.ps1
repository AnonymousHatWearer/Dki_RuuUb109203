# --- 1. Hide this PowerShell window ---
$sig = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
Add-Type -Name Win -Member $sig -Namespace Native
[Native.Win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess()).MainWindowHandle, 0)

# --- 2. Wait until someone moves the mouse ---
function Wait-ForTarget {
    Add-Type -AssemblyName System.Windows.Forms
    $startX = [System.Windows.Forms.Cursor]::Position.X
    $shell  = New-Object -ComObject WScript.Shell
    while ($true) {
        if ([System.Windows.Forms.Cursor]::Position.X -ne $startX) { break }
        $shell.SendKeys('{CAPSLOCK}')      # keep-alive; optional
        Start-Sleep -Seconds 3
    }
}

# --- 3. Fullscreen video player (WPF) ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.ComponentModel

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Player" WindowState="Maximized" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen">
    <MediaElement Stretch="Fill" Name="VideoPlayer" LoadedBehavior="Manual" UnloadedBehavior="Stop" />
</Window>
"@

$reader      = New-Object System.Xml.XmlNodeReader $XAML
$Window      = [Windows.Markup.XamlReader]::Load($reader)
$VideoPlayer = $Window.FindName("VideoPlayer")

$VideoPlayer.Volume = 100
$VideoPlayer.Source = [uri]"$env:TMP\rr\rr.mp4"   # matches the Expand-Archive destination

Wait-ForTarget
$VideoPlayer.Play()
$Window.ShowDialog() | Out-Null

# --- 4. Cleanup (OPTIONAL — leave commented while testing on your own machine) ---
if ([System.Windows.Forms.Control]::IsKeyLocked('CapsLock')) {
    (New-Object -ComObject WScript.Shell).SendKeys('{CapsLock}')
}
# Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
# reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /va /f
# Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
# Clear-RecycleBin -Force -ErrorAction SilentlyContinue
