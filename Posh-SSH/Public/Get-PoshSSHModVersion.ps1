# .ExternalHelp Posh-SSH.psm1-Help.xml
function Get-PoshSSHModVersion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param()

    Begin {
        $CurrentVersion = $null
        $installed = (Get-Module -Name 'posh-SSH').Version
    }
    Process {
        $webClient = New-Object System.Net.WebClient
        Try {
            $current = Invoke-Expression  $webClient.DownloadString('https://raw.github.com/darkoperator/Posh-SSH/master/Posh-SSH.psd1')
            $CurrentVersion = [Version]$current.ModuleVersion
        }
        Catch {
            Write-Warning 'Could not retrieve the current version.'
        }

        if ( $installed -eq $null ) {
            Write-Error 'Unable to locate Posh-SSH.'
        }
        elseif ( $CurrentVersion -gt $installed ) {
            Write-Warning 'You are running an outdated version of the module.'
        }

        $props = @{
            InstalledVersion = $installed
            CurrentVersion   = $CurrentVersion
        }
        New-Object -TypeName psobject -Property $props
    }
    End {}
}