# SetLocationEnhancer



SetLocationEnhancer is a PowerShell module that enhances the `Set-Location` cmdlet by allowing you to add, remove, and suspend custom behaviors that execute whenever you change directories. Behaviors are executed in reverse order of addition, meaning the most recently added behavior runs first.

## Features

- **Add Custom Behaviors**: Easily add new behaviors to execute when changing directories.
- **Remove Behaviors**: Remove specific behaviors by name.
- **List Behaviors**: View all registered behaviors and their names.

## Installation

You can install SetLocationEnhancer from the PowerShell Gallery:

```powershell
Install-Module -Name SetLocationEnhancer
```

## Usage

### Adding a Behavior

To add a new behavior, use the `Add-SetLocationBehavior` function:

```powershell
Add-SetLocationBehavior -Name 'LoadEnv' -Behavior {
	param($Path)
	$envFile = Join-Path -Path ($Path) -ChildPath ".env"

	if (-Not (Test-Path $envFile)) {
		Write-Error "The specified .env file does not exist: $envFile"
		return
	}

	Get-Content -Path $envFile | ForEach-Object {
		# Trim whitespace and skip empty lines or comments
		$_ = $_.Trim()
		if (-Not [string]::IsNullOrWhiteSpace($_) -and -Not $_.StartsWith('#')) {
			# Split the line into key and value
			$parts = $_ -split '=', 2
			if ($parts.Count -eq 2) {
				$key = $parts[0].Trim()
				$value = $parts[1].Trim()
				# Set the environment variable
				[System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
			}
		}
	}

	Write-Host "Environment variables loaded from $envFile"
}
```

### Managing Behaviors

List all behaviors:

```powershell
Get-SetLocationBehaviors
```

Remove a behavior:

```powershell
Remove-SetLocationBehavior -Name "MyBehavior"
```

Enable or disable behaviors:

```powershell
Disable-SetLocationBehavior -Name "MyBehavior"
Enable-SetLocationBehavior -Name "MyBehavior"
```

Change behavior order (position starts at 0):

```powershell
Move-SetLocationBehavior -Name "MyBehavior" -Position 2
```

Reset to default behaviors:

```powershell
Reset-SetLocationBehaviors
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

Your Name

## Acknowledgments

- Thanks to the PowerShell community for their support and contributions.
