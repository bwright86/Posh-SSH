Import-Module $PSScriptRoot\..\Posh-SSH.psd1

# Idea found in this SO answer: https://stackoverflow.com/questions/42522454/how-to-handle-keyboard-interactive-authentication-prompts-in-powershell

Describe "Test Keyboard Interactive Authentication" {

    $IP = "20.20.20.21"
    $Port = 22
    $Cred = $(Get-Credential)
    $user = $cred.UserName

    $action = {
        param([System.Object]$sender, [Renci.SshNet.Common.AuthenticationPromptEventArgs]$e)
        foreach ($prompt in $e.Prompts) {
            if ($prompt.request.tolower() -like "*password*") {
                $prompt.response = $Cred.GetNetworkCredential().Password
            }
        }
    }

    $KIConnInfo = [Renci.SshNet.KeyboardInteractiveConnectionInfo]::new($IP, $Port, $user)

    Register-ObjectEvent -InputObject $KIConnInfo -EventName AuthenticationPrompt -Action $action

    $client =  [Renci.SshNet.SshClient]::new($IP, $Port, $user, $Cred.GetNetworkCredential().Password)

    it "Client connects" {
        $client.Connect()
    }

}