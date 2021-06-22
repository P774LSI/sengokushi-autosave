; @name "Sengokushi AutoSave"
; @version "1.0.0 / 20210614"
; @author "P-774LSI"
; @lisence "CC0"

/*
概要: 戦国史SE, 戦国史FEでオートセーブ、クイックセーブ、ワンクリック内政（実験的機能）を行うユーザー操作補助スクリプトです。
使用にはAutoHotkey（以下AHK） v1.1.31以上の導入が必要です（セーブファイル名に日本語を使う場合はユニコード版推奨）。
スクリプト実行中は、マウスのセンターボタン・サイドボタン2、キーボードのF2～F3およびF7～F12がゲーム用のキー割り当てに変更されます。
必要に応じてAHKをサスペンド（戦国史が非アクティブ中にセンタークリック、もしくはタスクトレイのアイコンから可）してホットキーを無効化してください。
各種設定は48行目から記述されています。

・オートセーブは戦国史がアクティブかつ、ユーザーが一定時間操作をしない場合に行われます。

・オートセーブ、クイックセーブは共通してセーブファイル名は「プレフィクス+スプリッタ文字+YYYYMMDD-HH24MISS」になります。
例えばデフォルトでは、「sengokushi 20210613-201706」のようになります。プレフィクス・スプリッタは変更可能ですが、
上書き保存時以外は日付時刻は強制付与されます。

・ワンクリック内政は、商業開発・新田開発・産業開発・鉄砲生産の4つを実装しています。不要なものはホットキーでoffにできます。
これは実験的な要素であり、実行環境によっては動かない可能性があります。
動作が不正確な場合、129行目の`sleepDuration1`の値を増やすことで改善されるかもしれません。

・ホットキーの変更は416行目以降を書き換えてください。
http://ahkwiki.net/KeyList
http://ahkwiki.net/Hotkeys

---------------------------------------------------------------------------------------------------------------------
クイック・リファレンス

マウス
センターボタン: クイックセーブ。また戦国史がアクティブ中はサスペンドの中止、非アクティブ時はサスペンドが有効化されます。
サイドボタン2: ワンクリック内政。

キーボード
F2: オートセーブの有効/無効切り替え。
F3: 上書きセーブの有効/無効切り替え。
F7: ワンクリック内政の一括有効/無効切り替え。
F8: 商業開発の有効/無効切り替え。
F9: 新田開発の有効/無効切り替え。
F10: 産業開発の有効/無効切り替え。
F11: 鉄砲生産の有効/無効切り替え。
F12: セーブファイルフォルダを開く。

※キーボードのホットキーはF12以外はすべてブール値の切り替えを行うためのみに用意されています。これらの切り替えが不要な場合はすべて削除しても動作します。
*/

;-----------------------------------------------------------------------------------------------------------------------
; ユーザー設定項目

; オートセーブを有効化するかどうかのブール初期値を指定します。キーボードのF2で初期値から変更できます。
isAutoSaveEnabled := true

; オートセーブが発動するまでのマウス非操作時間（ミリ秒）。初期値300000（5分）。有効範囲：60000-4294967295
fireSaveDuration := 300000

; オートセーブ有効時、AHKを自動で一時停止（Pause）するまでのマウス非操作時間（ミリ秒）。初期値2時間。有効範囲：60000-4294967295
; 一時停止はタイマー類にのみ影響します。ホットキーは無効化されません。
firePauseDuration := fireSaveDuration * 24

; スクリプトを先に起動した時に、戦国史も一緒に起動させるかどうかのブール値を指定します。
; この設定が`false`の場合、先に戦国史を起動しないとSE, FEの判定を行えないため、スクリプトが正しく動作しません。
isLaunchAppEnabled := true

; 戦国史の実行ファイルのフルパス。前記の戦国史の`isLaunchAppEnabled`（自動起動）が`true`の場合、ここにパスを指定します。
appPath := "C:\Program Files (x86)\SengokushiSE\戦国史SE.exe"

; 戦国史のセーブフォルダのフルパス。キーボードのF12で開きます。上SE、下FE。
;saveFolderPathSE := "C:\Program Files (x86)\SengokushiSE\SaveData"  ; 恐らくWindows7未満
saveFolderPathSE = %LOCALAPPDATA%\VirtualStore\Program Files (x86)\SengokushiSE\SaveData
saveFolderPathFE = %LOCALAPPDATA%\VirtualStore\Program Files (x86)\SengokushiFE\SaveData

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

; ユーザー操作補助（ワンクリック内政）を有効化するかどうかのブール初期値を指定します。キーボードのF7で初期値から変更できます。
; この値が`false`の場合、以降の内政個別設定内容に関係なく、ユーザー操作補助は無効化されます。
isCommandAssistEnabled := true

; ワンクリック内政に商業開発を含めるかどうかのブール初期値を指定します。ホットキーはF8。
isCommerceEnabled := true

; ワンクリック内政に新田開発を含めるかどうかのブール初期値を指定します。ホットキーはF9。
isDevelopmentNewFieldsEnabled := true

; ワンクリック内政に産業（鉱山）開発を含めるかどうかのブール初期値を指定します。ホットキーはF10。
isIndustriesEnabled := true

; ワンクリック内政に鉄砲生産を含めるかどうかのブール初期値を指定します。ホットキーはF11。
isMatchlocksProductionEnabled := true

; 戦国史が非アクティブになった際に自動でサスペンド（ホットキー無効化）をさせるかどうかのブール初期値を指定します。
; 頻繁にアクティブウィンドウを切り替える場合に便利ですが、タイマーが常駐監視するためわずかですがリソース消費が増えます。
isAutoSuspendEnabled := false
/*
ここまでユーザー設定項目。
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
#Persistent  ; Keeps a script.

; Window titles.
title =
titleSE = ahk_exe 戦国史SE.exe
titleFE = ahk_exe 戦国史FE.exe

; Only use Save function.
saveFolderPath =
elapsedTime := 0
checkDuration := 1000

; Only use command assist function.
mouseXPos := 0  ; Current mouse X pos.
mouseYPos := 0
mouseOffset1 := 200  ; Just about the center pos of a sub-window.
checkBoxColor := 0x808080  ; Gray. RGB, 128, 128, 128
;subWindowBGColor := 0xFFFFFF  ; RGB, 255, 255, 255  ; Not use current version.
subWindow1checkBoxXPos := 26
subWindow1checkBoxYPos := 120
sleepDuration1 := 50  ; Short wait for key operation.
sleepDuration2 := sleepDuration1 * 10  ; Long wait for key operation.
;subWindow1Width := 519  ; Not use current version.
;subWindow1Height := 409  ; Not use current version.

; Get a window title of the app and define the variable.
setTitle()

if (isLaunchAppEnabled && !title) { ; To avoid double running of the app.
    Run, %appPath%
    Sleep 3000
    setTitle()
}

if (title == titleSE) {
    saveFolderPath := saveFolderPathSE
} else {
    saveFolderPath := saveFolderPathFE
}

; Start Auto save.
SetTimer, observe, % (isAutoSaveEnabled ? checkDuration : "off")

; Auto suspend.
if (isAutoSuspendEnabled) {
    SetTimer, executeAutoSuspend, % (WinExist(title) ? 2000 : "off")
}

; Change the default tray tooltip.
setTooltipText()

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

setTitle() {
    global title
    global titleSE
    global titleFE

    if (WinExist(titleSE)) {
        title := titleSE
    } else if (WinExist(titleFE)) {
        title := titleFE
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
    global title
    global isSaveComplete
    global isPrefixAutoDetectEnabled
    global isOverwrite
    str =
    clipSaved =

    if (WinExist(title) && WinActive(title)) {
        ; Open the save dialog box.
        Sleep, 500
        Send !{f}  ; Alt + f
        Sleep, 100
        Send {s}
        Sleep, 500

        ; Create a file name, into clipboard and send to the dailog box.
        FormatTime, TimeString,, yyyyMMdd-HHmmss

        if (isPrefixAutoDetectEnabled) {
            str := getPrefix()
            prefix := str ? str : prefix
        }

        clipSaved := ClipboardAll

        if (isOverwrite) {
            Clipboard = %prefix%
        } else {
            Clipboard = %prefix%%spliter%%TimeString%
        }

        Send ^{v}  ; Ctrl + v
        Sleep, 100
        Send !{s}

        if (isOverwrite) {
            Sleep, 500
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

assistDomesticAffairs() {
    global title
    global isCommandAssistEnabled

    if (WinExist(title) && WinActive(title) && isCommandAssistEnabled) {
        executeDomesticAffairs(1) ; Commerce.
        executeDomesticAffairs(2) ; Development new fields.
        executeDomesticAffairs(3)  ; Industries.
        executeDomesticAffairs(7)  ; Produce matchlocks.
    }
}

getColor(x, y) {
    PixelGetColor, Color, x, y, RGB Alt
    return Color
}

executeDomesticAffairs(processType) {
    global isCommerceEnabled
    global isDevelopmentNewFieldsEnabled
    global isIndustriesEnabled
    global isMatchlocksProductionEnabled
    global sleepDuration1
    global sleepDuration2
    isPermission :=

    switch processType
    {
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
    } else {  ; Else Cancel.
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

executeAutoSuspend() {
    global title

    if (!WinActive(title)) {
        Suspend, on
    } else {
        Suspend, off
    }
}

setTooltipText() {
    global tooltipText
    global isAutoSaveEnabled
    global isOverwrite
    global isCommerceEnabled
    global isDevelopmentNewFieldsEnabled
    global isIndustriesEnabled
    global isMatchlocksProductionEnabled
    
    tooltipText = 自動保存: %isAutoSaveEnabled% `n上書き保存: %isOverwrite% `n商業: %isCommerceEnabled% `n新田開発: %isDevelopmentNewFieldsEnabled% `n産業: %isIndustriesEnabled% `n鉄砲生産: %isMatchlocksProductionEnabled% 
    Menu, TRAY, Tip, %tooltipText%
}

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
    isCommandAssistEnabled := !isCommandAssistEnabled
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

MButton:: ; Quick save and the suspend switch.
    if (WinActive(title)) {
        Suspend, off
        save()
    } else {
        Suspend, on
    }
    return

XButton2::  ; Assist the command of domestic affairs.
    assistDomesticAffairs()
    return