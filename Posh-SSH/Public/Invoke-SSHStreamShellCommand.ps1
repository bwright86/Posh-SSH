# .ExternalHelp Posh-SSH.psm1-Help.xml
function Invoke-SSHStreamShellCommand {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param (
        # SSH stream to use for command execution.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [Renci.SshNet.ShellStream]
        $ShellStream,

        # Command to execute on SSHStream.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        [string]
        $Command,

        [Parameter(Mandatory = $false,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $PrompPattern = '[\$%#>] $'
    )

    Begin {
        $promptRegEx = [regex]$PrompPattern
    }
    Process {
        # Discard any banner or previous command output
        do { 
            $ShellStream.read() | Out-Null
    
        } while ($ShellStream.DataAvailable)

        $ShellStream.writeline($Command)

        #discard line with command entered
        $ShellStream.ReadLine() | Out-Null
        Start-Sleep -Milliseconds 500

        $out = ''

        # read all output until there is no more
        do { 
            $out += $ShellStream.read()
    
        } while ($ShellStream.DataAvailable)

        $outputLines = $out.Split("`n")
        foreach ($line in $outputLines) {
            if ($line -notmatch $promptRegEx) {
                $line
            }
        }
    }
    End{}
}