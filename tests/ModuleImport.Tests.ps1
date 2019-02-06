# A pester test to ensure module can be loaded.

$modulePath = "$PSScriptRoot\..\Posh-SSH\Posh-SSH.psd1"

Describe "Module Loading Tests" {

    it "Imports Posh-SSH w/o errors" {
        Import-Module -Name $modulePath
        $error.count | Should -Be 0
    }
}