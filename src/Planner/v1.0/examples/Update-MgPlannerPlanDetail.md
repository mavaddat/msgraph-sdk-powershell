### Example 1: Code snippet

```powershellImport-Module Microsoft.Graph.Planner

$params = @{
	sharedWith = @{
		"6463a5ce-2119-4198-9f2a-628761df4a62" = $true
		"d95e6152-f683-4d78-9ff5-67ad180fea4a" = $false
	}
	categoryDescriptions = @{
		category1 = "Indoors"
		category3 = $null
	}
}

Update-MgPlannerPlanDetail -PlannerPlanId $plannerPlanId -BodyParameter $params-If-Match W/"JzEtVGFzayAgQEBAQEBAQEBAQEBAQEBAWCc="
```
This example shows how to use the Update-MgPlannerPlanDetail Cmdlet.
To learn about permissions for this resource, see the [permissions reference](/graph/permissions-reference).

