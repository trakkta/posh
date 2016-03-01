# Copyright 2016 Max Yeremin
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A helper routine similar to cURL. It uses the flexible and REST-friendly System.Net.Http.HttpClient, needs .NET 4.5+ 
# 
# Parameters:
# -X [string], optional - HTTP method (GET, POST, ...), GET and POST can be inferred
# -H [hashtable], optional - a collection of headers, e.g. @{"Content-Type"="application/json", "Accept"="*/*"}
# -d [string], optional - request data
# -u [string] - URI of the resource
# Returns:
# [string] - output, in a CURL-like fashion

Export-ModuleMember Invoke-Curl

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
    }
    
    process {
        $uri = New-Object System.Uri($u, [System.UriKind]::Absolute)
        $req = New-Object System.Net.Http.HttpRequestMessage($method, $uri)
        
        if ($requestHeaders.Keys -notcontains "Host") {
            $req.Headers.Add("Host", $uri.Host)
        }
        
        if ($requestHeaders.Keys -notcontains "Accept") {
            $req.Headers.Add("Accept", "*/*")
        }
        
        if ($requestHeaders.Keys -notcontains "User-Agent") {
            $req.Headers.Add("User-Agent", -Join @("Powershell/", $PSVersionTable.PSVersion.Major, ".", $PSVersionTable.PSVersion.Minor, " (", [System.Environment]::OSVersion.VersionString, ")"))
        }
        
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
        
        [void]$outStr.Append(@($method, $uri.AbsolutePath, "HTTP/1.1") -Join " ")
        [void]$outStr.Append("`n")
        
        foreach ($header in $req.Headers) {
            [void]$outStr.Append($header.Key + ": " + $header.Value)
            [void]$outStr.Append("`n")
        }
        
        if ($req.Content -ne $null) {
            foreach ($header in $req.Content.Headers) {
                [void]$outStr.Append($header.Key + ": " + $header.Value)
                [void]$outStr.Append("`n")
            }
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
            foreach ($header in $res.Content.Headers) {
                [void]$outStr.Append($header.Key + ": " + $header.Value)
                [void]$outStr.Append("`n")
            }
        }
        
        if ($res.Content -ne $null) {
            [void]$outStr.Append("`n")
            [void]$outStr.Append($res.Content.ReadAsStringAsync().Result)
            [void]$outStr.Append("`n")
        }
        
        $client.Dispose()
        
        return $outStr.ToString()
    }
    
    end {
    }
}
