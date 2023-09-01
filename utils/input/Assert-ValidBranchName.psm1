Import-Module -Scope Local "$PSScriptRoot/../diagnostics/diagnostic-framework.psm1"

function Assert-ValidBranchName {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory, ValueFromPipeline = $true)][string[]]$branchName,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

	
	BEGIN {}
	PROCESS
	{
        foreach ($branch in $branchName) {
            git check-ref-format --branch "$branch" > $nil
            if ($global:LASTEXITCODE -ne 0) {
                Add-ErrorDiagnostic $diagnostics "Invalid branch name specified: '$branch'"
            }
        }
    }
    END {}
}

Export-ModuleMember -Function Assert-ValidBranchName
