# Change to array of hashtables
$SetLocationBehaviors = @()

# Function to add new behavior with a name
function Add-SetLocationBehavior {
    param(
        [string]$Name,
        [ScriptBlock]$Behavior
    )
    $script:SetLocationBehaviors += @{
        name = $Name
        behavior = $Behavior
        active = $true
    }
}

# Function to reset the behaviors
function Reset-SetLocationBehaviors {
    $script:SetLocationBehaviors = @()
}

# Function to remove a behavior by name
function Remove-SetLocationBehavior {
    param(
        [string]$Name
    )
    $script:SetLocationBehaviors = $script:SetLocationBehaviors | Where-Object { $_.name -ne $Name }
}

# Function to list all behaviors
function Get-SetLocationBehaviors {
    $script:SetLocationBehaviors
}

# Override Set-Location to call each function in the behaviors
function Set-Location {
    param(
        [string]$Path
    )
    # Get active behaviors and reverse them so Original runs last
    $activeBehaviors = $script:SetLocationBehaviors | Where-Object { $_.active } | ForEach-Object { $_.behavior }
    $behaviorArray = @($activeBehaviors)
    [array]::Reverse($behaviorArray)
    foreach ($func in $behaviorArray) {
        & $func $Path
    }
	# Run the original Set-Location
	Microsoft.PowerShell.Management\Set-Location -Path $Path
}

# Function to disable a behavior by name
function Disable-SetLocationBehavior {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $behavior = $script:SetLocationBehaviors | Where-Object { $_.name -eq $Name }
    if ($behavior) {
        $behavior.active = $false
    } else {
        Write-Warning "Behavior '$Name' not found"
    }
}

# Function to enable a behavior by name
function Enable-SetLocationBehavior {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $behavior = $script:SetLocationBehaviors | Where-Object { $_.name -eq $Name }
    if ($behavior) {
        $behavior.active = $true
    } else {
        Write-Warning "Behavior '$Name' not found"
    }
}

# Cleanup when module is removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Restore original Set-Location behavior
    Remove-Item -Path 'Function:\Set-Location' -ErrorAction SilentlyContinue
}
