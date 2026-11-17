# Real-path sweep (2026-11-17): runs the game in a real window with tools/dev/real_path_probe.gd and drives it with OS-level input.
#   powershell -File tools/dev/real_path.ps1 -Out DIR [-Size max|WxH] [-Mode route|flow] [-Route main] [-Resize] [-Timeout 1500]
# route: the probe asks for clicks, keys, wheel, middle drags and window changes (cmd_N.txt) and this script does them with user32.
# flow:  the game's own --flow-test walks every route; with -Resize the window is toggled (maximize, 1517x843, a corner drag) every
#        ~25 s while it runs. Results: DIR/probe.log (CHECK lines) and DIR/*.png. Never touches other Godot processes.
param([string]$Out, [string]$Size = "max", [string]$Mode = "route", [string]$Route = "main", [switch]$Resize, [int]$Timeout = 1500, [string]$Extra = "",
      [string]$Godot = "C:\BURIN_NITRO\Godot\Godot_v4.7.2-stable_win64.exe", [string]$Path = (Resolve-Path "$PSScriptRoot\..\..").Path)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class RP {
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
 [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags, int dx, int dy, int data, UIntPtr extra);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
 public struct RECT { public int L,T,R,B; } public struct POINT { public int X,Y; } }
"@
[RP]::SetProcessDPIAware() | Out-Null
New-Item -ItemType Directory -Force $Out | Out-Null
$chan = Join-Path $Out "chan"
New-Item -ItemType Directory -Force $chan | Out-Null
Get-ChildItem $chan -File | Remove-Item -Force
function Log($s) { $l = "[{0:HH:mm:ss}] {1}" -f (Get-Date), $s; Add-Content -Path (Join-Path $Out "harness.log") -Value $l; Write-Output $l }
function Client($h) { $r = New-Object RP+RECT; [RP]::GetClientRect($h, [ref]$r) | Out-Null; $pt = New-Object RP+POINT; [RP]::ClientToScreen($h, [ref]$pt) | Out-Null; return @($pt.X, $pt.Y, $r.R, $r.B) }
function Key($vk, $ms) { $sc = [byte][RP]::MapVirtualKey($vk, 0); [RP]::keybd_event($vk, $sc, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds $ms; [RP]::keybd_event($vk, $sc, 2, [UIntPtr]::Zero) }
function At($h, $x, $y) { $c = Client $h; [RP]::SetCursorPos($c[0] + $x, $c[1] + $y) | Out-Null }
function SetSize($h, $s) {
  if ($s -eq "none") { return }
  if ($s -eq "max") { [RP]::ShowWindow($h, 3) | Out-Null }
  else { [RP]::ShowWindow($h, 9) | Out-Null; Start-Sleep -Milliseconds 300; $wh = $s.Split("x"); [RP]::SetWindowPos($h, [IntPtr]::Zero, 30, 30, [int]$wh[0], [int]$wh[1], 0x0044) | Out-Null }
}
function DragCorner($h, $dx, $dy) {
  $r = New-Object RP+RECT; [RP]::GetWindowRect($h, [ref]$r) | Out-Null
  $x = $r.R - 9; $y = $r.B - 9  # inside the (invisible) sizing border of the bottom-right corner
  [RP]::SetCursorPos($x, $y) | Out-Null; Start-Sleep -Milliseconds 200
  [RP]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
  for ($i = 1; $i -le 20; $i++) { [RP]::SetCursorPos($x + [int]($dx * $i / 20), $y + [int]($dy * $i / 20)) | Out-Null; Start-Sleep -Milliseconds 25 }
  [RP]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
}

$args2 = @('--path', $Path, '-s', 'res://tools/dev/real_path_probe.gd', '--', "--sweep-out=$Out")
if ($Extra -ne "") { $args2 += $Extra.Split(" ") }
if ($Mode -eq "flow") { $args2 += '--flow-test' } else { $args2 += @('--dev', "--sweep-route=$Route", "--sweep-chan=$chan") }
$p = Start-Process -FilePath $Godot -ArgumentList $args2 -PassThru -RedirectStandardOutput (Join-Path $Out "stdout.log") -RedirectStandardError (Join-Path $Out "stderr.log")
for ($i = 0; $i -lt 120 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 250; $p.Refresh() }
$h = $p.MainWindowHandle
Log "pid=$($p.Id) hwnd=$h mode=$Mode size=$Size"
SetSize $h $Size
Start-Sleep -Milliseconds 800
$c = Client $h; Log ("client {0}x{1}" -f $c[2], $c[3])
if ($Mode -eq "flow") { $sc = Client $h; [RP]::SetCursorPos($sc[0] + $sc[2] - 2, $sc[1] + $sc[3] + 30) | Out-Null }  # park the cursor off the game
$start = Get-Date; $n = 1; $next = (Get-Date).AddSeconds(25); $step = 0
while (-not $p.HasExited) {
  if (((Get-Date) - $start).TotalSeconds -gt $Timeout) { Log "TIMEOUT: stopping pid $($p.Id)"; Stop-Process -Id $p.Id -Force; break }
  if ($Mode -eq "flow") {
    if ($Resize -and (Get-Date) -gt $next) {
      $plan = @("1517x843", "drag", "max", "1392x711", "max")
      $what = $plan[$step % $plan.Count]; $step++
      if ($what -eq "drag") { DragCorner $h 120 50 } else { SetSize $h $what }
      Start-Sleep -Milliseconds 400; $c = Client $h; Log ("resize {0} -> client {1}x{2}" -f $what, $c[2], $c[3])
      $sc = Client $h; [RP]::SetCursorPos($sc[0] + $sc[2] - 2, $sc[1] + $sc[3] + 30) | Out-Null
      $next = (Get-Date).AddSeconds(25)
    }
    Start-Sleep -Milliseconds 200; continue
  }
  $f = Join-Path $chan "cmd_$n.txt"
  if (-not (Test-Path $f)) { Start-Sleep -Milliseconds 30; continue }
  $line = (Get-Content $f -Raw).Trim(); $a = $line.Split(" ")
  [RP]::SetForegroundWindow($h) | Out-Null
  switch ($a[0]) {
    "click" { At $h ([int]$a[1]) ([int]$a[2]); Start-Sleep -Milliseconds 120; [RP]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60; [RP]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero) }
    "move" { At $h ([int]$a[1] - 6) ([int]$a[2] - 6); Start-Sleep -Milliseconds 60; At $h ([int]$a[1]) ([int]$a[2]) }
    "key" { Key ([int]$a[1]) ([int]$a[2]) }
    "wheel" { At $h ([int]$a[2]) ([int]$a[3]); $nn = [int]$a[1]; $d = if ($nn -gt 0) { 120 } else { -120 }
      for ($i = 0; $i -lt [math]::Abs($nn); $i++) { [RP]::mouse_event(0x0800, 0, 0, $d, [UIntPtr]::Zero); Start-Sleep -Milliseconds 120 } }
    "mdrag" { $x = [int]$a[1]; $y = [int]$a[2]; $dx = [int]$a[3]; $dy = [int]$a[4]; At $h $x $y; [RP]::mouse_event(0x0020, 0, 0, 0, [UIntPtr]::Zero)
      for ($i = 1; $i -le 30; $i++) { At $h ($x + [int]($dx * $i / 30)) ($y + [int]($dy * $i / 30)); Start-Sleep -Milliseconds 16 }
      [RP]::mouse_event(0x0040, 0, 0, 0, [UIntPtr]::Zero) }
    "max" { SetSize $h "max" }
    "start" { if ($Size -eq "none" -and $Extra -match "--window=(\d+)x(\d+)") { [RP]::ShowWindow($h, 9) | Out-Null; Start-Sleep -Milliseconds 300; [RP]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, [int]$Matches[1], [int]$Matches[2], 0x0044) | Out-Null } else { SetSize $h $Size } }
    "restore" { [RP]::ShowWindow($h, 9) | Out-Null }
    "size" { SetSize $h ("{0}x{1}" -f $a[1], $a[2]) }
    "dragcorner" { DragCorner $h ([int]$a[1]) ([int]$a[2]) }
    "done" { }
  }
  Start-Sleep -Milliseconds 250
  $c = Client $h; Log ("{0} -> client {1}x{2}" -f $line, $c[2], $c[3])
  Set-Content -Path (Join-Path $chan "ack_$n.txt") -Value "ok"
  $n++
}
Log "exit code $($p.ExitCode)"
