. $PSScriptRoot/branch-types/service-line.ps1
. $PSScriptRoot/branch-types/feature.ps1
. $PSScriptRoot/branch-types/release-candidate.ps1
. $PSScriptRoot/branch-types/integration.ps1
. $PSScriptRoot/branch-types/infrastructure.ps1

$branchTypes = @{
    serviceLine = $branchTypeServiceLine
    feature = $branchTypeFeature
    rc = $branchTypeReleaseCandidate
    integration = $branchTypeIntegration
    infrastructure = $branchTypeInfrastructure
}
