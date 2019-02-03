# .ExternalHelp Posh-SSH.psm1-Help.xml
function Invoke-SSHCommandStream
{
    [CmdletBinding(DefaultParameterSetName='Index')]
    param(

        [Parameter(Mandatory=$true,
                Position=1)]
        [string]$Command,

        [Parameter(Mandatory=$true,
                ParameterSetName = 'Session',
                ValueFromPipeline=$true,
                Position=0)]
        [Alias('Name')]
        [SSH.SSHSession]
        $SSHSession,

        [Parameter(Mandatory=$true,
                ParameterSetName = 'Index',
                Position=0)]
        [Alias('Index')]
        [int32]
        $SessionId,

        # Ensures a connection is made by reconnecting before command.
        [Parameter(Mandatory=$false)]
        [switch]
        $EnsureConnection,

        [Parameter(Mandatory=$false,
                Position=2)]
        [int]
        $TimeOut = 60,

        [Parameter()]
        [string]
        $HostVariable,

        [Parameter()]
        [string]
        $ExitStatusVariable
    )

    Begin
    {
        $ToProcess = @()
        switch($PSCmdlet.ParameterSetName)
        {
            'Session'
            {
                $ToProcess = $SSHSession
            }

            'Index'
            {
                foreach($session in $Global:SshSessions)
                {
                    if ($SessionId -contains $session.SessionId)
                    {
                        $ToProcess += $session
                    }
                }
            }
        }
    }
    Process
    {
        foreach($Connection in $ToProcess)
        {
            if ($Connection.session.isconnected)
                {
                    if ($EnsureConnection)
                    {
                        $Connection.session.connect()
                    }
                    $cmd = $Connection.session.CreateCommand($Command)
                }
                else
                {
                    $s.session.connect()
                    $cmd = $Connection.session.CreateCommand($Command)
                }

                $cmd.CommandTimeout = New-TimeSpan -Seconds $TimeOut

                if ( $PSBoundParameters.ContainsKey('HostVariable') )
                { Set-Variable -Scope 1 -Name $HostVariable -Value $Connection.Host }


                # start asynchronious execution of the command.
                $Async = $cmd.BeginExecute()
                $Duration = [System.Diagnostics.Stopwatch]::StartNew()
                $Reader = New-Object System.IO.StreamReader -ArgumentList $cmd.OutputStream

                try
                {
                    Write-Verbose "IsCompleted Before: $($Async.IsCompleted)"
                    while(-not $Async.IsCompleted -and $Duration.Elapsed -lt $cmd.CommandTimeout )
                    {
                        Write-Verbose "IsCompleted During: $($Async.IsCompleted)"
                        #if ( $Reader.Peek() -gt -1)
                        while ( $Reader.Peek() -gt -1)
                        {
                            $Result = $Reader.ReadLine()
                            $Result -replace '\n\r$'
                        }
                        Start-Sleep -Milliseconds 5
                    }
                }
                catch
                {
                    Write-Error -Message "Error with Command: $_"
                }
                finally
                {
                    Write-Verbose "IsCompleted After: $($Async.IsCompleted)"
                    # Using finally clause to make sure the command is ended if Ctrl-C is used to cancel it.

                    while ( $Reader.Peek() -gt -1)
                    {
                        $Result = $Reader.ReadLine()
                        $Result -replace '\n\r$'
                    }

                    if (-not $Async.IsCompleted -and $Duration.Elapsed -ge $cmd.CommandTimeout )
                    {
                        $cmd.EndExecute($Async)

                    }
                    elseif ( -not $Async.IsCompleted )
                    {
                        $cmd.CancelAsync()
                        Write-Warning "Canceled execution"

                    }

                }

            if ( $PSBoundParameters.ContainsKey('ExitStatusVariable') )
            {
                Set-Variable -Scope 1 -Name $ExitStatusVariable -Value @{
                    Host = $Connection.Host
                    ExitStatus = $cmd.ExitStatus
                    Error = $cmd.Error
                }
            }
        }
    }
    End{}
}