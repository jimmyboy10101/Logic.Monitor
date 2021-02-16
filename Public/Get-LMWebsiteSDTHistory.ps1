Function Get-LMWebsiteSDTHistory
{

    [CmdletBinding(DefaultParameterSetName = 'Id')]
    Param (
        [Parameter(Mandatory,ParameterSetName = 'Id')]
        [Int]$Id,

        [Parameter(ParameterSetName = 'Name')]
        [String]$Name,

        [Hashtable]$Filter,

        [Int]$BatchSize = 1000
    )
    #Check if we are logged in and have valid api creds
    If($global:LMAuth.Valid){

        If($Name){
            If($Name -Match "\*"){
                Write-Host "Wildcard values not supported for website name." -ForegroundColor Yellow
                return
            }
            $Id = (Get-LMWebsite -Name $Name | Select-Object -First 1 ).Id
            If(!$Id){
                Write-Host "Unable to find website with name: $Name, please check spelling and try again." -ForegroundColor Yellow
                return
            }
        }
        
        #Build header and uri
        $ResourcePath = "/website/websites/$Id/historysdts"

        #Initalize vars
        $QueryParams = ""
        $Count = 0
        $Done = $false
        $Results = @()

        #Loop through requests 
        While(!$Done){
            #Build query params
            $QueryParams = "?size=$BatchSize&offset=$Count&sort=-endDateTime"

            If($Filter){
                #List of allowed filter props
                $PropList = @()
                $ValidFilter = Format-LMFilter -Filter $Filter -PropList $PropList
                $QueryParams = "?filter=$ValidFilter&size=$BatchSize&offset=$Count&sort=-endDateTime"
            }

            Try{
                $Headers = New-LMHeader -Auth $global:LMAuth -Method "GET" -ResourcePath $ResourcePath
                $Uri = "https://$($global:LMAuth.Portal).logicmonitor.com/santaba/rest" + $ResourcePath + $QueryParams
    
                #Issue request
                $Response = Invoke-RestMethod -Uri $Uri -Method "GET" -Headers $Headers

                #Stop looping if single device, no need to continue
                If(![bool]$Response.psobject.Properties["total"]){
                    $Done = $true
                    Return $Response
                }
                #Check result size and if needed loop again
                Else{
                    [Int]$Total = $Response.Total
                    [Int]$Count += ($Response.Items | Measure-Object).Count
                    $Results += $Response.Items
                    If($Count -ge $Total){
                        $Done = $true
                    }
                }
            }
            Catch [Exception] {
                $Exception = $PSItem
                Switch($PSItem.Exception.GetType().FullName){
                    {"System.Net.WebException" -or "Microsoft.PowerShell.Commands.HttpResponseException"} {
                        $HttpException = ($Exception.ErrorDetails.Message | ConvertFrom-Json).errorMessage
                        $HttpStatusCode = $Exception.Exception.Response.StatusCode.value__
                        Write-Error "Failed to execute web request($($HttpStatusCode)): $HttpException"
                    }
                    default {
                        $LMError = $Exception.ToString()
                        Write-Error "Failed to execute web request: $LMError"
                    }
                }
            }
        }
        Return $Results
    }
    Else{
        Write-Host "Please ensure you are logged in before running any comands, use Connect-LMAccount to login and try again." -ForegroundColor Yellow
    }
}
