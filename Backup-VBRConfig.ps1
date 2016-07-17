Function Backup-VBRConfig{  
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$False,Position=1)]
        [string]$OutputPath
	)
  
  Begin
  {
    Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Backing up the current config."
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
                        Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Backing up the configuration."
                        $RepositoryPath = Get-VBRConfigurationBackupJob | select -ExpandProperty repository | select -ExpandProperty Path
                        $BackupPath = $RepositoryPath + "\VeeamConfigBackup"    
        
                        Start-VBRConfigurationBackupJob -Verbose
                    } 
                    else
                    {
                        Write-LogInfo -LogPath $sLogFile -ToScreen -Message "A Configuration backup is already running. Waiting..."
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
                     Write-LogError -LogPath $sLogFile -Message "There was an error backing up the config."
                     Write-LogError -LogPath $sLogFile -ExitGracefully -Message "The latest backup file was created on $($Files[0].LastWriteTime)"
                }
                #Copy latest backup file
                if ($OutputPath) 
                {
                    try
                    {
                        #Check to make sure that $OutputPath exists if not create.
                        if(-not (Test-Path $OutputPath))
                        {
                            New-Item -ItemType Directory -Force -Path $ConfigPath | Out-Null
                        }
                        copy $Files[0] $OutputPath -Force
                    }
                    catch
                    {
                        Write-LogError -LogPath $sLogFile -ExitGracefully -Message "There was an error copying the config. $Error[0]"
                    }    
                }
                }
                Catch
                {
                    Write-LogError -LogPath $sLogFile -ExitGracefully -Message "There was an error with the config backup. $($Error[0])"
                }
            }
            else
            {
                #Not sure how to verify this in pre 9
                try
                {
                    Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Backing up configuration."
                    Export-VBRConfiguration | Out-Null
                }
                catch
                {
                    Write-LogError -LogPath $sLogFile -ExitGracefully -Message "There was an error with the config backup. $($Error[0])"
                }
                Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Config has been backed up."
            }
        }#End Try
    
        Catch{
           Write-LogError -LogPath $sLogFile -ExitGracefully -Message "$_.Exception"
          Break
        }#End Catch
    }#End Process
  
  End{
    If($?){
      Write-LogInfo -LogPath $sLogFile -ToScreen -Message "Completed Successfully."
      Write-LogInfo -LogPath $sLogFile -ToScreen -Message " "
    }#End End
  }
}#End Function Backup-VBRConfig
