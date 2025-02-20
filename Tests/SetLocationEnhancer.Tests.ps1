# Get the module path relative to the test file
$ModulePath = (Resolve-Path "$PSScriptRoot\..\SetLocationEnhancer.psm1").Path

# Remove the module if it's already imported to ensure a clean state
if (Get-Module SetLocationEnhancer) {
    Remove-Module SetLocationEnhancer
}

# Import the module
Import-Module $ModulePath -Force

# Dot-source the module script
# . "$PSScriptRoot\..\SetLocationEnhancer.psm1"

Describe "SetLocationEnhancer Module" {

	$originalLocation = Get-Location
	$originalBehaviors = Get-SetLocationBehaviors

	BeforeEach {
		Reset-SetLocationBehaviors
	}

	AfterAll {
		Set-Location -Path $originalLocation
		Reset-SetLocationBehaviors
		foreach ($behavior in $originalBehaviors) {
			Add-SetLocationBehavior -Name $behavior.name -Behavior $behavior.behavior
		}
	}

    It "should initialize with only the original behavior" {
        Get-SetLocationBehaviors | Should -HaveCount 0
    }

    It "should add a new behavior" {
        Add-SetLocationBehavior -Name 'TestBehavior' -Behavior { param($Path) Write-Host "Test" }
        Get-SetLocationBehaviors | Select-Object -Last 1 -ExpandProperty name | Should -Be 'TestBehavior'
    }

    It "should list all behaviors" {
        Add-SetLocationBehavior -Name 'AnotherBehavior' -Behavior { param($Path) Write-Host "Another Test" }
        $behaviors = Get-SetLocationBehaviors
        $behaviors | Select-Object -First 1 -ExpandProperty name | Should -Be 'AnotherBehavior'
    }

    It "should remove a behavior" {
        Add-SetLocationBehavior -Name 'AnotherBehavior' -Behavior { param($Path) Write-Host "Another Test" }
        Remove-SetLocationBehavior -Name 'AnotherBehavior'
        Get-SetLocationBehaviors | Should -Not -Contain 'AnotherBehavior'
    }

    It "should trigger a behavior on location change" {
        Add-SetLocationBehavior -Name 'TestBehavior' -Behavior { param($Path) return "$Path" }
        $Result = Set-Location -Path 'TestDrive:'
        $Result | Should -Be 'TestDrive:'
    }

    It "should trigger multiple behaviors on location change in reverse order" {
        Add-SetLocationBehavior -Name 'TestBehavior1' -Behavior { param($Path) return "$Path #1" }
        Add-SetLocationBehavior -Name 'TestBehavior2' -Behavior { param($Path) return "$Path #2" }
        Add-SetLocationBehavior -Name 'TestBehavior3' -Behavior { param($Path) return "$Path #3" }
        $Result = Set-Location -Path 'TestDrive:'
        $Result | Should -Be @('TestDrive: #3', 'TestDrive: #2', 'TestDrive: #1') -Because "the behaviors should be executed in reverse order"
    }

    It "should disable and enable a behavior" {
        Add-SetLocationBehavior -Name 'TestBehavior1' -Behavior { param($Path) return "$Path #1" }
        Add-SetLocationBehavior -Name 'TestBehavior2' -Behavior { param($Path) return "$Path #2" }
        Add-SetLocationBehavior -Name 'TestBehavior3' -Behavior { param($Path) return "$Path #3" }
        Disable-SetLocationBehavior -Name 'TestBehavior1'
        $Result = Set-Location -Path 'TestDrive:'
        $Result | Should -Be @('TestDrive: #3', 'TestDrive: #2') -Because "the disabled behavior should not be executed"
        Enable-SetLocationBehavior -Name 'TestBehavior1'
        $Result = Set-Location -Path 'TestDrive:'
        $Result | Should -Be @('TestDrive: #3', 'TestDrive: #2', 'TestDrive: #1') -Because "the enabled behavior should be executed"
    }
}