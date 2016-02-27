# A helper routine similar to cURL
# Author: Max Yeremin
# Copyright 2016
#
# Uses the flexible and REST-friendly System.Net.Http.HttpClient, needs .NET 4.5+ 
#
# Invoke-Curl
# -X [string], optional - HTTP method (GET, POST, ...), GET and POST can be inferred
# -H [hashtable], optional - a collection of headers, e.g. @{"Content-Type"="application/json", "Accept"="*/*"}
# -d [string], optional - request data
# -u [string] - URI of the resource
# returns [string] - output, in a CURL-like fashion

Add-Type -AssemblyName System.Net.Http

function Invoke-Curl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$X,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [hashtable]$H,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$d,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$u
    )
    
    begin {
    }
    
    process {
        if ([string]::IsNullOrEmpty($X)) {
            $X = @("POST", "GET")[[string]::IsNullOrEmpty($d)]
        }
        
        $contentHeaderNames = "Allow", "Content-Disposition", "Content-Encoding", "Content-Language", "Content-Length", "Content-Location", "Content-MD5", "Content-Range", "Content-Type", "Expires", "LastModified"
        $requestHeaders = @{}
        $contentHeaders = @{}
        $contentType = "text/plain"
        
        if ($H -ne $null) {
            foreach ($header in $H.GetEnumerator()) {
                if ($contentHeaderNames -contains $header.Key) {
                    if ($header.Key -eq "Content-Type") {
                        $contentType = $header.Value
                    } else {
                        $contentHeaders.Add($header.Key, $header.Value)
                    }
                } else {
                    $requestHeaders.Add($header.Key, $header.Value)
                }
            }
        }
        
        $method = New-Object System.Net.Http.HttpMethod($X)
        $req = New-Object System.Net.Http.HttpRequestMessage($method, $u)
        
        foreach ($header in $requestHeaders.GetEnumerator()) {                
            $req.Headers.Add($header.Key, $header.Value)
        }
        
        if (-not [string]::IsNullOrEmpty($d) -and (($X -eq "POST") -or ($X -eq "PUT") -or ($X -eq "PATCH") -or ($X -eq "DELETE"))) {
            $req.Content = New-Object System.Net.Http.StringContent($d, [System.Text.Encoding]::UTF8, $contentType)
            
            foreach ($header in $contentHeaders.GetEnumerator()) {
                $req.Content.Headers.Add($header.Key, $header.Value)
            }
            
            $req.Content.Headers.ContentLength = $req.Content.Headers.ContentLength
        }
        
        $outStr = New-Object System.Text.StringBuilder
        
        [void]$outStr.Append($method)
        [void]$outStr.Append("`n")
        
        foreach ($header in $req.Headers) {
            [void]$outStr.Append($header.Key + ": " + $header.Value)
            [void]$outStr.Append("`n")
        }
        
        foreach ($header in $req.Content.Headers) {
            [void]$outStr.Append($header.Key + ": " + $header.Value)
            [void]$outStr.Append("`n")
        }
        
        $client = New-Object System.Net.Http.HttpClient
        $res = $client.SendAsync($req).Result
        
        [void]$outStr.Append("`n")
        [void]$outStr.Append([int]$res.StatusCode)
        [void]$outStr.Append(" " + $res.StatusCode)
        [void]$outStr.Append("`n")
        
        foreach ($header in $res.Headers) {
            [void]$outStr.Append($header.Key + ": " + $header.Value)
            [void]$outStr.Append("`n")
        }
        
        if ($res.Content -ne $null) {
            [void]$outStr.Append($res.Content.ReadAsStringAsync().Result)
        }
        
        $client.Dispose()
        
        return $outStr.ToString()        
    }
    
    end {
    }
}