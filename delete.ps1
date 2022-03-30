$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

#Change mapping here
$account = [PSCustomObject]@{ }

#region functions
# Write functions logic here

#endregion functions


if (-Not($dryRun -eq $true)) {
    # Write delete logic here
	try 
	{
		$headers=@{}
		$headers.Add("Accept", "application/json")
		$headers.Add("authorization", "Bearer $($c.Bearer)")

		$response = Invoke-WebRequest -Uri "https://openapi.pleo.io/v1/employees/$($aRef)" -Method DELETE -Headers $headers
		$success = $true
		$auditLogs.Add([PSCustomObject]@{
			# Action = "DeleteAccount" Optionally specify a different action for this audit log
			Message = "Account $($aRef) deleted"
			IsError = $false
			}
		)
	}
	catch 
	{
		$auditLogs.Add([PSCustomObject]@{
			# Action = "DeleteAccount" Optionally specify a different action for this audit log
			Message = "Account $($aRef) could not be deleted, $_"
			IsError = $true
			}
		)
	}
}



# Send results
$result = [PSCustomObject]@{
    Success   = $success
    AuditLogs = $auditLogs
    Account   = $account
}

Write-Output $result | ConvertTo-Json -Depth 10