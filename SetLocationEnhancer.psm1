# Change to array of hashtables
$SetLocationBehaviors = @(
    @{
        name = 'Original'
        behavior = { param($Path) Microsoft.PowerShell.Management\Set-Location -Path $Path }
        active = $true
    }
)

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
    $script:SetLocationBehaviors = @(
        @{
            name = 'Original'
            behavior = { param($Path) Microsoft.PowerShell.Management\Set-Location -Path $Path }
            active = $true
        }
    )
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
    $script:SetLocationBehaviors | Select-Object -ExpandProperty name
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

# Function to move a behavior to a new position in the array
function Move-SetLocationBehavior {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [int]$Position
    )
    
    # Find the behavior
    $behaviorIndex = 0..($script:SetLocationBehaviors.Count - 1) | Where-Object { 
        $script:SetLocationBehaviors[$_].name -eq $Name 
    }

    if ($null -eq $behaviorIndex) {
        Write-Warning "Behavior '$Name' not found"
        return
    }

    # Validate position
    if ($Position -lt 0 -or $Position -ge $script:SetLocationBehaviors.Count) {
        Write-Warning "Position must be between 0 and $($script:SetLocationBehaviors.Count - 1)"
        return
    }

    # Store the behavior to move
    $behaviorToMove = $script:SetLocationBehaviors[$behaviorIndex]
    
    # Remove from current position
    $script:SetLocationBehaviors = @(
        $script:SetLocationBehaviors[0..($behaviorIndex-1)]
        $script:SetLocationBehaviors[($behaviorIndex+1)..($script:SetLocationBehaviors.Count-1)]
    ) | Where-Object { $null -ne $_ }

    # Insert at new position
    $script:SetLocationBehaviors = @(
        $script:SetLocationBehaviors[0..($Position-1)]
        $behaviorToMove
        $script:SetLocationBehaviors[$Position..($script:SetLocationBehaviors.Count-1)]
    ) | Where-Object { $null -ne $_ }
}

# Cleanup when module is removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Restore original Set-Location behavior
    Remove-Item -Path 'Function:\Set-Location' -ErrorAction SilentlyContinue
}
