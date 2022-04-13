Function Get-LMDashboardWidget {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(ParameterSetName = 'Id')]
        [Int]$Id,

        [Parameter(ParameterSetName = 'Name')]
        [String]$Name,

        [Parameter(ParameterSetName = 'DashboardId')]
        [String]$DashboardId,

        [Parameter(ParameterSetName = 'DashboardName')]
        [String]$DashboardName,

        [Parameter(ParameterSetName = 'Filter')]
        [Hashtable]$Filter,

        [Int]$BatchSize = 1000
    )
    #Check if we are logged in and have valid api creds
    If ($Script:LMAuth.Valid) {

        If ($DashboardName) {
            $LookupResult = (Get-LMDashboard -Name $DashboardName).Id
            If (Test-LookupResult -Result $LookupResult -LookupString $DashboardName) {
                return
            }
            $DashboardId = $LookupResult
        }
        
        #Build header and uri
        $ResourcePath = "/dashboard/widgets"

        #Initalize vars
        $QueryParams = ""
        $Count = 0
        $Done = $false
        $Results = @()

        #Loop through requests 
        While (!$Done) {
            #Build query params
            Switch ($PSCmdlet.ParameterSetName) {
                "All" { $QueryParams = "?size=$BatchSize&offset=$Count&sort=+id" }
                "Id" { $resourcePath += "/$Id" }
                "Name" { $QueryParams = "?filter=name:`"$Name`"&size=$BatchSize&offset=$Count&sort=+id" }
                "DashboardId" { $QueryParams = "?filter=dashboardId:`"$DashboardId`"&size=$BatchSize&offset=$Count&sort=+id" }
                "DashboardName" { $QueryParams = "?filter=dashboardId:`"$DashboardId`"&size=$BatchSize&offset=$Count&sort=+id" }
                "Filter" {
                    #List of allowed filter props
                    $PropList = @()
                    $ValidFilter = Format-LMFilter -Filter $Filter -PropList $PropList
                    $QueryParams = "?filter=$ValidFilter&size=$BatchSize&offset=$Count&sort=+id"
                }
            }

            Try {
                $Headers = New-LMHeader -Auth $Script:LMAuth -Method "GET" -ResourcePath $ResourcePath
                $Uri = "https://$($Script:LMAuth.Portal).logicmonitor.com/santaba/rest" + $ResourcePath + $QueryParams
    
                #Issue request
                $Response = Invoke-RestMethod -Uri $Uri -Method "GET" -Headers $Headers

                #Stop looping if single device, no need to continue
                If ($PSCmdlet.ParameterSetName -eq "Id") {
                    $Done = $true
                    Return $Response
                }
                #Check result size and if needed loop again
                Else {
                    [Int]$Total = $Response.Total
                    [Int]$Count += ($Response.Items | Measure-Object).Count
                    $Results += $Response.Items
                    If ($Count -ge $Total) {
                        $Done = $true
                    }
                }
            }
            Catch [Exception] {
                $Proceed = Resolve-LMException -LMException $PSItem
                If (!$Proceed) {
                    Return
                }
            }
        }
        Return $Results
    }
    Else {
        Write-Error "Please ensure you are logged in before running any comands, use Connect-LMAccount to login and try again."
    }
}
