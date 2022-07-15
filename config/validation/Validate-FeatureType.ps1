. $PSScriptRoot/../Variables.ps1

function Validate-FeatureType($type, [switch] $optional) {
    if ($optional -AND $type -eq '') {
        return
    }
    if ($type -notmatch $featureTypeRegex) {
        throw "The feature type '$type' is not valid.";
    }
}