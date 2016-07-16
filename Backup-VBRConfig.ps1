Function Backup-VBRConfig{  
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$False,Position=1)]
        [string]$OutputPath
	)
  
  Begin
  {
    Log-Write -LogPath $sLogFile -LineValue "Backing up the current config."
  }#End Begin
  
    Process{
        Try{
            #Check to see what backup command is avaliable.
            if (Get-Command Get-VBRConfigurationBackupJob -ErrorAction SilentlyContinue)
            {
                try
                {
                    #Check for a job that is already running.
                    $ConfigBackupJob = Get-VBRConfigurationBackupJob
                    if($ConfigBackupJob.LastState -eq 'Stopped')
                    {
                        #Run a backup
                        Write-Output "Backing up the configuration."
                        $RepositoryPath = Get-VBRConfigurationBackupJob | select -ExpandProperty repository | select -ExpandProperty Path
                        $BackupPath = $RepositoryPath + "\VeeamConfigBackup"    
        
                        Start-VBRConfigurationBackupJob -Verbose
                    } 
                    else
                    {
                        Write-Output "A Configuration backup is already running. Waiting..."
                        while($ConfigBackupJob.LastState -ne 'Stopped')
                        {
                            $ConfigBackupJob = Get-VBRConfigurationBackupJob
                            sleep 2
                        }
                    }        
        
                #Verify there is a new config
                $Files  = Get-ChildItem $BackupPath -Recurse -Include *.bco | sort $_.LastWriteTime -Descending
                if ($($Files[0].LastWriteTime) -lt $((Get-Date).AddMinutes(-10)))
                {
                    Write-Output "There was an error backing up the config."
                    Write-Output "The latest backup file was created on $($Files[0].LastWriteTime)"
                    break 

                }
                #Copy latest backup file
                if ($OutputPath) 
                {
                    try
                    {
                        copy $Files[0] $OutputPath -Force
                    }
                    catch
                    {
                        Write-Output "There was an error copying the config. $Error[0]"
                        break
                    }    
                }
                }
                Catch
                {
                    Write-Output "There was an error with the config backup. $($Error[0])"
                    break
                }
            }
            else
            {
                #Not sure how to verify this in pre 9
                try
                {
                    Write-Output "Backing up configuration."
                    Export-VBRConfiguration | Out-Null
                }
                catch
                {
                    Write-Output "There was an error with the config backup. $($Error[0])"
                    break
                }
                Write-Output "Config has been backed up."
            }
        }#End Try
    
        Catch{
          Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
          Break
        }#End Catch
    }#End Process
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }#End End
  }
}#End Function Backup-VBRConfig
