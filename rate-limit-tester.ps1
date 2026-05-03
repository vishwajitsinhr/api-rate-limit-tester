param(
    [int]$Hits = 25,
    [int]$Delay = 1
)

# ========= CONFIG (USE ENV VARIABLES IN REAL USE) =========
$TokenUrl = $env:TOKEN_URL
$Username = $env:API_USERNAME
$Password = $env:API_PASSWORD

Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

function Get-NewToken {
    try {
        $body = @{
            username = $Username
            password = $Password
        }

        $response = Invoke-WebRequest -Uri $TokenUrl -Method POST -Body $body -UseBasicParsing -ErrorAction Stop

        [xml]$xml = $response.Content
        return $xml.Response.Entity.Token
    }
    catch {
        Write-Host "❌ Failed to get token" -ForegroundColor Red
        return $null
    }
}

# ========= API LIST =========
$Urls = @(
    "https://YOUR_API_BASE_URL_HERE/api/endpoint?token={token}"
)

$CsvFile = "rate_limit_results.csv"

if (-not (Test-Path $CsvFile)) {
    "URL,Configured_Hits,Successful_Hits,Observed_Limit,Status,Timestamp,Sizes" |
    Out-File -FilePath $CsvFile -Encoding utf8
}

foreach ($baseUrl in $Urls) {

    $Token = Get-NewToken
    if (-not $Token) {
        Write-Host "Skipping API due to token failure"
        continue
    }

    $url = $baseUrl -replace "\{token\}", $Token

    Write-Host "Testing API: $url"

    $count = 0
    $statusMsg = "OK"
    $sizes = @()

    while ($count -lt $Hits) {
        try {
            $client  = [System.Net.Http.HttpClient]::new()
            $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $url)
            $response = $client.SendAsync($request).Result
            $status   = [int]$response.StatusCode

            if ($status -eq 200) {
                $count++

                $sizeBytes = if ($response.Content.Headers.ContentLength) {
                    [int64]$response.Content.Headers.ContentLength
                } else {
                    ($response.Content.ReadAsByteArrayAsync().Result).Length
                }

                $sizeKB = [math]::Round($sizeBytes / 1024, 2)
                $sizes += "Request$count=$sizeKB KB"

                Write-Host "Request $count OK - $sizeKB KB"
            }
            elseif ($status -eq 429) {
                Write-Host "Rate limit hit after $count requests"
                $statusMsg = "429 Too Many Requests"
                break
            }
            elseif ($status -eq 401) {
                Write-Host "Token expired, refreshing..."
                $Token = Get-NewToken
                if (-not $Token) { break }
                $url = $baseUrl -replace "\{token\}", $Token
                continue
            }
            else {
                Write-Host "Unexpected status: $status"
                $statusMsg = "Unexpected $status"
                break
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)"
            $statusMsg = "Error"
            break
        }

        Start-Sleep -Seconds $Delay
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $sizesJoined = $sizes -join "; "

    "$url,$Hits,$count,$count,""$statusMsg"",""$timestamp"",""$sizesJoined""" |
    Out-File -Append -FilePath $CsvFile -Encoding utf8
}

Write-Host "Completed. Results saved to $CsvFile"