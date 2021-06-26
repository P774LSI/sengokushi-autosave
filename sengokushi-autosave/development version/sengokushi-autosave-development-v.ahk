; @name "Sengokushi AutoSave"
; @version "1.2.0.α3 / 20210627"
; @author "P-774LSI"
; @lisence "CC0"

/*
概要: 戦国史SE, 戦国史FEで「オートセーブ」・「クイックセーブ」を行うユーザー操作補助スクリプトです。
また拡張機能として「ワンクリック内政」・「足軽数が指定数以上の人物は最大まで徴兵する」・「軍団資産の数値ワンクリック入力」コマンドを提供します。
使用にはAutoHotkey（以下AHK） v1.1.31以上（ユニコード版）の導入が必要です（v2系は動作保証外）。
スクリプト実行中は、マウスのセンターボタン・サイドボタン1・2、キーボードのF2～F3およびF7～F12、Scroll Lockがゲーム用のキー割り当てに変更されます。
これらのホットキーは戦国史がアクティブな場合に限り、使用できます。非アクティブ化で自動的にオフになります。
Scroll Lock押下、もしくはタスクトレイのアイコンからもサスペンド（ホットキーの無効化）は切り替えできます。
各種設定は54行目から記述されています。

・オートセーブは戦国史がアクティブかつ、ユーザーが一定時間操作をしない場合に行われます。

・オートセーブ、クイックセーブは共通してセーブファイル名は「プレフィクス+スプリッタ文字+YYYYMMDD-HH24MISS」になります。
例えばデフォルトでは、「sengokushi 20210613-201706」のようになります。プレフィクス・スプリッタは変更可能ですが、
上書き保存時以外は日付時刻は強制付与されます。

・ワンクリック内政は、商業開発・新田開発・産業開発・鉄砲生産の4つを実装しています。不要なものはホットキーでoffにできます。

・テストは主に戦国史SE・Windows10下で行っています。環境によっては動作に問題が出る可能性があります。
動作が不正確な場合は141行目の【高度な設定】から`sleepDuration1`の値を増やすことで改善されるかもしれません。

・ホットキーの変更は642行目以降を書き換えてください。
http://ahkwiki.net/KeyList
http://ahkwiki.net/Hotkeys

---------------------------------------------------------------------------------------------------------------------
クイック・リファレンス

マウス
センターボタン: クイックセーブ。
サイドボタン2: 【内政フェイズ】ワンクリック内政。内政各サブウィンドウを開く前に押します。
              【軍備フェイズ】徴兵ウィンドウを開いた状態で押すと、足軽数が指定数以上の人物はすべて最大まで徴兵するします。動作中もう1度押すと中止します。
              【軍備フェイズ】軍団資産ウィンドウを開いた状態で押すと、資金供給・資金徴収・鉄砲支給の入力フォームに事前に定められた数値を入力します。動作中もう1度押すと鉄砲以外はさらに加算されます。
サイドボタン1: 【軍備フェイズ】徴兵ウィンドウを開き、人物または城を選択した状態で押すと、事前に指定された数の足軽または城兵を徴兵します。

キーボード
F2: オートセーブの有効/無効切り替え。
F3: 上書きセーブの有効/無効切り替え。
F7: ワンクリック内政の一括有効/無効切り替え。
F8: 商業開発の有効/無効切り替え。
F9: 新田開発の有効/無効切り替え。
F10: 産業開発の有効/無効切り替え。
F11: 鉄砲生産の有効/無効切り替え。
F12: セーブファイルフォルダを開く。
Scroll Lock: サスペンド（ホットキー無効化）の有効/無効の切り替え。

※キーボードのホットキーはF12以外はすべてブール値の切り替えを行うためのみに用意されています。これらの切り替えが不要な場合はすべて削除しても動作します。
*/

;-----------------------------------------------------------------------------------------------------------------------
; ユーザー設定項目
; =====【基本機能設定】=====

; [システム]
; スクリプトを先に起動した時に、戦国史も一緒に起動させるかどうかのブール値を指定します。
; この設定が`false`の場合、先に戦国史を起動しないとSE, FEの判定を行えないため、スクリプトが正しく動作しません。
isLaunchAppEnabled := true

; 戦国史の実行ファイルのフルパス。前記の戦国史の`isLaunchAppEnabled`（自動起動）が`true`の場合、ここにパスを指定します。
appPath := "C:\Program Files (x86)\SengokushiSE\戦国史SE.exe"

; 戦国史のセーブフォルダのフルパス。キーボードのF12で開きます。上SE、下FE。
;saveFolderPathSE := "C:\Program Files (x86)\SengokushiSE\SaveData"  ; 恐らくWindows7未満
saveFolderPathSE = %LOCALAPPDATA%\VirtualStore\Program Files (x86)\SengokushiSE\SaveData
saveFolderPathFE = %LOCALAPPDATA%\VirtualStore\Program Files (x86)\SengokushiFE\SaveData

; 戦国史が非アクティブになった際に自動でサスペンド（ホットキー無効化）をさせるかどうかのブール初期値を指定します。
; 頻繁にアクティブウィンドウを切り替える場合に便利ですが、タイマーが常駐監視するためわずかですがリソース消費が増えます。
isAutoSuspendEnabled := true


; [オートセーブ・クイックセーブ]
; オートセーブを有効化するかどうかのブール初期値を指定します。キーボードのF2で初期値から変更できます。
isAutoSaveEnabled := true

; オートセーブが発動するまでのマウス非操作時間（ミリ秒）。初期値300000（5分）。有効範囲：60000-4294967295
fireSaveDuration := 300000

; オートセーブ有効時、AHKを自動で一時停止（Pause）するまでのマウス非操作時間（ミリ秒）。初期値2時間。有効範囲：60000-4294967295
; 一時停止はタイマー類にのみ影響します。ホットキーは無効化されません。
firePauseDuration := fireSaveDuration * 24

; セーブファイル名の最初に付ける一意のプレフィクス（識別子）。
prefix := "sengokushi"

; セーブファイル名のプレフィクスと日付時刻の間に挿入されるスプリッタ1文字。
spliter := " "

; セーブファイル名のプレフィクスを最新の作成時刻を持つファイルから自動取得します。取得できなかった場合は`prefix`が適用されます。
; 例えば「小西 行長 関ヶ原」という名前のセーブデータが最新の場合、この設定が`true`かつ、`spliter`が半角スペースの場合は次回以降のスクリプトによるセーブは
; 「小西 YYYYMMDD-HH24MISS」となります。
isPrefixAutoDetectEnabled := true

; 上書きセーブするかどうかのブール値を指定します。`true`の場合、セーブファイル名は`prefix`のみが付与されます。切り替えのホットキーはF3。
isOverwrite := false





; =====【拡張機能設定】=====

; 拡張機能の有効/無効を切り替えます。
; この設定を`true`にすると、スクリプトに対してゲーム内から追加の情報を読み取る許可を与え、拡張機能の使用を可能にします。
; 具体的には「ワンクリック内政」・「指定数の足軽・城兵を徴兵する」・「足軽数が指定数以上の人物はすべて最大まで徴兵する」・「軍団資産の初期数値入力」の有効化です。
isLogical := true

; 現在内政フェイズかどうかを判断し、内政フェイズのカスタムユーザーコマンドを実行するための判断リストです。
; ユーザー作製シナリオの場合、内政フェイズのすべての単語が置換されている可能性があるため、リストの確認が必要です。サンプルシナリオでは不要です。
; 以下のリスト内の単語が1つでも内政コマンドに含まれているように、必要に応じてリストに追記を行います。
pendingList1 := ["新田開墾", "楽市楽座", "鉱山開発", "鉄砲生産", "商業整備", "産業整備"]


; [ワンクリック内政]
; ワンクリック内政を有効化するかどうかのブール初期値を指定します。キーボードのF7で初期値から変更できます。
; この値が`false`の場合、以降の内政個別設定内容に関係なく、ユーザー操作補助は無効化されます。
isAssistDomesticAffairsEnabled := true

; 「ワンクリック内政」に商業開発を含めるかどうかのブール初期値を指定します。ホットキーはF8。
isCommerceEnabled := true

; 「ワンクリック内政」に新田開発を含めるかどうかのブール初期値を指定します。ホットキーはF9。
isDevelopmentNewFieldsEnabled := true

; 「ワンクリック内政」に産業（鉱山）開発を含めるかどうかのブール初期値を指定します。ホットキーはF10。
isIndustriesEnabled := true

; 「ワンクリック内政」に鉄砲生産を含めるかどうかのブール初期値を指定します。ホットキーはF11。
isMatchlocksProductionEnabled := true

; 「ワンクリック内政」時に資金が以下の数値を下回る場合は新田開墾と鉄砲購入を行いません。
fundsLimit := 10000


; [指定数の足軽・城兵を徴兵する]
; 選択した人物に対して「指定数の足軽・城兵を徴兵する」コマンドを実行した際、以下の回数だけ足軽スピンをクリックします。例えば「兵最小単位」が10のシナリオで50と設定された場合、500人を徴兵します。
draftForGeneralSpinClicks := 85

; 選択した城に対して「指定数の足軽・城兵を徴兵する」コマンドを実行した際、以下の回数だけ守備兵スピンをクリックします。
draftForDefenderSpinClicks := 25

; 選択した城に対して「指定数の足軽・城兵を徴兵する」コマンドを実行した際に徴兵された城兵数から「兵最小単位」を推測し、次回以降の同コマンド実行時に城兵数が1回あたりの徴兵数の倍数になるように調整を行います。
; 例えば城兵数が700の城に対して500が一度に徴兵される設定だった場合、徴兵すると1,200ではなく、500の倍数である1,000になるように調整が行われます。
isDefenderDraftMultipleEnabled := true


; [足軽数が指定数以上の人物はすべて最大まで徴兵する]
; 「足軽数が指定数以上の人物はすべて最大まで徴兵する」コマンドを有効にする。
isCustomMaxDraftEnabled := true

; 「足軽数が指定数以上の人物はすべて最大まで徴兵する」コマンドは、この数値以上の足軽を抱える人物に対して実行されます。
targetNumberOfSoldiers := 4000

; 「足軽数が指定数以上の人物はすべて最大まで徴兵する」コマンドが実行中に、徴兵可能な足軽が以下の数値を下回った場合はコマンドを中止します。
draftRemainLimit := 3000


; [軍団資産の初期数値入力]
; 「軍団資産の初期数値入力」コマンドを有効にする。
isCustomManageCorpsFundsEnabled := true

; 「軍団資産の初期数値入力」コマンド実行時の「軍団に資金を支給」左横の入力ボックスに入力する数値を指定します。
; 数値はコマンドが実行されるたびに増加します。例: 30000 -> 60000 -> 90000 -> ...
paymentAmount := 50000

; 「軍団資産の初期数値入力」コマンド実行時の「軍団から資金を徴収」左横の入力ボックスに入力する数値を指定します。
; 数値はコマンドが実行されるたびに増加します。例: 30000 -> 60000 -> 90000 -> ...
collectionAmount := 30000

; 「軍団資産の初期数値入力」コマンド実行時の「軍団に鉄砲を支給」左横の入力ボックスに入力する数値を指定します。
supplyMatchlockAmount := 0





; =====【高度な設定】=====
;
; スクリプトが行うキー操作間のスリープ時間を指定します（ミリ秒）。数値が少ないほどコマンドの実行速度が上がりますが、環境によっては動作しなくなります。
; デフォルトでは50ms（0.05秒）とかなり高速で操作を行うように設定されています。動作不具合やスクリプトテスト時はまずこの値を増やして検証してください。
sleepDuration1 := 550

; ダイアログやサブウィンドウの表示を待つためのスリープ時間を指定します（ミリ秒）。
sleepDuration2 := 500





; ここまでユーザー設定項目。
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Variables.

; Window processes.
appProcess =
appProcessSE = ahk_exe 戦国史SE.exe
appProcessFE = ahk_exe 戦国史FE.exe

; Only use save function.
saveFolderPath =
elapsedTime := 0
checkDuration := 60000

; About extensions.
mouseXPos := 0  ; Current mouse X pos.
mouseYPos := 0
mouseOffset1 := 180  ; Just about the center pos of a sub-window.
checkBoxColor := 0x808080  ; Gray. RGB, 128, 128, 128
;subWindowBGColor := 0xFFFFFF  ; RGB, 255, 255, 255  ; Not use current version.
subWindow1checkBoxXPos := 23  ; Client coordinate. Not window cordinate !
subWindow1checkBoxYPos := 94  ; Client coordinate. Not window cordinate !

funds := 0
oldFunds := 0
isDomesticAffairsPhase := false
domesticAffairsWord =
isAssistDomesticAffairsRunning := false
isCustomDraftRunning := false
isCustomManageCorpsFundsRunning := false
soldierUnit := 0
defenderdraftAmount := 0

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Script start.

#Persistent  ; Keeps a script.
#MaxThreadsPerHotkey 2  ; To define an abort key if same hot key pressed twice in a row.
CoordMode, Pixel , Client  ; For unifying the origin of color coordinates of an app's window that differ between each operating system.
CoordMode, Mouse , Client

; Set a process name and define the variable.
setProcess()

if (isLaunchAppEnabled && !appProcess) { ; To avoid double running of the app.
    Run, %appPath%
    Sleep 3000
    setProcess()
}

if (appProcess == appProcessSE) {
    saveFolderPath := saveFolderPathSE
} else {
    saveFolderPath := saveFolderPathFE
}

; Start Auto save.
SetTimer, observe, % (isAutoSaveEnabled ? checkDuration : "off")

; Auto suspend.
if (isAutoSuspendEnabled) {
    SetTimer, executeAutoSuspend, % (WinExist(appProcess) ? 2000 : "off")
}

; Change the default tray tooltip.
setTooltipText()

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Labels.

; Observe a state of user operations.
observe:
    if (isMovedCursor()) {
        if (isSaveComplete) {
            isSaveComplete := false
        }

        elapsedTime := 0
    } else {
        elapsedTime += checkDuration

        if (!isSaveComplete) {
            if (elapsedTime >= fireSaveDuration) {
                save()
            }
        }

        if (elapsedTime >= firePauseDuration) {
            Pause, on
        }
    }
    return

executeAutoSuspend:
    global appProcess

    if (!WinActive(appProcess)) {
        Suspend, on
    } else {
        Suspend, off
    }
    return

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Functions.

setProcess() {
    global appProcess
    global appProcessSE
    global appProcessFE

    if (WinExist(appProcessSE)) {
        appProcess := appProcessSE
    } else if (WinExist(appProcessFE)) {
        appProcess := appProcessFE
    } 
}

; Determines whether a mouse cursor has been moved.
isMovedCursor() {
    global mouseXPos
    global mouseYPos

    MouseGetPos, currentMouseXPos, currentMouseYPos

    if (currentMouseXPos == mouseXPos && currentMouseYPos == mouseYPos) {
        mouseXPos := currentMouseXPos
        mouseYPos := currentMouseYPos
        return false
    } else {
        mouseXPos := currentMouseXPos
        mouseYPos := currentMouseYPos
        return true
    }
}

save() {
    global prefix
    global spliter
    global appProcess
    global isSaveComplete
    global isPrefixAutoDetectEnabled
    global isOverwrite
    global sleepDuration2
    str =
    clipSaved =

    if (WinExist(appProcess) && WinActive(appProcess)) {
        ; Open the save dialog box.
        Sleep, sleepDuration2
        Send !{f}  ; Alt + f
        Sleep, 100
        Send {s}
        Sleep, sleepDuration2

        ; Create a file name, into clipboard and send to the dailog box.
        FormatTime, timeString,, yyyyMMdd-HHmmss

        if (isPrefixAutoDetectEnabled) {
            str := getPrefix()
            prefix := str ? str : prefix
        }

        clipSaved := ClipboardAll

        if (isOverwrite) {
            Clipboard = %prefix%
        } else {
            Clipboard = %prefix%%spliter%%timeString%
        }

        Send ^{v}  ; Ctrl + v
        Sleep, 150
        Send !{s}

        if (isOverwrite) {
            Sleep, sleepDuration2
            Send {y}
        }

        isSaveComplete := true
        Clipboard = %clipSaved%  ; Restore to the clipboard text.
        clipSaved =  ; Release the memory.
    }
}

getPrefix() {
    global saveFolderPath
    global spliter

    Loop, %saveFolderPath%\*.ssd, ,0
    {
        FileGetTime, Time, %A_LoopFileFullPath%, C  ; C: Creation-date.

        if (Time > latestTime) {
            latestTime := Time
            fileName := A_LoopFileName
        }
    }

    StringGetPos, strPos, fileName, %spliter%

    if strPos > 0
        StringLeft, str, fileName, strPos
        return str
}

getColor(x, y) {
    PixelGetColor, Color, x, y, RGB Alt
    return Color
}

; Get a text in active window of app and returns it.
getWindowText(index) {
    global appProcess

    WinGetText, strings, %appProcess%
    array := StrSplit(strings, "`n")
    return RTrim(array[index], "`r")
}

detectPhase() {
    global appProcess
    global pendingList1
    global funds
    global domesticAffairsWord
    
    personnelWord = 捕虜処遇
    armamentsWord = 徴兵
    strategyWord = 陸路移動
    departureWord = 陸路出陣
    isMatch :=

    WinGetText, strings, %appProcess%
    commandTexts := StrSplit(strings, "`r`n")

    ; Init process. Set keyword of domestic affairs.
    if (!domesticAffairsWord) {
        for i, cElement in commandTexts {
            for j, pElement in pendingList1 {
                if (cElement == pElement) { 
                    domesticAffairsWord := cElement
                    isMatch := true
                    break
                }
            }

            if (isMatch) {
                break
            }
        }
    }

    for i, cElement in commandTexts {
        if (cElement == domesticAffairsWord) {
            funds := commandTexts[20]  ; Set a funds.
            ;MsgBox, %funds%
            return 3
        } else if (cElement == armamentsWord) {
            return 2
        } else if (cElement == strategyWord) {
            return 4
        } else if (cElement == departureWord) {
            return 5
        } else if (cElement == personnelWord) {
            return 1
        }
    }
}

assistDomesticAffairs() {
    global appProcess
    global isAssistDomesticAffairsEnabled
    global funds
    global oldFunds
    global fundsLimit
    global sleepDuration1
    global isAssistDomesticAffairsRunning
    isPossibleProduce := false
    fundsIndex := 20
    
    if (!isAssistDomesticAffairsEnabled) {
        return
    }

    isAssistDomesticAffairsRunning := true

    if (funds != oldFunds) {  ; If two numbers are different, probably carried over to month.
        isPossibleProduce := true
    } else {
        isPossibleProduce := false
    }

    executeDomesticAffairs(1)  ; Commerce.
    executeDomesticAffairs(3)  ; Industries.

    if (funds > fundsLimit) {
        executeDomesticAffairs(2)  ; Development new fields.

        if (isPossibleProduce) {
            executeDomesticAffairs(7)  ; Produce matchlocks.
        }
    }

    Sleep, 100  ; Wait a few minutes until the main window is displayed.
    oldFunds := getWindowText(fundsIndex)  ; Get an updated funds from the main window.
    ;MsgBox, %oldFunds%
    isAssistDomesticAffairsRunning := false
}

executeDomesticAffairs(processType) {
    global isCommerceEnabled
    global isDevelopmentNewFieldsEnabled
    global isIndustriesEnabled
    global isMatchlocksProductionEnabled
    global sleepDuration1
    global sleepDuration2
    isPermission :=

    switch processType {
        case 1:
            isPermission := isCommerceEnabled ? true : false
        case 2:
            isPermission := isDevelopmentNewFieldsEnabled ? true : false
        case 3:
            isPermission := isIndustriesEnabled ? true : false
        case 7:
            isPermission := isMatchlocksProductionEnabled ? true : false
    }

    if (isPermission) {
        Send !{c}  ; Alt + c
        Sleep, sleepDuration1
        Send {%processType%}
        Sleep, sleepDuration2

        ; Call sub-window routines of domestic affairs.
        if (processType == 7) {
            subWindowRoutine2()  ; Produce matchlocks.
        } else {
            subWindowRoutine1()
        }
    }   
}

subWindowRoutine1() {
    global mouseOffset1
    global sleepDuration1
    global checkBoxColor
    global subWindow1checkBoxXPos
    global subWindow1checkBoxYPos
    global isLogical
    global oldFunds
    global funds

    if (getColor(subWindow1checkBoxXPos, subWindow1checkBoxYPos) == checkBoxColor) {  ; If exist a check box, execute the routine.
        Send {Tab}
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Enter}
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Enter}
        Sleep, sleepDuration1
        Send {Enter}
        Sleep, sleepDuration1
        MouseMove, % mouseOffset1, mouseOffset1  ; Mouse cursor keeps on the sub-window for close this.
        Sleep, sleepDuration1
        Click
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Enter}   
    } else {  ; Else cancel.
        Send {Tab}
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Tab}
        Sleep, sleepDuration1
        Send {Enter}
    }
}

subWindowRoutine2() {  ; Only use the produce matchlocks.
    global sleepDuration1
    global isLogical
    global oldFunds
    global funds

    Send {Tab}
    Sleep, sleepDuration1
    Send {Tab}
    Sleep, sleepDuration1
    Send {Tab}
    Sleep, sleepDuration1
    Send {Enter}
    Sleep, sleepDuration1
    Send {Tab}
    Sleep, sleepDuration1
    Send {Tab}
    Sleep, sleepDuration1
    Send {Enter}
}

fixedAmountDraft() {
    global sleepDuration1
    global draftForGeneralSpinClicks
    global draftForDefenderSpinClicks
    global isDefenderDraftMultipleEnabled
    global soldierUnit
    global defenderdraftAmount
    maxAllowed := 0
    actuallySpinClicks := 0

    MouseGetPos, currentMouseXPos, currentMouseYPos  ; 

    if (currentMouseYPos > 0 && currentMouseYPos < 330) {  ; Draft for general.
        MouseMove, 376, 299
        BlockInput, MouseMove
        Sleep, sleepDuration1
        Click, %draftForGeneralSpinClicks%
        BlockInput, MouseMoveOff
    } else if (currentMouseYPos > 299 && currentMouseYPos < 543) {  ; Defender draft.
        if (isDefenderDraftMultipleEnabled) {
            if (soldierUnit) {
                currentDefenders := getWindowText(22)
                maxAllowed := (Floor(currentDefenders / defenderdraftAmount) + 1) * defenderdraftAmount
                actuallySpinClicks := (maxAllowed - currentDefenders) / soldierUnit
                MouseMove, 303, 513
                BlockInput, MouseMove
                Sleep, sleepDuration1
                Click, %actuallySpinClicks%
                BlockInput, MouseMoveOff
            } else {
                oldDefenders := getWindowText(22)
                MouseMove, 303, 513
                BlockInput, MouseMove
                Sleep, sleepDuration1
                Click, %draftForDefenderSpinClicks%
                BlockInput, MouseMoveOff
                Sleep, sleepDuration1
                currentDefenders := getWindowText(22)
                soldierUnit := % (currentDefenders - oldDefenders) / draftForDefenderSpinClicks
                defenderdraftAmount := % soldierUnit * draftForDefenderSpinClicks
            }
        } else {
            MouseMove, 303, 513
            BlockInput, MouseMove
            Sleep, sleepDuration1
            Click, %draftForDefenderSpinClicks%
            BlockInput, MouseMoveOff
        }

    }
}

customMaxDraft() {
    global appProcess
    global targetNumberOfSoldiers
    global draftRemainLimit
    global isCustomMaxDraftEnabled
    global isCustomDraftRunning
    global sleepDuration1
    isPossibleDraft := true

    draftTexts :=
    ;cavalier :=  ; Not use.
    currentSoldiers :=  ; Array index is 16.
    remainingAmount := ; Array index is 18.
    isLimit := false
    lineHeight := 17
    firstLineYPos := 45
    soldiersXPos := 300
    lineNumber := 0
    assumptionMaxSoldiers := 999999
    draftCount := 0

    if (!isCustomMaxDraftEnabled) {
        return
    }

    isCustomDraftRunning := true
    WinGetText, strings, %appProcess%  ; Create a list of draft words.
    draftTexts := StrSplit(strings, "`r`n")
    currentSoldiers := draftTexts[16]
    MouseMove, %soldiersXPos%, 25  ; Position of ascending sort of are soldiers.
    Sleep, sleepDuration1
    Click  ; Sorted.
    Sleep, sleepDuration1

    While (isPossibleDraft && isCustomDraftRunning) {      
        lineNumber := draftCount > 11 ? 12 : draftCount  ; Line number of draft position. 13 is the max line number having max Y position in the list.
        MouseMove, %soldiersXPos%, % firstLineYPos + lineHeight * lineNumber
        Sleep, sleepDuration1 
        Click  ; Activate a line.
        Sleep, sleepDuration1
        currentSoldiers := getWindowText(16)
        remainingAmount := getWindowText(18)

        if (currentSoldiers == 0 || currentSoldiers < targetNumberOfSoldiers || remainingAmount < draftRemainLimit || draftCount > 500) {
            isPossibleDraft := false
        } else {
            if (currentSoldiers == assumptionMaxSoldiers) {
                Send {Down}  ; Scroll the list.
                Sleep, sleepDuration1
            } else {
                MouseMove, 410, 303  ; Cursor move to the max button.
                Sleep, sleepDuration1
                Click  ; Draft to max.
                Sleep, sleepDuration1
                Send {Down}  ; Scroll the list.
                Sleep, sleepDuration1
            }

            if (draftCount == 0) {
                assumptionMaxSoldiers := getWindowText(16)
            }

            draftCount++
        }
    }

    isCustomDraftRunning := false
}

customManageCorpsFunds() {
    global isCustomManageCorpsFundsEnabled
    global isCustomManageCorpsFundsRunning
    global sleepDuration1
    global paymentAmount
    global collectionAmount
    global supplyMatchlockAmount

    WinGetText, strings, %appProcess% 
    corpsFundsTexts := StrSplit(strings, "`r`n")
    currentPaymentAmount := corpsFundsTexts[8]
    currentCollectionAmount := corpsFundsTexts[9]
    currentSupplyMatchlockAmount := corpsFundsTexts[16]
    inputXPos := 352

    ;MsgBox, %currentPaymentAmount%

    if (!isCustomManageCorpsFundsEnabled) {
        return
    }

    isCustomManageCorpsFundsRunning := true
    clipSaved := ClipboardAll

    if (paymentAmount > 0) {
        MouseMove, %inputXPos%, 26
        Sleep, sleepDuration1
        Click
        Sleep, sleepDuration1
        Send {BS 10}  ; To remove all of the string in the input box.
        Sleep, sleepDuration1
        Clipboard = % currentPaymentAmount + paymentAmount
        Sleep, sleepDuration1
        Send ^{v}  ; Ctrl + v
        Sleep, % sleepDuration1
    }

    if (collectionAmount > 0) {
        MouseMove, %inputXPos%, 60
        Sleep, sleepDuration1
        Click
        Sleep, sleepDuration1
        Send {BS 10}
        Sleep, sleepDuration1
        Clipboard = % currentCollectionAmount + collectionAmount
        Sleep, sleepDuration1
        Send ^{v}
        Sleep, % sleepDuration1
    }
    
    if (supplyMatchlockAmount > 0 && currentSupplyMatchlockAmount == 0) {
        MouseMove, %inputXPos%, 94
        Sleep, sleepDuration1
        Click
        Sleep, sleepDuration1
        Send {BS 5}
        Sleep, sleepDuration1
        Clipboard = %supplyMatchlockAmount%
        Sleep, sleepDuration1
        Send ^{v}
        Sleep, % sleepDuration1
    }

    Clipboard = %clipSaved%  ; Restore to the clipboard text.
    clipSaved =  ; Release the memory.
    isCustomManageCorpsFundsRunning := false
}

setTooltipText() {
    global tooltipText
    global isAutoSaveEnabled
    global isOverwrite
    global isCommerceEnabled
    global isDevelopmentNewFieldsEnabled
    global isIndustriesEnabled
    global isMatchlocksProductionEnabled
    
    tooltipText = 自動保存: %isAutoSaveEnabled% `n上書き保存: %isOverwrite% `n商業: %isCommerceEnabled% `n新田開墾: %isDevelopmentNewFieldsEnabled% `n産業: %isIndustriesEnabled% `n鉄砲生産: %isMatchlocksProductionEnabled% 
    Menu, TRAY, Tip, %tooltipText%
}

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Hot keys.

f2::  ; Toggle the Auto save function on and off.
    isAutoSaveEnabled := !isAutoSaveEnabled
    SetTimer, observe, % (isAutoSaveEnabled ? checkDuration : "off")
    setTooltipText()
    return

f3::  ; Toggle the over write save on and off.
    isOverwrite := !isOverwrite
    setTooltipText()
    return

f7::  ; Toggle the command assist function on and off
    isAssistDomesticAffairsEnabled := !isAssistDomesticAffairsEnabled
    return

f8::  ; Toggle the commerce command on and off.
    isCommerceEnabled := !isCommerceEnabled
    setTooltipText()
    return

f9::  ; Toggle the development new fields command on and off.
    isDevelopmentNewFieldsEnabled := !isDevelopmentNewFieldsEnabled
    setTooltipText()
    return

f10::  ; Toggle the industries command on and off.
    isIndustriesEnabled := !isIndustriesEnabled
    setTooltipText()
    return

f11::  ; Toggle the matchlocks production command on and off.
    isMatchlocksProductionEnabled := !isMatchlocksProductionEnabled
    setTooltipText()
    return

f12::  ; Open the save data folder.
    Run, %saveFolderPath%
    return

ScrollLock:: ; Toggle the suspend key on and off.
    Suspend

    if (A_IsSuspended) {
        isAutoSuspendEnabled := true
        SetTimer, executeAutoSuspend, % (isAutoSuspendEnabled ? 2000 : "off")
    } else {
        isAutoSuspendEnabled := false
        SetTimer, executeAutoSuspend, % (isAutoSuspendEnabled ? 2000 : "off")
    }
    return

MButton:: ; Quick save.
    if (WinActive(appProcess)) {
        save()
    }
    return

XButton1::  ; Main action button.
/*
    if (!isAssistDomesticAffairsRunning) {
        assistDomesticAffairs()
    }
    return
    */
    if (!isLogical || !WinExist(appProcess) || !WinActive(appProcess)) {
        return
    }


    ;WinGetText, strings, %appProcess%
    ;windowTexts := StrSplit(strings, "`r`n")

    WinGetTitle, windowTitle, %appProcess%

    switch windowTitle {
        case "徴兵":  ; Execuete a command of the custom max draft. If the command is running, abort it.
            if (isCustomDraftRunning) {
                isCustomDraftRunning := false
            } else {
                customMaxDraft()
            }
        case "軍団資産":
            if (!isCustomManageCorpsFundsRunning) {
                customManageCorpsFunds()
            }
        case "戦国史SE", "戦国史FE":
            ;MsgBox, フェイズ判定へ
            phaseType := detectPhase()

            ;MsgBox, %phaseType%

            switch phaseType {
                case 1:  ; Personnel phase.
                    MsgBox, 人事フェイズ
                case 2:  ; Armaments phase.
                    MsgBox, 軍備フェイズ
                case 3:  ; Domestic affairs phase.
                    assistDomesticAffairs()
                case 4:  ; Strategy phase.
                    MsgBox, 移動フェイズ
                case 5:  ; Departure phase.
                    MsgBox, 出陣フェイズ

            }
    }

    return

XButton2::
    if (!isLogical || !WinExist(appProcess) || !WinActive(appProcess)) {
        return
    }

    WinGetTitle, windowTitle, %appProcess%

    switch windowTitle {
        case "徴兵":  ; Execuete a command of the fixed amount draft.
            fixedAmountDraft()
        case "軍団資産":

        case "戦国史SE", "戦国史FE":
            ;MsgBox, フェイズ判定へ
            phaseType := detectPhase()

            ;MsgBox, %phaseType%

            switch phaseType {
                case 1:  ; Personnel phase.
                    MsgBox, 人事フェイズ
                case 2:  ; Armaments phase.
                    MsgBox, 軍備フェイズ
                case 3:  ; Domestic affairs phase.
                    ;assistDomesticAffairs()
                case 4:  ; Strategy phase.
                    MsgBox, 移動フェイズ
                case 5:  ; Departure phase.
                    MsgBox, 出陣フェイズ

            }
    }
    return

; The following code is for the development and test.
Home::
    global appProcess

    WinGetText, strings, %appProcess%
    ;array := StrSplit(strings, "`n")
    MsgBox, %strings%
    return

Insert::
    WinGetTitle, windowTitle, %appProcess%
    MsgBox, %windowTitle%
    return

Delete::
    ControlGetText, OutputVar, Button1, %appProcess%
    MsgBox, %OutputVar%
    return

Break::
    Click, 100

isMainWindow() {
    WinGetTitle, windowTitle, %appProcess%

    if (windowTitle == "戦国史SE" || windowTitle == "戦国史FE") {
        return true
    } else {
        return false
    }
}