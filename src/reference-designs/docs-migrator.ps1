[CmdletBinding()]
param (
    [Parameter(Position=1)]
    [string]
    $Directory="."
)

$DirList = Get-ChildItem -Path "$($Directory)/*" -Include *.md -Exclude index*

$images = "images"
$index = "index.md"
$section = "refarchs"
$tmp = $env:TEMP
$resource = "resources"

if ( -Not (Test-Path "$($tmp)/$($section)")) {
    New-Item -Path "$($tmp)" -ItemType Directory -Name $section | out-null
}

foreach($file in $DirList) {
    $contents = Get-Content $file
    $bundle =  ($file.name).substring(0, ($file.name).length -3)

    if ( -Not (Test-Path "$($tmp)/$($section)/$($bundle)")) {
        New-Item -Path "$($tmp)/$($section)" -ItemType Directory -Name $bundle | out-null
    }
    
    if ( -Not (Test-Path "$($tmp)/$($section)/$($bundle)/$($images)")) {
        New-Item -Path "$($tmp)/$($section)/$($bundle)" -ItemType Directory -Name $images | out-null
    }

    foreach($line in $contents) {
        if ($line -match '[^!]\[[\w\s\d]+\]\(([./]+[\w\d./?=-]+)\)') {
            if ( -Not (Test-Path "$($tmp)/$($section)/$($bundle)/$($resource)")) {
                New-Item -Path "$($tmp)/$($section)/$($bundle)" -ItemType Directory -Name $resource | out-null
            }
            # $warn += @("Possible relative link issue ($($file.name)): $($Matches[1])")
        }

        if ($line -match '[^!]\[[\w\s\d]+\]\(([./]*deployment-guides\/[\w\d./?=-]*([\w\d.?=-]+\.[a-z]+))\)' -or $line -match '[^!]\[[\w\s\d]+\]\(([./]*resources([\w\d/?=-]*\/([\w\d?=-]+\.[a-z]+)))\)') {
            Copy-Item -Path "$($Directory)/$($Matches[1])" -Destination "$($tmp)/$($section)/$($bundle)/$($resource)/$($Matches[3])" -Force
        }

        if ($line -match '(!\[[\w\s\d]+\])\(([\w\d./?=#-]*img\/[\w\d./?=#-]+\/([\w\d./?=#-]+\.[a-z]{3}))\)') {
            Copy-Item -Path "$($Directory)/$($Matches[2])" -Destination "$($tmp)/$($section)/$($bundle)/$($images)/$($Matches[3])" -Force
        }
    }
    $prepend = @"
    ---
    date: '2023-05-16'
    description: This document lays out a reference architecture related for VMware Tanzu for Kubernetes Operations when deployed on a vSphere environment backed by VMware NSX-T and offers a high-level overview of the different components.
    linkTitle: TKO on vSphere NSX
    tags:
    - TKO
    - TKG
    - vSphere
    - NSX
    title: $($bundle)
    ---
    
"@
    $contents = $prepend + $contents
    $contents = $contents -replace '(!\[[\w\s\d]+\])\([\w\d./?=#-]*img\/[\w\d./?=#-]+\/([\w\d./?=#-]+\.[a-z]{3})\)','$1(images/$2)'
    $contents = $contents -replace '[^!]\[[\w\s\d]+\]\(([./]*deployment-guides\/([\w\d./?=-]+\.[a-z]+))\)','$1($resources/$2)'
    $contents = $contents -replace '[^!]\[[\w\s\d]+\]\(([./]*resources\/([\w\d./?=-]+\.[a-z]+))\)','$1($resources/$2)'

    Set-Content -Path "$($tmp)/$($section)/$($bundle)/$($index)" -Force -Value $contents
    $info += "File $($_.name) migrated to $($tmp)/$($section)/$($bundle)"
}

$info | Write-Information
$warn | Write-Warning