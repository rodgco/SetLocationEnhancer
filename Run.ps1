# Parse command-line arguments
param (
	[string]$Task = "Test"
)

function Publish {
    if (-not $env:NUGET_API_KEY) {
        Write-Host "NuGetApiKey is not set"
        return
    }
    Publish-Module -Path "." -NuGetApiKey $env:NUGET_API_KEY
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