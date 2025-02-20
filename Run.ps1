# Parse command-line arguments
param (
	[string]$Task = "Test"
)

function Publish {
    if (-not $env:NuGetApiKey) {
        Write-Host "NuGetApiKey is not set"
        return
    }
    Publish-Module -Path "." -NuGetApiKey $env:NuGetApiKey
}

function Test {
    Invoke-Pester -Path .\Tests
}

# Execute the specified task
switch ($Task) {
    "Publish" { Publish }
    "Test" { Test }
    default { Write-Host "Unknown task: $Task" }
}