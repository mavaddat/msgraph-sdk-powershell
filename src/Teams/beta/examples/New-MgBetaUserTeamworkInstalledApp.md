### Example 1: Code snippet

```powershell

Import-Module Microsoft.Graph.Beta.Teams

$params = @{
	"teamsApp@odata.bind" = "https://graph.microsoft.com/beta/appCatalogs/teamsApps/12345678-9abc-def0-123456789a"
}

New-MgBetaUserTeamworkInstalledApp -UserId $userId -BodyParameter $params

```
This example shows how to use the New-MgBetaUserTeamworkInstalledApp Cmdlet.

