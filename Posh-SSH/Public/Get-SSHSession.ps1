# .ExternalHelp Posh-SSH.psm1-Help.xml
function Get-SSHSession
{
    [CmdletBinding(DefaultParameterSetName='Index')]
    param(
        [Parameter(Mandatory=$false,
                   ParameterSetName = 'Index',
                   Position=0)]
        [Alias('Index')]
        [Int32[]]
        $SessionId,

        [Parameter(Mandatory=$false,
                   ParameterSetName = 'ComputerName',
                   Position=0)]
        [Alias('Server', 'HostName', 'Host')]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory=$false,
                   ParameterSetName = 'ComputerName',
                   Position=0)]
        [switch]
        $ExactMatch
    )

    Begin{}
    Process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Index')
        {
            if ( $PSBoundParameters.ContainsKey('SessionId') )
            {
                foreach($i in $SessionId)
                {
                    foreach($session in $SshSessions)
                    {
                        if ($session.SessionId -eq $i)
                        {
                            $session
                        }
                    }
                }
            }
            else
            {
                # Can not reference SShSessions directly so as to be able
                # to remove the sessions when Remove-SSHSession is used
                $return_sessions = @()
                foreach($s in $SshSessions){$return_sessions += $s}
                $return_sessions
            }
        }
        else # ParameterSetName -eq 'ComputerName'
        {
            # Only check to see if it contains ComputerName.  If it get's it without having any values somehow, then don't return anything as they did something odd.
            if ( $PSBoundParameters.ContainsKey('ComputerName') )
            {
                foreach($s in $ComputerName)
                {
                    foreach($session in $SshSessions)
                    {
                        if ($session.Host -like $s -and ( -not $ExactMatch -or $session.Host -eq $s ) )
                        {
                            $session
                        }
                    }
                }
            }
        }
    }
    End{}
}