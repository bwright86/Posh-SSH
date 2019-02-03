# .ExternalHelp Posh-SSH.psm1-Help.xml
function Invoke-SSHStreamExpectSecureAction
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

        # SecureString representation of action once an expression is matched.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [securestring]
        $SecureAction,

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
                Write-Verbose -Message 'Matching by String.'
                $found = $ShellStream.Expect($ExpectString, (New-TimeSpan -Seconds $TimeOut))
             }

            'Regex'  {
                Write-Verbose -Message 'Matching by RegEx.'
                $found = $ShellStream.Expect($ExpectRegex, (New-TimeSpan -Seconds $TimeOut))
             }
        }

        if ($found -ne $null)
        {
            Write-Verbose -Message "Executing action."
            $ShellStream.WriteLine([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureAction)))
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