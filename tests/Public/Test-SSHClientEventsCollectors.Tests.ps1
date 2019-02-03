Import-Module $PSScriptRoot\..\Posh-SSH.psd1

# Idea found in this SO answer: https://stackoverflow.com/questions/42522454/how-to-handle-keyboard-interactive-authentication-prompts-in-powershell

Describe "Receive Host Key Fingerprint" {

    $IP = "20.20.20.21"
    $Port = 22
    $Cred = $(Get-Credential)
    $user = $cred.UserName

    # Instantiate an object to hold the hos
    $Global:HostKey = ""

    $AuthPromptaction = {
        param([System.Object]$sender, [Renci.SshNet.Common.AuthenticationPromptEventArgs]$e)
        foreach ($prompt in $e.Prompts) {
            if ($prompt.request.tolower() -like "*password*") {
                $prompt.response = $Cred.GetNetworkCredential().Password
            }
        }
    }

    $HostKeyaction = {
        param([System.Object]$sender, [Renci.SshNet.Common.HostKeyEventArgs]$e)
        $Global:HostKey = $e
    }

    $KIConnInfo = [Renci.SshNet.KeyboardInteractiveConnectionInfo]::new($IP, $Port, $user)

    Register-ObjectEvent -InputObject $KIConnInfo -EventName AuthenticationPrompt -Action $AuthPromptaction

    $client =  [Renci.SshNet.SshClient]::new($IP, $Port, $user, $Cred.GetNetworkCredential().Password)

    Register-ObjectEvent -InputObject $client -EventName HostKeyReceived -Action $HostKeyaction

    $client.Connect()

    it "Client connects" {
        $client.IsConnected | Should -BeTrue
    }

    it "Contains a fingerprint" {
        $fingerprint = ($Global:HostKey.Fingerprint | ForEach-Object ToString X2) -Join ":"
        
        $fingerprint | Write-Host

        $fingerprint | Should -not -BeNullOrEmpty   
    }
}