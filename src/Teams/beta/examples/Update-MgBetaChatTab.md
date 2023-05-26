### Example 1: Code snippet

```powershellImport-Module Microsoft.Graph.Beta.Teams

Get-MgBetaChatTab -ChatId $chatId -TeamsTabId $teamsTabId -ExpandProperty "teamsApp"
```
This example shows how to use the Update-MgBetaBetaChatTab Cmdlet.
To learn about permissions for this resource, see the [permissions reference](/graph/permissions-reference).

