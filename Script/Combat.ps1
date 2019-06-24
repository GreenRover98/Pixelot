function Enter-Combat {
    #Creates all necessary variables and calls player1's turn (Note: Player1Position/Player2Position can be amalgamated or discarded and replaced with Positions)
    $global:Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Player1Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Player2Tools = import-csv -Path '..\Data\Tool.csv'
    $global:Verbs = import-csv -path '..\Data\Verb.csv'
    $global:Positions = import-csv -path '..\Data\Position.csv'
    $global:Player1Position = import-csv -path '..\Data\Position.csv'
    $global:Player2Position = import-csv -path '..\Data\Position.csv'

    New-Item -ItemType File -Path '..\Data\Active\Player1CurrentPosition.csv'
    New-Item -ItemType file -Path '..\Data\Active\Player2CurrentPosition.csv'
    $text = 'Position_ID,Position_Name' | Out-File -FilePath '..\Data\Active\Player1CurrentPosition.csv'
    $text = 'Position_ID,Position_Name' | Out-File -FilePath '..\Data\Active\Player2CurrentPosition.csv'
    $text = '1,Center' | out-file -Append -FilePath '..\Data\Active\Player1CurrentPosition.csv'
    $text = '1,Center' | out-file -Append -FilePath '..\Data\Active\Player2CurrentPosition.csv'

    $global:Player1CurrentPos = import-csv -path '..\Data\Active\Player1CurrentPosition.csv'
    $global:Player2CurrentPos = Import-csv -Path '..\Data\Active\Player2CurrentPosition.csv'
    #$global:Directions = import-csv -path '..\Direction.csv'
    
    Player1-Turn
}

function Player1-Turn{
    $Player1Command = read-host "Player1, what would you like to do?"
    Parse-Command -PlayerCommand $Player1Command
    Validate-Command -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool -RestartCommand "Player1-Turn"
    Assess-CmdAvailability -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool -CurrentPlayer "Player1" -OpponentPlayer "Player2" -RestartCommand "Player1-Turn"
    echo "Valid"
    Execute-Command -Verb $Current_Verb -Target $Current_Target -Tool $Current_Tool
    #Assess next player's viability Assess-PlayerViabilitity -Player "Player2"
    Player2-Turn
}

function Player2-Turn{
    read-host "Player2, what would you like to do?"
    Player1-Turn
}

function Parse-Command ($PlayerCommand) {

    #Acquire Verb
    [regex]$Regex = '(?i).*(?= their)'
    $global:Current_Verb = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}

    [regex]$Regex = '(?i)(?<=their ).*(?= with)'
    $global:Current_Target = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}

    [regex]$Regex = '(?i)(?<=with ).*'
    $global:Current_tool = $Regex.Matches("$PlayerCommand") | foreach-object {echo $_.Value}


}

function validate-command ($Verb,$Target,$Tool,$RestartCommand){
    $Result = 5

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

    switch ($Result){
        1 {}
        2 {echo "Invalid Tool"; Invoke-Expression $RestartCommand}
        3 {echo "Invalid Target"; Invoke-Expression $RestartCommand}
        4 {Echo "Invalid Verb"; Invoke-Expression $RestartCommand}
        5 {Echo "Invalid Command"; Invoke-Expression $RestartCommand}
    }
}

function Assess-CmdAvailability ($Verb,$Target,$Tool,$CurrentPlayer,$OpponentPlayer,$RestartCommand){
    $ToolAv = $Null
    $TargetAv = $Null
    $VerbAv = $Null
    $VerbList = $Null
    $Verb_ToolsValid = $Null
    $Verb_PositionValid = $Null
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

    #Assess if Target is already 0
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

    #Depending on the result of the tools parse above, will read the tools column and return whether or not the current tool is valid.
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