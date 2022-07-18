$ticketPartialRegex = '[A-Z]+-[0-9]+'
$defaultFeatureType = 'feature'
$featureTypePartialRegex = '(feature|bugfix)'
$commentPart = '[^/]+'
$parentTicketDelimeter = '_'

$ticketRegex = "^$ticketPartialRegex$"
$featureTypeRegex = "^$featureTypePartialRegex$"
# $featureBranchRegex = "(?<type>$featureTypePartialRegex)/(?<ticket>$ticketPartialRegex)(-(?<comment>$commentPart))?"
$featureBranchRegex = "^(?<type>$featureTypePartialRegex)/(?<parentTickets>$ticketPartialRegex$parentTicketDelimeter)*(?<ticket>$ticketPartialRegex)(-(?<comment>$commentPart))?$"
$rcBranchRegex = "^rc/(?<comment>$commentPart)$"
$integrationBranchRegex = "^integrate/(?<tickets>($ticketPartialRegex$parentTicketDelimeter)*$ticketPartialRegex)"
$infraBranchRegex = "^infra/((?<tickets>($ticketPartialRegex$parentTicketDelimeter)*$ticketPartialRegex)-)?(?<comment>$commentPart)$"
