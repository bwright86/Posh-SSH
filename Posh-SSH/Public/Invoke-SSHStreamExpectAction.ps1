# .ExternalHelp Posh-SSH.psm1-Help.xml
function Invoke-SSHStreamExpectAction
{
    [CmdletBinding(DefaultParameterSetName='String')]
    [OutputType([Bool])]
    Param
    (
        # SSH Shell Stream.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Renci.SshNet.ShellStream]
        $ShellStream,

        # Initial command that will generate the output to be evaluated by the expect pattern.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Command,

        # String on what to trigger the action on.
        [Parameter(Mandatory=$true,
                   ParameterSetName='String',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $ExpectString,

        # Regular expression on what to trigger the action on.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Regex',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [regex]
        $ExpectRegex,

        # Command to execute once an expression is matched.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $Action,

        # Number of seconds to wait for a match.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [int]
        $TimeOut = 10
    )

    Begin
    {
    }
    Process
    {
        Write-Verbose -Message "Executing command $($Command)."
        $ShellStream.WriteLine($Command)
        Write-Verbose -Message "Waiting for match."
        switch ($PSCmdlet.ParameterSetName)
        {
            'string' {
                Write-Verbose "Matching on string $($ExpectString)"
                $found = $ShellStream.Expect($ExpectString, (New-TimeSpan -Seconds $TimeOut))}
            'Regex'  {
                Write-Verbose "Matching on pattern $($ExpectRegex)"
                $found = $ShellStream.Expect($ExpectRegex, (New-TimeSpan -Seconds $TimeOut))}
        }

        if ($found -ne $null)
        {
            Write-Verbose -Message "Executing action: $($Action)."
            $ShellStream.WriteLine($Action)
            Write-Verbose -Message 'Action has been executed.'
            $true
        }
        else
        {
            Write-Verbose -Message 'Expect timeout without achiving a match.'
            $false
        }
    }
    End
    {
    }
}