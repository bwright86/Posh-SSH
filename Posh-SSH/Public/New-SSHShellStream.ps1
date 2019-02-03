# .ExternalHelp Posh-SSH.psm1-Help.xml
function New-SSHShellStream
{
    [CmdletBinding(DefaultParameterSetName="Index")]
    [OutputType([Renci.SshNet.ShellStream])]
    Param
    (
        [Parameter(Mandatory=$true,
            ParameterSetName = "Session",
            ValueFromPipeline=$true,
            Position=0)]
        [Alias("Session")]
        [SSH.SSHSession]
        $SSHSession,

        [Parameter(Mandatory=$true,
            ParameterSetName = "Index",
            ValueFromPipeline=$true,
            Position=0)]
        [Alias('Index')]
        [Int32]
        $SessionId,

        # Name of the terminal.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $TerminalName = "PoshSSHTerm",

        # The columns
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Columns=80,

        # The rows.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Rows=24,

        # The width.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Width= 800,

        # The height.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Height=600,

        # Size of the buffer.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $BufferSize=1000
    )

    Begin
    {
        $ToProcess = $null
        switch($PSCmdlet.ParameterSetName)
        {
            'Session'
            {
                $ToProcess = $SSHSession
            }

            'Index'
            {
                $sess = Get-SSHSession -Index $SessionId
                if ($sess)
                {
                    $ToProcess = $sess
                }
                else
                {
                    Write-Error -Message "Session specified with Index $($SessionId) was not found"
                    return
                }
            }
        }
    }
    Process
    {
        $stream = $ToProcess.Session.CreateShellStream($TerminalName, $Columns, $Rows, $Width, $Height, $BufferSize)
        Add-Member -InputObject $stream -MemberType NoteProperty -Name SessionId -Value $ToProcess.SessionId
        Add-Member -InputObject $stream -MemberType NoteProperty -Name Session -Value $ToProcess.Session
        $stream
    }
    End
    {
    }
}