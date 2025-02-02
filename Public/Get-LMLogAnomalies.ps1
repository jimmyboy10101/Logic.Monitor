Function Get-LMLogAnomalies {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [String[]]$DeviceIdList,

        [Datetime]$StartDate,

        [Datetime]$EndDate,

        [Parameter(ParameterSetName = 'Type')]
        [ValidateSet("never_before_seen")]
        [String]$AnomalyType,

        [Int]$BatchSize = 300
    )
    #Check if we are logged in and have valid api creds
    If ($Script:LMAuth.Valid) {
        
        #Build header and uri
        $ResourcePath = "/log/anomalies/log"

        #Initalize vars
        $QueryParams = ""
        $Results = @()

        #Convert to epoch, if not set use defaults 30 min search
        If (!$StartDate) {
            [int]$StartDate = ([DateTimeOffset]$(Get-Date).AddMinutes(-30)).ToUnixTimeSeconds()
        }
        Else {
            [int]$StartDate = ([DateTimeOffset]$($StartDate)).ToUnixTimeSeconds()
        }

        If (!$EndDate) {
            [int]$EndDate = ([DateTimeOffset]$(Get-Date)).ToUnixTimeSeconds()
        }
        Else {
            [int]$EndDate = ([DateTimeOffset]$($EndDate)).ToUnixTimeSeconds()
        }


        #Build query params
        $QueryParams = "?startTime=$StartDate&endTime=$EndDate&size=$BatchSize&range=custom"

        If ($AnomalyType) {
            $QueryParams += "&anomalyType=$AnomalyType"
        }

        If ($DeviceIdList) {
            $QueryParams += "&devices=$($DeviceIdList -Join ",")"
        }

        Try {
            $Headers = New-LMHeader -Auth $Script:LMAuth -Method "GET" -ResourcePath $ResourcePath
            $Uri = "https://$($Script:LMAuth.Portal).logicmonitor.com/santaba/rest" + $ResourcePath + $QueryParams

            $Uri

            #Issue request
            $Response = Invoke-RestMethod -Uri $Uri -Method "GET" -Headers $Headers

            $Results = $Response.Items
        }
        Catch [Exception] {
            $Proceed = Resolve-LMException -LMException $PSItem
            If (!$Proceed) {
                Return
            }
        }
        Return $Response
    }
    Else {
        Write-Error "Please ensure you are logged in before running any comands, use Connect-LMAccount to login and try again."
    }
}
