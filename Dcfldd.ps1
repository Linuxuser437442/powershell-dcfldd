Param($Global:TargetDir = '', $Global:CaseFolder='', $Global:TempFolder='')

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

Function Menu {
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
    $Selection = ''
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
    $options= "FILE", "FOLDER", "DISK"

    if ($Selection -eq ''){
        $Selection = Menu $options "Are You Copying FILE, FOLDER, OR DISK?"
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

Function Get-Folder
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


Function Get-File
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
#CASE CREATION
###############################################################################
Function CaseCreation{

    $CaseName = Read-Host "Please name your case"        
    return $CaseName
}

###############################################################################
#DCLFDD COPY FILE
###############################################################################
Function dclfdd-file{
    
    Param([Parameter(Mandatory=$True,Position=1)]
          [string]$CurrentDir,
          [Parameter(Mandatory=$True,Position=2)]
          [String]$HashAlgorithm,
          [Parameter(Mandatory=$True,Position=3)]
          [String]$Source,
          [Parameter(Mandatory=$True,Position=4)]
          [String]$Destination,
          [Parameter(Mandatory=$False,Position=5)]
          [String]$HashLog="default.hash")
    
    cd $CurrentDir
    .\dcfldd.exe sizeprobe=if hash=$HashAlgorithm if=$Source of=$Destination hashlog=$HashLog
    
}

###############################################################################
#DCLFDD COPY FOLDER
###############################################################################
Function dclfdd-folder{

    param([Parameter(Mandatory=$True)]
          [String]$SourceFolder
          )

    process{
        
        $items = Get-ChildItem -Path $SourceFolder
        foreach ($item in $items){
            if(Test-Path $item.FullName -PathType Container){
                
                ValidateDest $item.FullName
                dclfdd-folder $item.FullName

            }else{                
                
                $Filename = $item.Name
				$Source = $SourceFolder + "\" + $Filename
                
                #Return destination path
                ValidateDest $SourceFolder
				$Destination = $Global:TempFolder + "\$Filename"
				$HashLog = $Global:TempFolder + "\$Filename.hash"

                #EXECUTE DCLFDD WITH ALL PARAMETERS LOADED                				
				dclfdd-file $CurrentDir $HashAlgorithm $Source $Destination $HashLog

            }
        }

    }
}

###############################################################################
#VALIDATE DESTINATION
#
#This function will validate the existence of destination folder
#If it is not existed, create a destination then return the path
###############################################################################

Function ValidateDest{
    param([Parameter(Mandatory=$True,Position=1)]
          [String]$SourceDir
          )

    process{        
        
        $FolderName = Get-Item $Global:TargetDir | Select-Object -ExpandProperty Name
        $StartIndex = $Global:TargetDir.LastIndexOf("\") + $FolderName.Length + 1
        
        $TempPath = $SourceDir.Substring($StartIndex, $SourceDir.Length - $StartIndex)

        $DestinationDir = $Global:CaseFolder + "\$TempPath"
        if(!(Test-Path $DestinationDir -PathType Container)){
            MKDIR $DestinationDir
        }

        $Global:TempFolder = $DestinationDir

    }

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
          [String]$Filename='',
          [String]$CaseName = ''
          )

    Process{
        
        #CREATE CASE PROFILE
        $CaseName = CaseCreation
        $CasePath = $CurrentDir + "\Cases\$CaseName"
        MKDIR $CasePath
        
        #START MAIN MENU
        $Selection = MainMenu
            

        If($Selection -eq "COPY FILES/FOLDER"){
        
            #CHOOSE HASH ALGORITHM
            $HashAlgorithm= HashAlgorithm


            #DECIDE WHETHER IT IS FILE OR FOLDER
            $Source = File/Folder


            #CONDITION FOR EACH OPTION
            if($Source -eq "FILE"){

                $Source = Get-File($CurrentDir)
                $Source = $Source.Substring(1)                
                $Filename = Get-Item $Source | Select-Object -ExpandProperty Name				
				$Destination = $CurrentDir + "\Cases\$CaseName\$Filename"
				$HashLog = $CurrentDir + "\Cases\$CaseName\$Filename.hash"

                #EXECUTE DCLFDD WITH ALL PARAMETERS LOADED                				
				dclfdd-file $CurrentDir $HashAlgorithm $Source $Destination $HashLog

            }elseif($Source -eq "FOLDER"){
                
                $Source = Get-Folder
                $SourceFolder = $Source.SubString(0,$Source.IndexOf(" System"))
                $FolderName = Get-Item $SourceFolder | Select-Object -ExpandProperty Name
				$Global:TargetDir = $SourceFolder #This variable is used for recrusion purpose.
                $Global:CaseFolder = $CurrentDir + "\Cases\$CaseName\$FolderName"
                MKDIR $Global:CaseFolder
                dclfdd-folder $SourceFolder            
                
            }else{
                
                $Drive = Read-Host "Please type which drive you want to image (e.g. C or E)"
                $DriveFormat = "\\.\" + $Drive.ToLower() + ":"
                $Destination = $CasePath + "\$Drive.dd"
                $HashLog = $CurrentDir + "\Cases\$CaseName\$Drive.hash"

                dclfdd-file $CurrentDir $HashAlgorithm $DriveFormat $Destination $HashLog


            }

        }
    }
}

MainProcess(Split-Path $MyInvocation.MyCommand.Path)