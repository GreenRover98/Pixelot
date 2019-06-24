#PIXELOT
#A PowerShell Combat System & RPG
#
#Copyright © 2019 GreenRover98
#=============================
#
#To-Do Lists
#===========
#List of necessary improvements for workable code:
#    -Complete the Assess-CmdAvailability function
#       -Function must include:
#            -Match if the size of the target is compatible with the attempted action.
#            -Match if the opponent's position is compatible with the attempted action.
#    -Create the Execute-Command function
#    -Create a more comprehensive list of possible actions (verbs)
#    -Write all effects to the correct player (should be included in Execute-Command)
#
#List of non-essential improvements for easier playability:
#    -More specific errors
#    -Help Screen
#    -Allow commands to be more vague
#    -'Result' echo statements
#
#List of Code optimization improvements:
#    -Easier parsing ability for the verb assessment (Assess-CmdAvailability)
#    -Clean up unnecessary or duplicate variables
#    -More segregation of different function functions?
#
#Readibility Information
#=======================
#This is a hand-to-hand combat game.
#  Tools - refers to the part of the player character's body that will be used to perform the action.***
#  Target - refers to the part of the opponent player character's body that will be performed on.***
#  Verb - refers to the action that the tool will be performing on the target.***
#
#Any necessary CSVs are included in the Data folder. This script has been designed with the following folder structure in mind:
#
#\Script\*All scripts*
#\Data\Active\*All CSV files that will be modified/created by PS script
#\Data\*All CSV files that will be read-only*
#
#***This is the least-sexual way I could find to put it. Probably there's a better way, but this is what I've got. Please spare me.


function Enter-Combat {
    #Creates all necessary variables and calls player1's turn (Note: Player1Position/Player2Position can be amalgamated or discarded and replaced with Positions)

    #Imports all CSV files into object variables. The Player1 and Player2 tools variables will be written to.
    $global:Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Player1Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Player2Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Verbs = import-csv -path '..\Data\Verb.csv'
    $global:Positions = import-csv -path '..\Data\Position.csv'
    $global:Player1Position = import-csv -path '..\Data\Position.csv'
    $global:Player2Position = import-csv -path '..\Data\Position.csv'

    #Creates files for the Player 1 and Player 2 current positions
    New-Item -ItemType File -Path '..\Data\Active\Player1CurrentPosition.csv'
    New-Item -ItemType file -Path '..\Data\Active\Player2CurrentPosition.csv'
    $text = 'Position_ID,Position_Name' | Out-File -FilePath '..\Data\Active\Player1CurrentPosition.csv'
    $text = 'Position_ID,Position_Name' | Out-File -FilePath '..\Data\Active\Player2CurrentPosition.csv'
    $text = '1,Center' | out-file -Append -FilePath '..\Data\Active\Player1CurrentPosition.csv'
    $text = '1,Center' | out-file -Append -FilePath '..\Data\Active\Player2CurrentPosition.csv'

    #Creates variables for the player 1 and player 2 current position files
    $global:Player1CurrentPos = import-csv -path '..\Data\Active\Player1CurrentPosition.csv'
    $global:Player2CurrentPos = Import-csv -Path '..\Data\Active\Player2CurrentPosition.csv'
    #$global:Directions = import-csv -path '..\Direction.csv'
    
    #Launches the Player1-Turn function
    Player1-Turn
}

function Player1-Turn{
    #Launches all of the functions necessary to perform a command in sequential order after taking the command input from the user.
    $Player1Command = read-host "Player1, what would you like to do?"

    #Takes the user's input and separates the keywords from it based on "their" and "with". Assigns these keywords to variables.
    #IE separates "asdf", "qwer", and "yuio" from "asdf their qwer with yuio"
    Parse-Command -PlayerCommand $Player1Command
    
    #Uses the keywords taken from the Parse-Command function and checks if each keyword is on the tool and verb lists. Assigns the keywords to
    # variables if they are valid keywords.
    Validate-Command -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool -RestartCommand "Player1-Turn"

    #Now that the keywords are verified valid, the Assess-CmdAvailability function determines if the action that the player wants to take can
    # be taken with those tools/verbs/targets.
    Assess-CmdAvailability -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool -CurrentPlayer "Player1" -OpponentPlayer "Player2" -RestartCommand "Player1-Turn"
    
    #This is the furthest that has been coded so far.
    echo "Valid"
    
    #Executes the command
    Execute-Command -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool
    #??? - Assess next player's viability Assess-PlayerViabilitity -Player "Player2" MAYBE

    #Calls Player2's turn
    Player2-Turn
}

function Player2-Turn{
    read-host "Player2, what would you like to do?"
    Player1-Turn
}

function Parse-Command ($PlayerCommand) {
   
    #Acquire Verb from user input
    [regex]$Regex = '(?i).*(?= their)'
    $global:Current_Verb = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}

    #Acquire Target from user input
    [regex]$Regex = '(?i)(?<=their ).*(?= with)'
    $global:Current_Target = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}

    #Acquire Tool from user input
    [regex]$Regex = '(?i)(?<=with ).*'
    $global:Current_tool = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}


}

function validate-command ($Verb,$Target,$Tool,$RestartCommand){
    
    #The result variable is established here in error state. If $Result isn't changed the command will not be verified.
    $Result = 5

    #Checks the input variables against the appropriate columns in the appropriate global variables to see if there's
    # a match. If there's not a match then the $Result variable is changed or left alone to reflect this.
    $Verbs | ForEach-Object {if ($Verb -eq $_.Name){

            $Tools | Foreach-object {if ($Target -eq $_.Name){

                    $Tools | foreach-object {if ($Tool -eq $_.Name){
                            $Result = 1
                        } elseif ($Result -gt 1){$Result = 2}
                    }
                } elseif ($Result -gt 2){$Result = 3}
            }
        } elseif ($Result -eq 5){$Result = 5} elseif ($Result -gt 3){$Result -eq 4}
    }

    #Uses the $Result variable to determine if nothing happens (valid command) or if an error is processed (invalid 
    #command). A value of 1 is a valid command.
    switch ($Result){
        1 {}
        2 {echo "Invalid Tool"; Invoke-Expression $RestartCommand}
        3 {echo "Invalid Target"; Invoke-Expression $RestartCommand}
        4 {Echo "Invalid Verb"; Invoke-Expression $RestartCommand}
        5 {Echo "Invalid Command"; Invoke-Expression $RestartCommand}
    }
}

function Assess-CmdAvailability ($Verb,$Target,$Tool,$CurrentPlayer,$OpponentPlayer,$RestartCommand){
    #Sets all variables to Null
    $ToolAv = $Null
    $TargetAv = $Null
    $VerbAv = $Null
    $VerbList = $Null
    $Verb_ToolsValid = $Null
    $Verb_PositionValid = $Null
    
    #Sets variables depending on which player was fed to this function
    switch ($CurrentPlayer) {
        "Player1" {$CurPosition = $global:Player1Position; $CurTools = $global:Player1Tools; $CurrentPosition = $global:Player1CurrentPos}
        "Player2" {$CurPosition = $global:Player2Position; $CurTools = $global:Player2Tools; $CurrentPosition = $global:Player2CurrentPos}
    }

    switch ($OpponentPlayer) {
        "Player1" {$TargetPosition = $Global:Player1Position; $TargetTools = $global:Player1Tools; $TargetCurPosition = $global:Player1CurrentPos}
        "Player2" {$TargetPosition = $Global:Player2Position; $TargetTools = $global:Player2Tools; $TargetCurPosition = $global:Player2CurrentPos}
    }

    #Assess if tool has enough HP
    $CurTools | foreach-object {
        if ($Tool -eq $_.Name) {
            if ($_.HP -gt 0) {$ToolAv = 1;$CurrentTool = $_}
        }
    }

    #Assess if Target is already 0 HP
    $TargetTools | foreach-object {
        if ($Target -eq $_.Name) {
            if ($_.HP -le 0) {$TargetAv = $Null;$Current_Target = $_} else {$TargetAv = 1}
        }
    }

    #Parses the "tools" column for this verb. Used to find if tools is equal to a CS value, Astrisk (all), or a single value.
    $Verbs | foreach-object {
        if ($Verb -eq $_.Name){
            $li = $_.Tools
            switch -regex ($li){
                "," {$ValidTools = $li.split(",");$VerbList = 1}
                "\*" {$ValidTools = "Everything";$VerbList = 2}
                default {$ValidTools = $li;$VerbList = $Null}
            }
         }
    }

    #Depending on the result of the tools parse above, will read the tools column and return whether or not the current tool 
    # is valid based on if the Selected tool matches the value in the current action's tool column.
    if ($VerbList -eq 2){
        if ($ToolAv -eq 1){$Verb_ToolsValid = 1}
    } elseif ($VerbList -eq 1) {
        $ValidTools | ForEach-Object {
            if ($CurrentTool.ID -eq $_){$Verb_ToolsValid = 1}
        }
    } else {if ($CurrentTool.ID -eq $ValidTools){$Verb_ToolsValid = 1}}



    #Parses the "Necessary_PriorPos" column for this verb. Used to find if Prior Position is equal to a CS value, Astrisk (all), or a single value.
    $Verbs | foreach-object {
        if ($Verb -eq $_.Name){
            $li = $_.Necessary_PriorPos
            switch -regex ($li){
                "," {$ValidPosition = $li.split(",");$PositionList = 1}
                "\*" {$ValidPosition = "Everything";$PositionList = 2}
                default {$ValidPosition = $_;$PositionList = $Null}
            }
         }
    }

    #Depending on the results of the priorpos parse above, will read the necessary_priorpos column and return whether or not the current verb is valid.
    if ($PositionList -eq 2){
        $Verb_PositionValid = 1
    } elseif ($PositionList -eq 1) {
        $ValidPosition | ForEach-Object {
            if ($CurrentPosition.ID -eq $_){$Verb_PositionValid = 1}
        }
    } else {if ($CurrentPosition.ID -eq $ValidPosition){$Verb_PositionValid = 1}}

    if ($Verb_PositionValid){if ($Verb_ToolsValid){$VerbAv = 1}else{echo "The tool won't work with that verb."}}else{echo "The verb won't work in that position."}

    #If the tool, target, and verb are available, the following will do nothing and return to wherever it was called from. 
    #Otherwise it will read out an error and restart the calling function.
    #=====================================================================
    if ($ToolAv){
        if ($TargetAv){
            if ($VerbAv){
            }else{echo "The verb you wanted to use is not available.";Invoke-Expression $RestartCommand}
        }else{echo "The Target that you wanted to act on is not available.";Invoke-Expression $RestartCommand}
    }else {echo "The Tool that you wanted to act on is not available.";Invoke-Expression $RestartCommand}
}

#This function is used to assign the "CurrentPosDetails" variable to the row in the Position.csv that matches the ID given to the function
function Get-PositionFromID ($PositionID){
    $Positions | foreach-object {
        if ($_.ID -eq $PositionID){
            echo $_
        }
    }
}