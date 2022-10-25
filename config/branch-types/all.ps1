. $PSScriptRoot/service-line.ps1
. $PSScriptRoot/feature.ps1
. $PSScriptRoot/release-candidate.ps1
. $PSScriptRoot/integration.ps1
. $PSScriptRoot/infrastructure.ps1

$branchTypes = @{
    serviceLine = $branchTypeServiceLine
    feature = $branchTypeFeature
    rc = $branchTypeReleaseCandidate
    integration = $branchTypeIntegration
    infrastructure = $branchTypeInfrastructure
}
