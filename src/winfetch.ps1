#!/usr/bin/env pwsh
#requires -version 6

# WinFetch - neofetch ported to PowerShell for windows 10 systems.
#
# The MIT License (MIT)
# Copyright (c) 2019 Kied Llaentenn
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Summary: Winfetch is a command-line system information utility for Windows written in PowerShell. 
# Usage: ./winfetch [options]
# Help: Run winfetch without arguments to view core functionality.
# 
# OPTIONS
#          -genconf   Download a custom configuration. Internet connection needed.
#     -image [path]   Display a pixelated image instead of the usual logo. Imagemagick required.
#          -noimage   Do not display any image or logo; display information only.
#             -help   Display this help message.
#

param (
    [switch]$genconf,
    [string]$image,
    [switch]$noimage,
    [switch]$help
)

$version = "0.1.0"
$e = [char]0x1B

$DEG = [char]0x00B0

[array]$logo = @("${e}[1;34m                    ....,,:;+ccllll${e}[0m",
"${e}[1;34m      ...,,+:;  cllllllllllllllllll${e}[0m",
"${e}[1;34m,cclllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34m                                   ${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34m``'ccllllllllll  lllllllllllllllllll${e}[0m",
"${e}[1;34m      ``' \\*::  :ccllllllllllllllll${e}[0m",
"${e}[1;34m                       ````````''*::cll${e}[0m",
"${e}[1;34m                                 ````${e}[0m")

$color_char = "   "
$color_bar = "${e}[0;40m${color_char}${e}[0;41m${color_char}${e}[0;42m${color_char}${e}[0;43m${color_char}${e}[0;44m${color_char}${e}[0;45m${color_char}${e}[0;46m${color_char}${e}[0;47m${color_char}${e}[0m"

$configdir = $env:XDG_CONFIG_HOME, "$env:USERPROFILE\.config" | Select-Object -First 1
$configfolder = "${configdir}/winfetch/"
$config = "${configfolder}config.ps1"

$defaultconfig = "https://raw.githubusercontent.com/lptstr/winfetch/master/lib/config.ps1"

# ensure configuration directory exists
if (!(test-path $configfolder)) {
    mkdir -p $configfolder > $null 
}

# ===== DISPLAY HELP =====
function helptitle($text) {
    $text | Select-String '(?m)^# Helptitle: ([^\n]*)$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function usage($text) {
    $text | Select-String '(?m)^# Usage: ([^\n]*)$' | ForEach-Object { "Usage: " + $_.matches[0].groups[1].value }
}

function summary($text) {
    $text | Select-String '(?m)^# Summary: ([^\n]*)$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function help_msg($text) {
    $help_lines = $text | Select-String '(?ms)^# Help:(.(?!^[^#]))*' | ForEach-Object { $_.matches[0].value; }
    $help_lines -replace '(?ms)^#\s?(Help: )?', ''
}

if ($help) {
    try {
        $text = (Get-Content $MyInvocation.PSCommandPath -raw)
    } catch {
        $text = (Get-Content $PSCOMMANDPATH -raw)
    }
    $helpmsg = helptitle $text
    $helpmsg += usage $text
    $helpmsg += "`n"
    $helpmsg += summary $text
    $helpmsg += "`n"
    $helpmsg += help_msg $text
    $helpmsg
    exit 0
}

# ===== GENERATE CONFIGURATION =====
if ($genconf) {
    if (test-path $config) {
        write-host "error: configuration file already exists!" -f red
        exit 1
    } else {
        write-host "info: downloading default config to $config"
        $wb = new-object net.webclient
        $wb.DownloadFile($defaultconfig, $config)
        write-host "info: successfully completed download."
        exit 0
    }
}

# ===== VARIABLES =====
$title                = ""
$dashes               = ""
$img                  = ""
$os                   = ""
$hostname             = ""
$username             = ""
$computer             = ""
$uptime               = ""
$terminal             = ""
$cpu                  = ""
$gpu                  = ""
$memory               = ""
$disk                 = ""
$pwsh                 = ""
$pkgs                 = ""

# ===== CONFIGURATION =====
$show_title           = $true
$show_dashes          = $true
$show_os              = $true
$show_computer        = $true
$show_uptime          = $true
$show_terminal        = $true
$show_cpu             = $true
$show_gpu             = $true
$show_memory          = $true
$show_disk            = $true
$show_pwsh            = $true
$show_pkgs            = $true

if (test-path $config) {
    . "$config"
}

# ===== IMAGE =====
$img = @()
if (-not $image -and (-not $noimage)) {
    $img = $logo
} elseif (-not $noimage -and ($image)) {
    $magick = try { Get-Command magick -ea stop } catch { $null }
    if (-not $magick) {
        write-host "error: Imagemagick must be installed to print custom images." -f Red
        write-host "hint: if you have Scoop installed, try `scoop install imagemagick`." -f Yellow
        exit 1
    }

    $E = [char]0x1B
    $COLUMNS = 35
    $CURR_ROW = ""
    $CHAR = [text.encoding]::utf8.getstring((226,150,128)) # 226,150,136
    [string[]]$global:upper = @()
    [string[]]$global:lower = @()
    if ($image -eq "wallpaper") {
        $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    }
    if (-not (test-path $image)) {
        write-host "error: specified image or wallpaper does not exist. aborting." -f Red
        exit 1
    }
    [array]$pixels = (magick convert -thumbnail "${COLUMNS}x" -define txt:compliance=SVG $image txt:- ).Split("`n")
    foreach ($pixel in $pixels) {
        $coord = ((([regex]::match(
                      $pixel, 
                      "([0-9])+,([0-9])+:")).Value).TrimEnd(":")
                  ).Split(",")
        [int]$global:col = $coord[0]
        [int]$global:row = $coord[1]
        $rgba = ([regex]::match(
                    $pixel, 
                    "\(([0-9])+,([0-9])+,([0-9])+,([0-9])+\)"
                 )).Value

        $rgba = (($rgba.TrimStart("(")).TrimEnd(")")).Split(",")
        $r = $rgba[0]
        $g = $rgba[1]
        $b = $rgba[2]
        if (($row % 2) -eq 0) {
            $upper += "${r};${g};${b}"
        } else {
            $lower += "${r};${g};${b}"
        }
        if (($row%2) -eq 1 -and ($col -eq ($COLUMNS-1))) {
            $i = 0
            while ($i -lt $COLUMNS) {
                $CURR_ROW += "${E}[38;2;$($upper[$i]);48;2;$($lower[$i])m${CHAR}"
                $i++
            }
            $img += "${CURR_ROW}${E}[0m${E}[B${E}[0G"
            $CURR_ROW = ""
            $upper = @()
            $lower = @()
        }
    }
} else {
    $img = @()
}

# ===== OS =====
if ($show_os) {
    $os = (($PSVersionTable.OS).ToString()).TrimStart("Microsoft ")
} else {
    $os = "disabled"
}

# ===== HOSTNAME =====
$hostname = $env:computername

# ===== USERNAME =====
$username = [System.Environment]::UserName

# ===== TITLE =====
if ($show_title) {
    $title = "${e}[1;34m${username}${e}[0m@${e}[1;34m${hostname}${e}[0m"
} else {
    $title = "disabled"
}

# ===== DASHES =====
if ($show_dashes) {
    $shorttitle = "${username}@${hostname}"
    for ($i = 0; $i -lt $shorttitle.length; $i++) {
        $dashes += "-"
    }
} else {
    $dashes = "disabled"
}

# ===== COMPUTER =====
if ($show_computer) {
    $computer_data = Get-CimInstance -ClassName Win32_ComputerSystem
    $make = $computer_data.Manufacturer
    $model = $computer_data.Model
    $computer = "$make $model"
} else {
    $computer = "disabled"
}

# ===== UPTIME =====
if ($show_uptime) {
    $bootTime = Get-CimInstance -ClassName win32_operatingsystem | select -ExpandProperty lastbootuptime
    $uptime_data = (get-date) - $bootTime
    
    $raw_days = $uptime_data.Days
    $raw_hours = $uptime_data.Hours
    $raw_mins = $uptime_data.Minutes

    $days ="${raw_days} days "
    $hours ="${raw_hours} hours "
    $mins ="${raw_mins} minutes"
    
    # remove plural if needed
    if ($raw_days -lt 2) { $days ="${raw_days} day " }
    if ($raw_hours -lt 2) { $hours ="${raw_hours} hour " }
    if ($raw_mins -lt 2) { $mins ="${raw_mins} minute" }
    
    # hide empty fields
    if ($raw_days -eq 0) { $days = "" }
    if ($raw_hours -eq 0) { $hours = "" }
    if ($raw_mins -eq 0) { $mins = "" }
    
    $uptime = "${days}${hours}${mins}"
} else {
    $uptime = "disabled"
}

# ===== TERMINAL =====
# this section works by getting
# the parent processes of the 
# current powershell instance.
if ($show_terminal) {
    $cid = $pid
    $parid = (get-process -id $cid).Parent
    $notterm = new-object collections.generic.list[string]
    $notterm.Add("powershell")
    $notterm.Add("pwsh")
    $notterm.Add("winpty-agent")
    $notterm.Add("cmd")
    while ($true) {
        if ($notterm.Contains($parid.ProcessName)) {
            $cid = $parid.ID
            $parid = (get-process -id $cid).Parent
            continue
        } else {
            break
        }
    }
    $rawterm = $parid.ProcessName
    try {
        switch ($rawterm) {
            "explorer" { $terminal = "Windows Console" }
            "alacritty" {
                $alacritty_ver = ((alacritty --version).Split(" "))[1]
                $terminal = "Alacritty v${alacritty_ver}"
            }
            "hyper" {
                $hyper_ver = ((hyper --version).Split("`n")[0]).Split(" ")[-1]
                $terminal = "Hyper v${hyper_ver}"
            }
            default { $terminal = $rawterm }
        }
    } catch {
        $terminal = $rawterm
    }
} else {
    $terminal = "disabled"
}

# ===== CPU/GPU =====
if ($show_cpu) {
    $cpu_data = Get-CimInstance -ClassName Win32_Processor
    $cpu = $cpu_data.Name
} else {
    $cpu = "disabled"
}

if ($show_gpu) {
    $gpu_data = Get-CimInstance -ClassName Win32_VideoController
    $gpu = $gpu_data.Name
} else {
    $gpu = "disabled"
}

# ===== MEMORY =====
if ($show_memory) {
    $mem_data = Get-Ciminstance Win32_OperatingSystem
    $freemem = $mem_data.FreePhysicalMemory
    [int]$totalmem = ($mem_data.TotalVisibleMemorySize) / 1024
    [int]$usedmem = ($freemem - $totalmem) / 1024
    $memory = "${usedmem}MiB / ${totalmem}MiB"
} else {
    $memory = "disabled"
}

# ===== DISK USAGE =====
if ($show_disk) {
    $disk_data = Get-Ciminstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freespace = $disk_data.FreeSpace
    $disk_name = $disk_data.VolumeName
    [int]$totalspace = ($disk_data.Size) / 1074000000
    [int]$usedspace = ($freespace - $totalspace) / 1074000000
    $disk = "${usedspace}GiB / ${totalspace}GiB (${disk_name})"
} else {
    $disk = "disabled"
}

# ===== POWERSHELL VERSION =====
if ($show_pwsh) {
    $pwsh_data = ($PSVersionTable.PSVersion).ToString()
    $pwsh = "PowerShell v${pwsh_data}"
} else {
    $pwsh = "disabled"
}

# ===== PACKAGES =====
if ($show_pkgs) {
    $chocopkg, $scooppkg = 0

    # detect is Scoop or Choco is installed
    $scoop = try { Get-Command scoop -ea stop } catch { $null }
    $choco = try { Get-Command choco -ea stop } catch { $null }
    
    # count Chocolatey packages
    if ($choco) {
        $chocopkg += (((((clist -l | out-string).Split("`n"))[-2]).Split(" "))[0]) - 1
    }
    
    # count Scoop packages
    if ($scoop) {
        $scooppath = scoop which scoop
        $scoopdir = ((resolve-path "$(split-path $scooppath)\..\..\..\").Path).ToString()
        pushd
        set-location $scoopdir
        $scooppkg += ((get-childitem -directory).Count) - 1
        popd
    }
    
    if ($scoop) {
         $pkgs += "$scooppkg (scoop)"
    }
    if ($choco -and $scoop) {
        $pkgs += ", $chocopkg (choco)"
    } elseif ($choco -and (-not $scoop)) {
        $pkgs += "$chocopkg (choco)"
    } else {
    }
} else {
    $pkgs = "disabled"
}

# reset terminal sequences and display a newline
write-host "${e}[0m`n" -nonewline

# add system info into an array
$info = New-Object 'System.Collections.Generic.List[string[]]'
$info.Add(@("", "$title"))
$info.Add(@("", "$dashes"))
$info.Add(@("OS", "$os"))
$info.Add(@("Host", "$computer"))
$info.Add(@("Uptime", "$uptime"))
$info.Add(@("Packages", "$pkgs"))
$info.Add(@("PowerShell", "$pwsh"))
$info.Add(@("Terminal", "$terminal"))
$info.Add(@("CPU", "$cpu"))
$info.Add(@("GPU", "$gpu"))
$info.Add(@("Memory", "$memory"))
$info.Add(@("Disk", "$disk"))
$info.Add(@("", ""))
$info.Add(@("", "$color_bar"))

# write system information in a loop
$counter = 0
while ($counter -lt $info.Count) {
    # print items, only if not empty or disabled
    if (($info[$counter])[1] -ne "disabled") {
        # print line of logo
        if ($counter -le $img.Count) {
            if (-not $noimage) {
                write-host " " -nonewline
            }
            if ("" -ne $img[$counter]) {
                write-host "$($img[$counter])" -nonewline
            }
        } else {
            if (-not $noimage) {
                $imglen = $img[0].length
                if ($image) {
                    $imglen = 37
                }
                for ($i = 0; $i -le $imglen; $i++) {
                    write-host " " -nonewline
                }
            }
        }
        if ($image) {
            write-host "${e}[37G" -nonewline
        }
        # print item title 
        write-host "   ${e}[1;34m$(($info[$counter])[0])${e}[0m" -nonewline
        if ("" -eq $(($info[$counter])[0])) {
            write-host "$(($info[$counter])[1])`n" -nonewline
        } else {
            write-host ": $(($info[$counter])[1])`n" -nonewline
        }
    } else {
        if (($info[$counter])[1] -ne "disabled") {
            ""
        }
    }
    $counter++
}

# print the rest of the logo
if ($counter -lt $img.Count) {
    while ($counter -le $img.Count) {
        write-host " $($img[$counter])"
        $counter++
    }
}

write-host "" # a newline

# EOF - We're done!
