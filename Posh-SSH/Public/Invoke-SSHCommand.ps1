# .ExternalHelp Posh-SSH.psm1-Help.xml
function Invoke-SSHCommand
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
        [SSH.SSHSession[]]
        $SSHSession,

        [Parameter(Mandatory=$true,
                   ParameterSetName = 'Index',
                   Position=0)]
        [Alias('Index')]
        [int32[]]
        $SessionId = $null,

        # Ensures a connection is made by reconnecting before command.
        [Parameter(Mandatory=$false)]
        [switch]
        $EnsureConnection,

        [Parameter(Mandatory=$false,
                   Position=2)]
        [int]
        $TimeOut = 60,

        [Parameter(Mandatory=$false, Position=3)]
        [int]
        $ThrottleLimit = 32
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

        # array to keep track of all the running jobs.
        $Script:AsyncProcessing = @{}
        $JobId = 0
        function CheckAsyncProcessing
        {
            process
            {
                $RemoveJobs = @()
                $Script:AsyncProcessing.GetEnumerator() |
                ForEach-Object {
                    $JobKey = $_.Key
                    #Write-Verbose $JobKey -Verbose
                    $_.Value
                } |
                ForEach-Object {
                    # Check if it completed or is past the timeout setting.
                    if ( $_.Async.IsCompleted -or $_.Duration.Elapsed.TotalSeconds -gt $TimeOut )
                    {
                        $Output = $_.cmd.EndExecute($_.Async)

                        # Generate custom object to return to pipeline and client
                        [pscustomobject]@{
                            Output = $Output -replace '\n$' -split '\n'
                            ExitStatus = $_.cmd.ExitStatus
                            Error = $_.cmd.Error
                            Host = $_.Connection.Host
                            Duration = $_.Duration.Elapsed
                        } |
                        ForEach-Object {
                            $_.pstypenames.insert(0,'Renci.SshNet.SshCommand');

                            #Return object to pipeline
                            $_
                        }

                        # Set this object as having been processed.
                        $_.Processed = $true
                        $RemoveJobs += $JobKey
                    }
                }

                # Remove all the items that are done.
                #[int[]]$Script:AsyncProcessing.Keys |
                $RemoveJobs |
                ForEach-Object {
                    if ($Script:AsyncProcessing.$_.Processed)
                    {
                        $Script:AsyncProcessing.Remove( $_ )
                    }
                }
            }
        }
    }


    Process
    {
        foreach($Connection in $ToProcess)
        {
            if ($Connection.Session.IsConnected)
            {
                if ($EnsureConnection)
                {
                    try
                    {
                        $Connection.Session.Connect()
                    }
                    catch
                    {
                        if ( $_.Exception.InnerException.Message -ne 'The client is already connected.' )
                        { Write-Error -Exception $_.Exception }
                    }
                }
            }
            else
            {
                try
                {
                    $Connection.Session.Connect()
                }
                catch
                {
                    Write-Error "Unable to connect session to $($Connection.Host) :: $_"
                }

            }

            if ($Connection.Session.IsConnected)
            {
                while ($Script:AsyncProcessing.Count -ge $ThrottleLimit )
                {
                    CheckAsyncProcessing
                    Write-Debug "Throttle reached: $ThrottleLimit"
                    Start-Sleep -Milliseconds 50
                }

                $cmd = $Connection.session.CreateCommand($Command)
                $cmd.CommandTimeout = [timespan]::FromMilliseconds(50) #New-TimeSpan -Seconds $TimeOut

                # start asynchronious execution of the command.
                $Duration = [System.Diagnostics.Stopwatch]::StartNew()
                $Async = $cmd.BeginExecute()

                $Script:AsyncProcessing.Add( $JobId, ( [pscustomobject]@{
                    cmd = $cmd
                    Async = $Async
                    Connection = $Connection
                    Duration = $Duration
                    Processed = $false
                }))

                $JobId++
            }

            CheckAsyncProcessing

        }
    }
    End
    {
        $Done = $false
        while ( -not $Done )
        {
           CheckAsyncProcessing

            if ( $Script:AsyncProcessing.Count -eq 0 )
            { $Done = $true }
            else { Start-Sleep -Milliseconds 50 }
        }
    }
}