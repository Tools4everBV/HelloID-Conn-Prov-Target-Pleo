$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

$accountGuid = ""

#region functions
# Write functions logic here

#endregion functions



# Change mapping here
$account = [PSCustomObject]@{
	firstName = $p.name.GivenName
	lastName = $p.name.FamilyName
	email = $p.contact.business.email
	title = $p.PrimaryContract.Title.Name
	phone = $p.contact.Business.phone.mobile
}

$accountfound = $false;
if (-Not($dryRun -eq $true)) {
    # Write create logic here
	try 
	{
		$headers=@{}
		$headers.Add("Accept", "application/json")
		$headers.Add("authorization", "Bearer $($c.bearer)")
		$response = Invoke-RestMethod -Uri 'https://openapi.pleo.io/v1/employees' -Method GET -Headers $headers
		#$response.employees
		$employee = $response.employees | where { $_.email -eq $p.contact.business.email }
		if (($employee | Measure-Object).Count -ge 1)
		{
			#Correlate
			$accountGuid = $employee.id
			$accountfound = $true;
			$success = $true
			Write-Information $accountGuid
			$auditLogs.Add([PSCustomObject]@{
					# Action = "CreateAccount" Optionally specify a different action for this audit log
					Message = "Correlated account with username $($account.UserName)"
					IsError = $false
				}
			)
		}
		else
		{
			$body_create_1 = @{
				email = $p.contact.business.email
			}
			#create
			#create mail
			$response = Invoke-RestMethod -Uri 'https://openapi.pleo.io/v1/employees' -Method POST -Headers $headers -ContentType 'application/json' -Body ($body_create_1 | ConvertTo-Json)
			
			$accountGuid = $response.id
			$success = $true
			$response = Invoke-RestMethod -Uri "https://openapi.pleo.io/v1/employees/$($response.id)" -Method PUT -Headers $headers -ContentType 'application/json' -Body ($account | ConvertTo-Json)
			
			$auditLogs.Add([PSCustomObject]@{
					# Action = "CreateAccount" Optionally specify a different action for this audit log
					Message = "Created account with username $($account.UserName)"
					IsError = $false
				}
			)
		}
	}
	catch 
	{
		$auditLogs.Add([PSCustomObject]@{
			# Action = "DeleteAccount" Optionally specify a different action for this audit log
			Message = "Account $($p.contact.business.email) could not be created, $_"
			IsError = $true
			}
		)
	}
}

# Send results
$result = [PSCustomObject]@{
    Success          = $success
    AccountReference = $accountGuid
    AuditLogs        = $auditLogs
    Account          = $account
}

Write-Output $result | ConvertTo-Json -Depth 10