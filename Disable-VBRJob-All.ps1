Function Disable-VBRJob-All{  
    [CmdletBinding()]
    Param(
    )
  
  Begin{
    Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Disabling all Veeam jobs."
  }#End Begin
  
  Process{
    Try{
        #Get a list of all enabled jobs
        $EnabledJobs = Get-VBRJob | Where {$_.IsScheduleEnabled -eq $True}
        $EnabledCountStart = ($EnabledJobs | measure).Count

        if ($EnabledCountStart -gt 0)
        {
            Write-Output "There are currently $EnabledCountStart enabled jobs."
            Write-Output "Will wait for any running jobs."
            Write-Output $EnabledJobs.Name
        }

        #If there are any enabled jobs disable them.
        while(Get-VBRJob | Where {$_.IsScheduleEnabled -eq $True})
        {

            Write-Progress -Activity “Disabling all Veeam jobs.” -status “Currently running, waiting to finish: $($EnabledJobs.Name )” -percentComplete ($EnabledCount / $EnabledCountStart*100)
    
            foreach ($Job in $EnabledJobs)
            {
                #Make sure that job is not running or that it is continuous
                if ($($Job.IsRunning) -eq $false -or $($Job.IsContinuous) -eq $true )
                {
                    Disable-VBRJob -Job $Job | Out-Null
                }
        
            }
            sleep 2
            $EnabledJobs = Get-VBRJob | Where {$_.IsScheduleEnabled -eq $True}
            $EnabledCount = ($EnabledJobs | measure).Count

        }

    }#End Try
    
    Catch{
      Write-LogError -LogPath $sLogFile -ExitGracefully -Message "$_.Exception"
    }#End Catch
  }#End Process
  
  End{
    If($?){
      Write-LogInfo -LogPath $sLogFile -ToScreen -Message "All jobs have been disabled."
      Write-LogInfo -LogPath $sLogFile -ToScreen -Message " "
    }#End End
  }
}#End Function Disable-VBRJob-All
