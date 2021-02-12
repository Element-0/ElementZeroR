function Invoke-NativeCommand {
    <#
    .SYNOPSIS
        Invoke a native command (.exe) as a new process.

    .DESCRIPTION
        Invoke-NativeCommand executes an arbitrary executable as a new process. Both the standard
        and error output streams are redirected.

        Error out is written as a single non-terminating error. ErrorAction can be used to raise
        this as a terminating error.

    .EXAMPLE
        Invoke-NativeCommand git clone repo-uri -ErrorAction "Stop"

        Run the git command to clone repo-uri. Raise a terminating error if the command fails.
    #>

    [CmdletBinding()]
    param (
        <#
            The command line to execute. This parameter is named to attempt to avoid conflicts with
            parameters for the executing command line.
        #>
        [Parameter(Position = 1, ValueFromRemainingArguments, ValueFromPipeline)]
        $__CommandLine
    )

    process {
        $command, $argumentList = $__CommandLine

        try {
            $process = [System.Diagnostics.Process]@{
                StartInfo = [System.Diagnostics.ProcessStartInfo]@{
                    FileName               = (Get-Command $command -ErrorAction "Stop").Source
                    Arguments              = $argumentList
                    WorkingDirectory       = $pwd
                    RedirectStandardOutput = $true
                    RedirectStandardError  = $true
                    UseShellExecute        = $false
                }
            }
            $null = $process.Start()
            $process.WaitForExit()

            while (-not $process.StandardOutput.EndOfStream) {
                $process.StandardOutput.ReadToEnd()
            }

            while (-not $process.StandardError.EndOfStream) {
                Write-Error $process.StandardError.ReadToEnd()
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}