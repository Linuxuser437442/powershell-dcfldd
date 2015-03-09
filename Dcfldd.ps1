###############################################################################
# MENU FUNCTION
###############################################################################
Function DrawMenu {
    ## supportfunction to the Menu function below
    param ($menuItems, $menuPosition, $menuTitle)
    $fcolor = $host.UI.RawUI.ForegroundColor
    $bcolor = $host.UI.RawUI.BackgroundColor
    $l = $menuItems.length + 1
    cls
    $menuwidth = $menuTitle.length + 4
    Write-Host "`t" -NoNewLine
    Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
    Write-Host "`t" -NoNewLine
    Write-Host "* $menuTitle *" -fore $fcolor -back $bcolor
    Write-Host "`t" -NoNewLine
    Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
    Write-Host ""
    Write-debug "L: $l MenuItems: $menuItems MenuPosition: $menuposition"
    for ($i = 0; $i -le $l;$i++) {
        Write-Host "`t" -NoNewLine
        if ($i -eq $menuPosition) {
            Write-Host "$($menuItems[$i])" -fore $bcolor -back $fcolor
        } else {
            Write-Host "$($menuItems[$i])" -fore $fcolor -back $bcolor
        }
    }
}

function Menu {
    ## Generate a small "DOS-like" menu.
    ## Choose a menuitem using up and down arrows, select by pressing ENTER
    param ([array]$menuItems, $menuTitle = "MENU")
    $vkeycode = 0
    $pos = 0
    DrawMenu $menuItems $pos $menuTitle
    While ($vkeycode -ne 13) {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.virtualkeycode
        Write-host "$($press.character)" -NoNewLine
        If ($vkeycode -eq 38) {$pos--}
        If ($vkeycode -eq 40) {$pos++}
        if ($pos -lt 0) {$pos = 0}
        if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
        DrawMenu $menuItems $pos $menuTitle
    }
    Write-Output $($menuItems[$pos])
}

###############################################################################
#Options Selection
###############################################################################
Function MainMenu{   
    clear
    $options=@()
    $options = "COPY FILES/FOLDER", "SECURLY WIPE DISK" 
   
    
    if ($Selection -eq ''){
        $Selection = Menu $options "Choose an option here"
    }

    return $Selection
}

Function File/Folder{
    
    $Selection=''
    $options=@()
    $options= "FILE", "FOLDER"

    if ($Selection -eq ''){
        $Selection = Menu $options "Are You Copying FILE or FOLDER?"
    }

    return $Selection

}

Function HashAlgorithm{
    
    $Selection=''
    $options=@()
    $options= "md5", "md5,sha1", "md5,sha1,sha256", "md5,sha1,sha256,sha384", "md5,sha1,sha256,sha384,sha512"

    if ($Selection -eq ''){
        $Selection = Menu $options "Choose some hash algorithms"
    }

    return $Selection
}

###############################################################################
#DIALOG TO FIND PATH
###############################################################################

Function Get-Folder() 
{
    param([String]$path = 0,
          [String]$message = 'Select a folder'
    )

    process{
        $object = New-Object -comObject Shell.Application  
     
        $folder = $object.BrowseForFolder(0, $message, 0, $path) 
        if ($folder -ne $null) {
            $folder.self.Path
            Write-Output $folder
        }
        return $folder
    }


}#end function Get-Folder


Function Get-File()
{   
    param([String]$initialDirectory,
          [String]$title = 'Select a file'
    )
    
    begin {}
    
    process{

        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog 
        $OpenFileDialog.initialDirectory = $initialDirectory
        $OpenFileDialog.title = $title
        $OpenFileDialog.DefaultExt
        $OpenFileDialog.filter = "All files (*.*)| *.*"
        $OpenFileDialog.ShowDialog() | Out-Null
        $OpenFileDialog.filename

    }
} #end function Get-FileName


###############################################################################
#DCLFDD FUNCTION
###############################################################################
Function dclfdd{
    
    Param([String]$HashAlgorithm,
          [String]$Source,
          [String]$Destination,
          [String]$HashLog)

    #.\dcfldd.exe sizeprobe=if hash=$HashAlgorithm if=$Source of=$Destination hashlog=$HashLog
    
}

###############################################################################
#MAIN PROCESS
###############################################################################

Function MainProcess{
    
    
    Param([Parameter(Mandatory=$True,Position=1)]
          [string]$CurrentDir,
          [String]$Selection = '',
          [String]$HashAlgorith = '',
          [String]$Source='',
          [String]$Filename=''
          )

    Process{
    
        
        $Selection = MainMenu     

        If($Selection -eq "COPY FILES/FOLDER"){
        
            #GET CURRENT DIR
            $CurrentDir=Split-Path $MyInvocation.MyCommand.Path               
            
        
            #CHOOSE HASH ALGORITHM
            $HashAlgorithm= HashAlgorithm


            #DECIDE WHETHER IT IS FILE OR FOLDER
            $Source = File/Folder


            #CHOOSE SOURCE PATH
            if($Source -eq "FILE"){

                $Source = Get-File($CurrentDir)
                $Source = $Source.Substring(1)                
                $Filename = Get-Item $Source | Select-Object -ExpandProperty Name

            }else{
            
                $Source = Get-Folder
                $Source = $Source.SubString(0,$Source.IndexOf(" System"))
                $Filename = Get-Item $Source | Select-Object -ExpandProperty Name
            }

        
            #EXECUTE DCLFDD WITH ALL PARAMETERS LOADED
            $Destination = $CurrentDir + "\Testcase\$Filename"
            $HashLog = $CurrentDir + "\Testcase\$Filename.txt"
            
            #cd $CurrentDir
            #dclfdd($HashAlgorith, $Source, $Destination, $HashLog)

            cd $CurrentDir #Change directory to where dcfldd located, for some reasons, Invoke-Expression doesn't work as exptect
            .\dcfldd.exe sizeprobe=if hash=$HashAlgorithm if=$Source of=$Destination hashlog=$HashLog       

        }
    }
}

MainProcess(Split-Path $MyInvocation.MyCommand.Path)