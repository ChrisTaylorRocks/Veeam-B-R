Function Uninstall-VBRAll{  
    [CmdletBinding()]
    Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "Uninstalling Veeam Backup & Replication."
  }#End Begin
  
  Process
  {
    Try
    {
        Stop-Process -Name 'Veeam.Backup.Shell' -Force -ErrorAction SilentlyContinue
        $APPS = Get-WmiObject -Class win32_product -Filter "vendor LIKE 'Veeam%' AND NOT name LIKE 'Veeam ONE%'" 
        while ($($APPS.count) -gt 0)
        {
            #Start-Process -FilePath msiexec.exe -ArgumentList "/x {A9DA3FE1-997F-4956-B43D-6B67610E35E6} /qn"
            #Start-Process -FilePath msiexec.exe -ArgumentList "/x {52EC4366-FF56-4B08-817F-7797C72397A0} /qn"

            foreach($APP in $APPs)
            {
                $AppGUID = $APP.properties["IdentifyingNumber"].value.toString()
                $Arguments = "/L*v `"$($sLogPath)\$($APP.Name)Uninstall.log`" /qn /x $AppGUID"
                Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait
            }
            sleep 1
            $APPS = Get-WmiObject -Class win32_product -Filter "vendor LIKE 'Veeam%' AND NOT name LIKE 'Veeam ONE%'" 
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
}#End Function Uninstall-VBRAll
