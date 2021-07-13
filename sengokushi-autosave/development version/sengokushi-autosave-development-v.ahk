; @name "Sengokushi AutoSave"
; @version "1.3.0.α1 / 20210703"
; @author "P-774LSI / https://github.com/P774LSI/sengokushi-autosave"
; @lisence "CC0"

/*
概要: 戦国史SE, 戦国史FEで「オートセーブ」・「クイックセーブ」を行うユーザー操作補助スクリプトです。
また拡張機能として「内政アシスト」・「足軽・城兵を指定数だけ徴兵」・「足軽数が指定数以上の人物はすべて最大まで徴兵」・「兵糧を指定数だけ補充」・「兵糧を最大まで補充」・「軍団資産の初期数値入力」
コマンドを提供します。
使用にはAutoHotkey（以下AHK） v1.1.31以上（ユニコード版）の導入が必要です（v2系は動作保証外）。
スクリプト実行中は、マウスのセンターボタン・サイドボタン1・2、キーボードのF2～F3およびF7～F12、Scroll Lockがゲーム用のキー割り当てに変更されます。
これらのホットキーは戦国史がアクティブな場合に限り、使用できます。非アクティブ化で自動的にオフになります。
Scroll Lock押下、もしくはタスクトレイのアイコンからもサスペンド（ホットキーの無効化）は切り替えできます。
各種設定は59行目から記述されています。

・オートセーブは戦国史がアクティブかつ、ユーザーが一定時間操作をしない場合に行われます。

・オートセーブ、クイックセーブは共通してセーブファイル名は「プレフィクス+スプリッタ文字+YYYYMMDD-HH24MISS」になります。
例えばデフォルトでは、「sengokushi 20210613-201706」のようになります。プレフィクス・スプリッタは変更可能ですが、
上書き保存時以外は日付時刻は強制付与されます。

・内政アシストは、商業開発・新田開発・産業開発・鉄砲生産の4つを実装しています。不要なものはホットキーでoffにできます。

・テストは主に戦国史SE・Windows10下で行っています。環境によっては動作に問題が出る可能性があります。
動作が不正確な場合は220行目の【高度な設定】から`sleepDuration1`の値を増やすことで改善されるかもしれません。

・ホットキーの変更は1017行目以降を書き換えてください。
http://ahkwiki.net/KeyList
http://ahkwiki.net/Hotkeys

---------------------------------------------------------------------------------------------------------------------
クイック・リファレンス

【マウス】
センターボタン: クイックセーブ。
サイドボタン1:  [軍備フェイズ] 徴兵ウィンドウを開いて人物または城を選択した状態で押すと、事前に指定された数の足軽または城兵を徴兵します。
               [軍備フェイズ] 城兵糧補充ウィンドウを開いて城を選択した状態で押すと、事前に指定された数量の兵糧を補充します。
               [軍備フェイズ] 軍団資産ウィンドウを開いた状態で押すと、資金供給・資金徴収・鉄砲支給の入力フォームに事前に指定された数値を入力します。動作中もう1度押すと鉄砲以外はさらに加算されます。
               [内政フェイズ] 内政アシスト。内政フェイズで各サブウィンドウを開く前に押します。
サイドボタン2:  [軍備フェイズ] 徴兵ウィンドウを開いた状態で押すと、足軽数が指定数以上の人物はすべて最大まで徴兵します。動作中もう1度押すと中止します。
               [軍備フェイズ] 城兵糧補充ウィンドウを開いて城を選択した状態で押すと、最大まで兵糧を補充します。


【キーボード】
F2: オートセーブの有効/無効切り替え。
F3: 上書きセーブの有効/無効切り替え。
F7: 内政アシストの一括有効/無効切り替え。
F8: 商業開発の有効/無効切り替え。
F9: 新田開発の有効/無効切り替え。
F10: 産業開発の有効/無効切り替え。
F11: 鉄砲生産の有効/無効切り替え。
F12: セーブファイルフォルダを開く。
Scroll Lock: サスペンド（ホットキー無効化）の有効/無効の切り替え。これはオートサスペンドが無効時の切り替え操作のために用意されています。

※キーボードのホットキーはF12以外はすべてブール値の切り替えを行うためのみに用意されています。これらの切り替えが不要な場合はすべて削除しても動作します。
*/

;-----------------------------------------------------------------------------------------------------------------------
; ユーザー設定項目

; ------------------------
; =====【基本機能設定】=====
; ------------------------
; 【システム】
; スクリプトを先に起動した時に、戦国史も一緒に起動させるかどうかのブール値を指定します。
; 通常は戦国史起動後にスクリプトを起動する必要がありますが、この設定が`true`の場合に限り先にスクリプトを起動できます。
isLaunchAppEnabled := true

; 戦国史の実行ファイルのフルパス。前記の戦国史の`isLaunchAppEnabled`（自動起動）が`true`の場合、ここにパスを指定します。
appPath := "C:\Program Files (x86)\SengokushiSE\戦国史SE.exe"

; 戦国史のセーブフォルダのフルパス。キーボードのF12で開きます。上SE、下FE。
EnvGet, envPath, LOCALAPPDATA  ; 環境変数を使用する場合は最後の引数にその名前を記載。
saveFolderPathSE = %envPath%\VirtualStore\Program Files (x86)\SengokushiSE\SaveData
saveFolderPathFE = %envPath%\VirtualStore\Program Files (x86)\SengokushiFE\SaveData
;saveFolderPathSE := "C:\Program Files (x86)\SengokushiSE\SaveData"  ; 恐らくWindows7未満

; 戦国史が非アクティブになった際に自動でサスペンド（ホットキー無効化）をさせるかどうかのブール初期値を指定します。
; 頻繁にアクティブウィンドウを切り替える場合に便利ですが、タイマーが常駐監視するためわずかですがリソース消費が増えます。
isAutoSuspendEnabled := true


; 【オートセーブ・クイックセーブ】
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





; ------------------------
; =====【拡張機能設定】=====
;-------------------------
; 【システム】
; 拡張機能の有効/無効をブール値で切り替えます。
; この設定を`true`にすると、スクリプトに対してゲーム内から追加の情報を読み取る許可を与え、拡張機能の使用を可能にします。
; 具体的には「内政アシスト」・「足軽・城兵を指定数だけ徴兵」・「足軽数が指定数以上の人物はすべて最大まで徴兵」・【兵糧を指定数だけ補充】・「兵糧を最大まで補充」・「軍団資産の初期数値入力」を使用可能にします。
isExtensionEnabled := true

; 現在内政フェイズかどうかを判断し、「内政アシスト」を適切に実行するための判断リストです。
; ユーザー作製シナリオでは、内政フェイズのすべての単語が置換されている可能性があるため、リストの確認が必要です。サンプルシナリオでは不要です。
; 以下のリスト内の単語が1つでも内政コマンドに含まれているように、必要に応じてリストに追記を行います。
pendingList1 := ["新田開墾", "楽市楽座", "鉱山開発", "鉄砲生産", "商業整備", "産業整備"]


; 【内政アシスト】
; 「内政アシスト」を有効化するかどうかのブール初期値を指定します。キーボードのF7で初期値から変更できます。
; この値が`false`の場合、以降の内政個別設定内容に関係なく、内政アシストは無効化されます。
isAssistDomesticAffairsEnabled := true

; 「内政アシスト」に商業開発を含めるかどうかのブール初期値を指定します。切り替えホットキーはF8。
isCommerceEnabled := true

; 「内政アシスト」に新田開発を含めるかどうかのブール初期値を指定します。切り替えホットキーはF9。
isDevelopmentNewFieldsEnabled := true

; 「内政アシスト」に産業（鉱山）開発を含めるかどうかのブール初期値を指定します。切り替えホットキーはF10。
isIndustriesEnabled := true

; 「内政アシスト」に鉄砲生産を含めるかどうかのブール初期値を指定します。切り替えホットキーはF11。
isMatchlocksProductionEnabled := true

; 「内政アシスト」時に資金が以下の数値を下回る場合は新田開墾と鉄砲購入を行いません。
fundsLimit := 10000


; 【足軽・城兵を指定数だけ徴兵】
; 「足軽・城兵を指定数だけ徴兵」コマンドを有効化するかどうかのブール値を指定します。
isFixedAmountDraftEnabled := true

; 選択した人物に対して「足軽・城兵を指定数だけ徴兵」コマンドを実行した際、以下の回数だけ足軽スピンをクリックします。例えば「兵最小単位」が10のシナリオで50と設定された場合、500人を徴兵します。
draftForGeneralSpinClicks := 85

; 選択した城に対して「足軽・城兵を指定数だけ徴兵」コマンドを実行した際、以下の回数だけ守備兵スピンをクリックします。
draftForCastleSpinClicks := 25

; 選択した城に対して「足軽・城兵を指定数だけ徴兵」コマンドを実行した際に徴兵された城兵数から「兵最小単位」を計算し、次回以降の同コマンド実行時に城兵数が1回あたりの徴兵数の倍数になるように調整を行います。
; 例えば城兵数が720の城に対して500が一度に徴兵される設定だった場合、徴兵すると1,220ではなく、500の倍数である1,000になるように調整が行われます。
isDraftDefenderMultipleEnabled := true

; 「足軽・城兵を指定数だけ徴兵」コマンドを実行した後に、マウスカーソルを元の位置に戻すかどうかのブール値を指定します。
isReturnsCursorFixedAmountDraft := true


; 【足軽数が指定数以上の人物はすべて最大まで徴兵】
; 「足軽数が指定数以上の人物はすべて最大まで徴兵」コマンドを有効化するかどうかのブール値を指定します。
isCustomMaxDraftEnabled := true

; 「足軽数が指定数以上の人物はすべて最大まで徴兵」コマンドは、この数値以上の足軽を抱える人物に対して実行されます。
targetNumberOfSoldiers := 4000

; 「足軽数が指定数以上の人物はすべて最大まで徴兵」コマンドを実行中、徴兵可能な足軽が以下の数値を下回った場合はコマンドを中止します。
draftRemainLimit := 3000


; 【兵糧を指定数だけ補充】
; 「兵糧を指定数だけ補充」コマンドを有効化するかどうかのブール値を指定します。
isFixedAmountSupplyHyoroEnabled := true

; 「兵糧を指定数だけ補充」コマンド実行時に補充される1回あたりの兵糧の数量を指定します。
; これはスライダーのみによる補充で、微調整は行いません。ほとんどのケースで指定数よりも幾らか誤差が出ます。誤差を出したくない、または末尾の数字を0で揃えたい場合は次の倍数指定を有効化してください。
amountOfSupplyHyoro := 2500

; 「兵糧を指定数だけ補充」コマンドを実行した際に、補充後の兵糧が指定数の倍数になるように自動で調整します。
; 例えば兵糧が5,330の城に対して2,500が一度に補充される設定だった場合、補充すると7,830ではなく、2,500の倍数である7,500になるように調整が行われます。
isSupplyHyoroMultipleEnabled := false

; 「兵糧を指定数だけ補充」コマンドを実行した後に、マウスカーソルを元の位置に戻すかどうかのブール値を指定します。
isReturnsCursorFixedAmountSupplyHyoro := true


; 【兵糧を最大まで補充】
; 「兵糧を最大まで補充」コマンドを有効化するかどうかのブール値を指定します。
isMaxSupplyHyoroEnabled := true

; 「兵糧を最大まで補充」コマンドを実行した後に、マウスカーソルを元の位置に戻すかどうかのブール値を指定します。
isReturnsCursorMaxSupplyHyoro := true


; 【軍団資産の初期数値入力】
; 「軍団資産の初期数値入力」コマンドを有効化するかどうかのブール値を指定します。
isCustomManageCorpsFundsEnabled := true

; 「軍団資産の初期数値入力」コマンド実行時の「軍団に資金を支給」左横の入力ボックスに入力する数値を指定します。
; 数値はコマンドが実行されるたびに増加します。例: 30000 -> 60000 -> 90000 -> ...
paymentAmount := 50000

; 「軍団資産の初期数値入力」コマンド実行時の「軍団から資金を徴収」左横の入力ボックスに入力する数値を指定します。
; 数値はコマンドが実行されるたびに増加します。例: 30000 -> 60000 -> 90000 -> ...
collectionAmount := 30000

; 「軍団資産の初期数値入力」コマンド実行時の「軍団に鉄砲を支給」左横の入力ボックスに入力する数値を指定します。
supplyMatchlockAmount := 0





; ------------------------
; =====【高度な設定】=====
; ------------------------
; 【システム】
; スクリプトが行うキー操作間のスリープ時間を指定します（ミリ秒）。数値が少ないほどコマンドの実行速度が上がりますが、環境によっては動作しなくなります。
; デフォルトでは50ms（0.05秒）とかなり高速で操作を行うように設定されています。なお、実際のスリープ時間はこれにキーそのものが持つわずかなスリープ時間も加わります。
; 動作不具合やスクリプトテスト時はまずこの値を増やして検証してください。
sleepDuration1 := 50

; ダイアログやサブウィンドウの表示を待つためのスリープ時間を指定します（ミリ秒）。
sleepDuration2 := 500

sleepDuration3 := 300



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
isSaveComplete :=

; About extensions.
mouseXPos := 0  ; Current mouse X pos.
mouseYPos := 0
mouseOffset1 := 180  ; Just about the center pos of a sub-window.
checkBoxColor := 0x808080  ; Gray. RGB, 128, 128, 128
subWindow1checkBoxXPos := 23  ; Client coordinate. Not window cordinate !
subWindow1checkBoxYPos := 94  ; Client coordinate. Not window cordinate !
grayOutColor := 0x808080  ; String color of a gray out.
fontColor := 0x000000  ; Default font color.
lineColor := 0xE0E0E0  ; Line color of a list.

funds := 0
oldFunds := 0
domesticAffairsWord =
soldierUnit := 0  ; 1 or 10.  Define the parameter the first time of draft command.
draftDefenderAmount := 0  ; soldierUnit(1 or 10) * draftForCastleSpinClicks(user define number)

isCustomDraftRunning := false
isSupplyHyoroRunning := false
isCustomManageCorpsFundsRunning := false
isAssistDomesticAffairsRunning := false
isAfbRunning := false
isAswRunning := false

; test
sleepDurationTest1 := 500

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Script start.

#NoEnv
#Persistent  ; Keeps a script.
#MaxThreadsPerHotkey 2  ; To define an abort key if same hot key pressed twice in a row.
CoordMode, Pixel , Client  ; For unifying the origin of color coordinates of an app's window that differ between each operating system.
CoordMode, Mouse , Client
;SendMode Input

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
; Objects.

; Auto field battle(AFB).
afb := {}

afb.generalListTop := 168
afb.generalListRowHeight := 16

afb.friendlyBattleArray := []
afb.enemyBattleArray := []  ; Index 0: The first unit. Index 1: The second unit. Index 2: Headquarters.
afb.friendlyUnits :=  ; Number of friendly units.
afb.enemyUnits :=  ; Number of enemy units.
afb.friendlyUnitFrontPos :=
afb.enemyUnitFrontPos :=  ; Default an enemy first unit position.
afb.arrayDistance :=  ; Range 1-5.
afb.enemyTookPresumptionAction :=  ; Enemy took a presumption action. 0 is wait, 1 is move forward, 2 is fire.




;afb.listTop
;afb.honzinStringColorXPos := 263
;afb.honzinStringColorYPos := 483
;afb.honzinStringColor := getColor(263, 483)



afb.jindate := Func("_afbJindate")
afb.engage := Func("_afbEngage")
afb.judgeAction := Func("_afbJudgeAction")
afb.inputAction := Func("_afbInputAction")
afb.updateBattleArray := Func("_afbUpdateBattleArray")




_afbJindate(this, commanderType) {
    global isAfbRunning
    global sleepDuration1
    global grayOutColor
    global lineColor
    global sleepDurationTest1
    honzinStringColor :=
    isBottom := false
    color1 :=
    counter := 0
    currentYPos :=
    isAfbRunning := true


    WinGetTitle, windowTitle, %appProcess%

    if (windowTitle != "野戦発生") {
        isAfbRunning := false
        return
    }

    color1 := getColor(100, this.generalListTop + this.generalListRowHeight)

    if (color1 != lineColor) {
        commanderType := 0  ; Only supreme commander.
    }

    switch commanderType {
        case 1:  ; The commander having the smallest units.
            MouseMove, 210, 160
            Sleep, sleepDurationTest1
            Click
            
            ;While (!isBottom || counter < 21) {
            While (!isBottom) {
                counter++
                ;currentYPos := % this.generalListTop + this.generalListRowHeight
                ;MsgBox, %currentYPos% [currentYPos]

                color1 := getColor(100, this.generalListTop + this.generalListRowHeight * counter)
                ;MsgBox, %color1% [color1]

                if (color1 != lineColor) {
                    isBottom := true
                } else if (counter > 14) {
                    MouseClick, WheelDown, , , 5
                    isBottom := true
                }
            }

            ;MsgBox, %counter% [counter]

            MouseMove, 210, % -7 + this.generalListTop + this.generalListRowHeight * (counter - 1)
            Sleep, 2000
            Click
            honzinStringColor := getColor(263, 483)

            if (honzinStringColor == grayOutColor) {
                commanderType := 0
            }

            ; test return
            ;return
        
        case 2:  ; The commander having the biggest units.
        
        case 3:  ; The commander having a highest leadership ability with the field battle.
            ;MsgBox, case3
            MouseMove, 353, 160
            Sleep, sleepDurationTest1
            Click  ; Click a column header to ordered the list by the leadership ability.
            Sleep, sleepDurationTest1
            ;MouseClick, WheelUp, , , 5
            Sleep, sleepDurationTest1
            MouseMove, 353, 174
            Sleep, sleepDurationTest1
            Click  ; Choose a commander.

            honzinStringColor := getColor(263, 483)

            if (honzinStringColor == grayOutColor) {
                commanderType := 0
            }
    }

    if (commanderType) {
        MouseMove, 290, 485  ; Hover the cursor on the `Honjin(本陣)` button.
        Sleep, sleepDurationTest1
        Click
        
        color1 := getColor(100, this.generalListTop + this.generalListRowHeight)

        if (color1 != lineColor) {
            MouseMove, 772, 20
            Sleep, sleepDurationTest1
            Click
        } else {
            ; Set all the general to the first group.
            MouseMove, 110, % this.generalListTop + 8
            Sleep, sleepDurationTest1
            MouseClickDrag, LEFT, 0, 0, 0, 500, 5, R
            Sleep, sleepDurationTest1
            MouseMove, 110, 485
            Sleep, sleepDurationTest1
            Click
            Sleep, sleepDurationTest1
            MouseMove, 772, 20
            Sleep, sleepDurationTest1
            Click
        }
    } else {
        Click
        Sleep, sleepDuration2
        MouseMove, 772, 20
        Sleep, sleepDurationTest1
        Click
    }


}

_afbJudgeAction(this, actionType) {
    global fontColor
    stringColor :=
    isConfirm :=
    priorityList :=
    priorityList1 := [2, 1, 3, 3]
    priorityList2 :=
    priorityList3 :=
    priorityList9a := [6, 2]  ; 奇襲退却
    priorityList9b := [2, 3]  ; 奇襲反撃
    isShootOut :=

    While (!isConfirm) {
        switch actionType {
            case 1:  ; Move forward(前進).
                stringColor := getColor(54, 41)

                if (stringColor == fontColor) {
                    return 1
                } else {
                    actionType := 2
                }
            case 2:  ; Attack(攻撃).
                stringColor := getColor(190, 41)

                if (stringColor == fontColor) {
                    ;MsgBox, 攻撃決定
                    return 2
                } else {
                    actionType := 1
                }
            case 3:  ; Fire(鉄砲射撃).
                stringColor := getColor(77, 71)  ; or getColor(77, 69)

                if (stringColor == fontColor) {
                    return 3
                } else {
                    ;MsgBox, 攻撃可能判定へ
                    actionType := 2
                }
            case 4:  ; Change a battle array(先陣／第二陣 交代).
                return 4
            case 5:  ; Wait(待機).
                return 5
            case 6:  ; Restreat(退却).
                return 6
        }
    }
}

_afbInputAction(this, actionType) {
    global sleepDuration1
    global sleepDurationTest1
    leftButtonXPos := 62
    rightButtonXPos := 186
    moveForwardYPos := 45
    attackYPos := 45
    fireYPos := 74
    changeBattleArrayYPos := 74
    waitYPos := 103
    retreatYPos := 103

    ;MsgBox, InputAction OK!

    switch actionType {
        case 1:  ; Move forward(前進).
            MouseMove, %leftButtonXPos%, %moveForwardYPos%
            Sleep, sleepDurationTest1
            Click
        case 2:  ; Attack(攻撃).
            MouseMove, %rightButtonXPos%, %attackYPos%
            Sleep, sleepDurationTest1
            Click
        case 3:  ; Fire(鉄砲射撃).
            MouseMove, %leftButtonXPos%, %fireYPos%
            Sleep, sleepDurationTest1
            Click
        case 4:  ; Change a battle array(先陣／第二陣 交代).
            MouseMove, %rightButtonXPos%, %changeBattleArrayYPos%
            Sleep, sleepDurationTest1
            Click
        case 5:  ; Wait(待機).
            MouseMove, %leftButtonXPos%, %waitYPos%
            Sleep, sleepDurationTest1
            Click
        case 6:  ; Restreat(退却).
            MouseMove, %rightButtonXPos%, %retreatYPos%
            Sleep, sleepDurationTest1
            Click
    }
}

_afbUpdateBattleArray(this, turn) {
    global afb
    enemyColor := 0xFF7D5A
    friendlyColor :=
    pickedColor :=
    enemyFrontPos :=
    friendlyFrontPos :=
    oldEnemyUnits := afb.enemyUnits
    oldEnemyFrontPos := afb.enemyUnitFrontPos
    oldDistance := afb.arrayDistance
    isExistUnit :=
    checkColorXPos :=
    checkColorYPos :=
    checkColorXPosList := []
    checkColorYPosList := []
    checkColorXPosList[2] := 334
    checkColorXPosList[3] := 382
    checkColorXPosList[4] := 433
    checkColorXPosList[5] := 481
    checkColorXPosList[6] := 531
    checkColorXPosList[7] := 580
    checkColorXPosList[8] := 629
    checkColorYPosList[2] := 179
    checkColorYPosList[3] := 169
    checkColorYPosList[4] := 158
    checkColorYPosList[5] := 148
    checkColorYPosList[6] := 138
    checkColorYPosList[7] := 127
    checkColorYPosList[8] := 117

    ;MsgBox, %oldEnemyFrontPos% [oldEnemyFrontPos]


    if (isApproximateColor(enemyColor, 20, 2, checkColorXPosList[oldEnemyFrontPos - 1], checkColorYPosList[oldEnemyFrontPos - 1], 2)) {
        pickedColor := getColor(743, 345)
        afb.enemyUnitFrontPos := oldEnemyFrontPos - 1
        afb.enemyTookPresumptionAction := 1  ;  Presumption action.

        if (pickedColor == 0xFFFFFF) {
            afb.enemyBattleArray[0] := oldEnemyFrontPos - 1
            pickedColor := getColor(743, 447)

            if (pickedColor == 0xFFFFFF) {
                afb.enemyBattleArray[1] := oldEnemyFrontPos
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 1
            } else {
                afb.enemyBattleArray[1] := 0
                afb.enemyBattleArray[2] := oldEnemyFrontPos
            }
        } else {
            afb.enemyBattleArray[0] := 0
            pickedColor := getColor(743, 447)

            if (pickedColor == 0xFFFFFF) {
                afb.enemyBattleArray[1] := oldEnemyFrontPos
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 1
            } else {
                afb.enemyBattleArray[1] := 0
                afb.enemyBattleArray[2] := oldEnemyFrontPos
            }
        }
    } else if (isApproximateColor(enemyColor, 20, 2, checkColorXPosList[oldEnemyFrontPos], checkColorYPosList[oldEnemyFrontPos], 2)) {
        pickedColor := getColor(743, 345)
        afb.enemyUnitFrontPos := oldEnemyFrontPos
        afb.enemyTookPresumptionAction := 0

        if (pickedColor == 0xFFFFFF) {
            afb.enemyBattleArray[0] := oldEnemyFrontPos
            pickedColor := getColor(743, 447)

            if (pickedColor == 0xFFFFFF) {
                afb.enemyBattleArray[1] := oldEnemyFrontPos + 1
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 2
            } else {
                afb.enemyBattleArray[1] := 0
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 1
            }
        } else {
            afb.enemyBattleArray[0] := 0
            pickedColor := getColor(743, 447)

            if (pickedColor == 0xFFFFFF) {
                afb.enemyBattleArray[1] := oldEnemyFrontPos + 1
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 2
            } else {
                afb.enemyBattleArray[1] := 0
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 1
            }
        }
    } else {
        pickedColor := getColor(743, 345)
        afb.enemyUnitFrontPos := oldEnemyFrontPos + 1
        afb.enemyTookPresumptionAction := 0

        if (pickedColor == 0xFFFFFF) {
            afb.enemyBattleArray[0] := oldEnemyFrontPos + 1
            afb.enemyBattleArray[1] := 0
            afb.enemyBattleArray[2] := oldEnemyFrontPos + 2
        } else {
            pickedColor := getColor(743, 447)
            afb.enemyBattleArray[0] := 0

            if (pickedColor == 0xFFFFFF) {
                afb.enemyBattleArray[1] := oldEnemyFrontPos + 1
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 2
            } else {
                afb.enemyBattleArray[1] := 0
                afb.enemyBattleArray[2] := oldEnemyFrontPos + 2
            }
        }               
    }



    afb.friendlyUnitFrontPos := Max(afb.friendlyBattleArray[0], afb.friendlyBattleArray[1], afb.friendlyBattleArray[2])
    afb.arrayDistance := afb.enemyUnitFrontPos - afb.friendlyUnitFrontPos  ; Calc the distance.

    if (afb.arrayDistance < oldDistance) {
        afb.enemyTookPresumptionAction := 1    
    } else {
        if (oldEnemyUnits > afb.enemyUnits) {
            afb.enemyTookPresumptionAction := 1
        } else {
            afb.enemyTookPresumptionAction := 0
        }
    }


    MsgBox, % afb.friendlyBattleArray[0] "`n" afb.friendlyBattleArray[1] "`n" afb.friendlyBattleArray[2] "`n" afb.enemyBattleArray[0] "`n" afb.enemyBattleArray[1] "`n" afb.enemyBattleArray[2]
    MsgBox, % afb.friendlyUnits "[afb.friendlyUnits]`n" afb.enemyUnits "[afb.enemyUnits]`n" afb.friendlyUnitFrontPos "[afb.friendlyUnitFrontPos]`n" afb.enemyUnitFrontPos "[afb.enemyUnitFrontPos]`n" afb.arrayDistance "[afb.arrayDistance]`n" afb.enemyTookPresumptionAction "[afb.enemyTookPresumptionAction]"
}


_afbEngage(this, tacticsType) {
    global afb
    global sleepDuration1
    global sleepDuration2
    global sleepDuration3
    global sleepDurationTest1
    global grayOutColor
    global fontColor
    turn := 0
    checkColors := [0xFFFFFF]

    ;MsgBox, engage1ok
    testActions1 := [3, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    testActions2 := [3, 1, 1, 1, 2, 2, 2]
    testActions3 := [3, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    testActions8 := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]


    this.friendlyUnits :=  ; Number of friendly units.
    this.enemyUnits :=  ; Number of enemy units.
    this.friendlyUnitFrontPos :=
    this.enemyUnitFrontPos := 8 ; Default an enemy first unit position.
    this.arrayDistance :=  ; Range 1-5.
    this.enemyTookPresumptionAction := 0 ; Enemy took a presumption action. 0 is wait, 1 is move forward, 2 is fire.

    ; Determine whether or not a surprise attack has occurred.
    if (getWindowText(1) == "OK") {
        Send {Enter}
        sleep, sleepDuration2

        if (compareColors([fontColor], 183, 103, 2)) {
            tacticsType := 8  ; Surprise attack succeeded.
        } else {
            tacticsType := 9
        }
    }

    switch tacticsType {
        case 1:
            ;MsgBox, 通常釣り出し

            for i, element in testActions3 {
                turn++
                ;MsgBox, %i%
                this.inputAction(this.judgeAction(element))
                Sleep, sleepDuration3

                if (getWindowText(1) == "OK") {
                    ;MsgBox, End of battle.
                    break
                }
            }
        case 2:
            ;MsgBox, 鉄砲釣り出し
        case 3:
            ;MsgBox, 通常会戦
            
            for i, element in testActions3 {
                WinGetTitle, windowTitle, %appProcess%

                if (windowTitle == "野戦") {
                    turn++
                    ;afb.updateBattleArray(turn)
                    ;MsgBox, %i%
                    

                    this.inputAction(this.judgeAction(element))
                    Sleep, % sleepDuration3

                    if (getWindowText(1) == "OK") {
                        ;MsgBox, "[afb.engage() / case3 / getWindowText(1) == OK]"
                        Send {Enter}
                        Sleep, % sleepDuration2
                    }

                } else {
                    ;MsgBox, "[afb.engage() / case3 / brake]"
                    break
                }
            }            
        case 8:  ; Surprise attack succeeded.
            for i, element in testActions8 {
                turn++
                ;MsgBox, %i%
                this.inputAction(this.judgeAction(element))
                Sleep, % sleepDuration3

                if (getWindowText(1) == "OK") {
                    ;MsgBox, End of battle.
                    break
                }
            }
        case 9:
  
    }

    Sleep, sleepDuration2
    MouseMove, 88, 48
    Sleep, sleepDurationTest1
    Click
    MouseMove, 126, 170
    Sleep, sleepDurationTest1
    Click
    isAfbRunning := false
}

; Auto siege warfare (ASW).
asw := {}


asw.attack := Func("_aswAttack")
asw.defend := Func("_aswDefend")
asw.execute := Func("_aswExecute")

asw.fireExecuteDuration := -2000


_aswAttack(this) {
    global isAswRunning
    ;global sleepDuration1
    ;global sleepDuration2
    global sleepDuration3
    global fontColor
    turn := 0
    ;roadType :=
    friendlySoldiers :=
    enemySoldiers :=
    isStormEnabled := true

    if (!isAswRunning) {
        return
    }

    ;MsgBox, "[asw.attack() call]"

    WinGetText, strings, %appProcess%
    infoTexts := StrSplit(strings, "`r`n")


    ;turn := infoTexts[12]
    friendlySoldiers := RegExReplace(infoTexts[21], "[^0-9]+", "")
    enemySoldiers := RegExReplace(infoTexts[22], "[^0-9]+", "")

    Loop 5 {
        if (isAswRunning) {
            turn++

            if (turn != 1) {
                friendlySoldiers := RegExReplace(infoTexts[21], "[^0-9]+", "")
                enemySoldiers := RegExReplace(infoTexts[22], "[^0-9]+", "")
                ;MsgBox, % turn "`n" friendlySoldiers "`n" enemySoldiers
            }
            
            if (isStormEnabled && getColor(176, 447) == fontColor) {
                MouseMove, 173, 446
                Sleep, sleepDuration1
                Click
                Sleep, sleepDuration1
            } else {
                MouseMove, 173, 472
                Sleep, sleepDuration1
                Click 
                Sleep, sleepDuration1         
            }
        }
    }

    ; Close the window.
    MouseMove, 393, 458
    Sleep, sleepDuration1
    Click
    isAswRunning := false
}

_aswDefend(this) {
    global isAswRunning


    isAswRunning := false
}


_aswExecute(this, tacticsType) {
    global sleepDuration1
    global sleepDuration2
    global sleepDuration3
    global sleepDurationTest1
    global isAswRunning
    buttonShadowColor := 0x606060

    isAswRunning := true

    if (getColor(224, 444) == buttonShadowColor) { ;  Player is the attacker.
        SetTimer, aswStartAttack, % this.fireExecuteDuration
        
    } else { ;  Player is the defender.
        SetTimer, aswStartDefend, % this.fireExecuteDuration
    }
}




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

aswStartAttack:
    asw.attack()
    return

aswStartDefend:
    asw.defend()
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
    global sleepDuration2
    global prefix
    global spliter
    global appProcess
    global isSaveComplete
    global isPrefixAutoDetectEnabled
    global isOverwrite
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
    PixelGetColor, Color, x, y, Alt RGB
    return Color
}

/*
 * @function
 * @param {number} hexColor Required. Hexadecimal color code.
 * @param {string} rgbType Required. `r`, `g`, `b` or `rgb`.
 * @returns {number|Array} Returns an integer with specific color code or array contained RGB color code.
 */
hexToRgb(hexColor, rgbType) {
    switch rgbType {
        case "r":
            StringMid, red, hexColor, 3, 2
            red := "0x" . red
            return red + 0
        case "g":
            StringMid, green, hexColor, 5, 2
            green := "0x" . green
            return green + 0
        case "b":
            StringMid, blue, hexColor, 7, 2
            blue := "0x" . blue
            return blue + 0
        case "rgb":
            array := []
            StringMid, red, hexColor, 3, 2
            StringMid, green, hexColor, 5, 2
            StringMid, blue, hexColor, 7, 2
            red := "0x" . red
            green := "0x" . green
            blue := "0x" . blue
            array[0] := red + 0
            array[1] := green + 0
            array[2] := blue + 0
            return array
    }    
}

/*
 * @function
 * @param {Array} colors Required. Integer.
 * @param {number} x Required. Integer.
 * @param {number} y Required. Integer.
 * @param {number} delta Optional. Integer.
 * @returns {number} Returns are number of matched colors.
 */
compareColors(colors, x, y, delta) {
    matches := 0

    if (delta) {
        for i, Element in colors {
            getColor(x, y) == Element ? matches++
            getColor(x - delta, y - delta) == Element ? matches++
            getColor(x, y - delta) == Element ? matches++
            getColor(x + delta, y - delta) == Element ? matches++
            getColor(x - delta, y) == Element ? matches++
            getColor(x + delta, y) == Element ? matches++
            getColor(x - delta, y + delta) == Element ? matches++
            getColor(x, y + delta) == Element ? matches++
            getColor(x + delta, y + delta) == Element ? matches++
        }
    } else {
        for i, Element in colors {
            getColor(x, y) == Element ? matches++
        }
    }

    ;MsgBox, %matches% [matches]
    return matches
}

/*
 * @function
 * @param {number} hexColor1 Required.
 * @param {number} hexColor2 Required.
 * @returns {number} Returns a color difference with percentage.
 */
calcAverageOfColorDifference(hexColor1, hexColor2) {
    rgbColor1 := hexToRgb(hexColor1, "rgb")
    rgbColor2 := hexToRgb(hexColor2, "rgb")
    diffR := Abs(rgbColor1[0] - rgbColor2[0])
    ;MsgBox, % diffR
    diffG := Abs(rgbColor1[1] - rgbColor2[1])
    diffB := Abs(rgbColor1[2] - rgbColor2[2])
    pctDiffR := diffR / 255
    pctDiffG := diffG / 255
    pctDiffB := diffB / 255
    return (pctDiffR + pctDiffG + pctDiffB) / 3 * 100
}

/*
 * @function
 * @param {number} hexColor Required.
 * @param {number} allowance Required. Integer.
 * @param {number} completion. Required. Integer.
 * @param {number} x Required. Integer.
 * @param {number} y Required. Integer.
 * @param {number} delta Optional. Integer.
 * @returns {boolean} Returns true if picked colores has passed the criteria of approximate color, else false.
 */
isApproximateColor(hexColor, allowance, completion, x, y, delta) {
    passes := 0
    colorDifferences := []

    if (delta) {
        colorDifferences[0] := calcAverageOfColorDifference(hexColor, getColor(x, y))
        colorDifferences[1] := calcAverageOfColorDifference(hexColor, getColor(x - delta, y - delta))
        colorDifferences[2] := calcAverageOfColorDifference(hexColor, getColor(x, y - delta))
        colorDifferences[3] := calcAverageOfColorDifference(hexColor, getColor(x + delta, y - delta))
        colorDifferences[4] := calcAverageOfColorDifference(hexColor, getColor(x - delta, y))
        colorDifferences[5] := calcAverageOfColorDifference(hexColor, getColor(x + delta, y))
        colorDifferences[6] := calcAverageOfColorDifference(hexColor, getColor(x - delta, y + delta))
        colorDifferences[7] := calcAverageOfColorDifference(hexColor, getColor(x, y + delta))
        colorDifferences[8] := calcAverageOfColorDifference(hexColor, getColor(x + delta, y + delta))
        
        ;MsgBox, % colorDifferences[0]

        for i, Element in colorDifferences {
            if (Element < allowance) {
                passes++

                if (passes == completion) {
                    ;MsgBox, %passes% [passes]
                    return true
                }
            }
        }

        return false
    } else {
        colorDifferences[0] := calcAverageOfColorDifference(hexColor, getColor(x, y))

        if (colorDifferences[0] < allowance) {
            return true
        } else {
            return false
        }
    }
}

; isApproximateColor(0xFFFFFF, 100, 1, 200, 350, 2)





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
    global sleepDuration1
    global appProcess
    global isAssistDomesticAffairsEnabled
    global funds
    global oldFunds
    global fundsLimit
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
    isAssistDomesticAffairsRunning := false
}

executeDomesticAffairs(processType) {
    global sleepDuration1
    global sleepDuration2
    global isCommerceEnabled
    global isDevelopmentNewFieldsEnabled
    global isIndustriesEnabled
    global isMatchlocksProductionEnabled
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
    global sleepDuration1
    global mouseOffset1
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
    global isFixedAmountDraftEnabled
    global draftForGeneralSpinClicks
    global draftForCastleSpinClicks
    global isDraftDefenderMultipleEnabled
    global soldierUnit
    global draftDefenderAmount
    global isReturnsCursorFixedAmountDraft
    maxAllowed := 0
    actuallySpinClicks := 0

    if (!isFixedAmountDraftEnabled) {
        return
    }

    MouseGetPos, currentMouseXPos, currentMouseYPos 

    if (currentMouseYPos > 0 && currentMouseYPos < 330) {  ; Draft for general.
        MouseMove, 376, 299
        BlockInput, MouseMove
        Sleep, sleepDuration1
        Click, %draftForGeneralSpinClicks%
        BlockInput, MouseMoveOff
    } else if (currentMouseYPos > 299 && currentMouseYPos < 543) {  ; Defender draft.
        if (isDraftDefenderMultipleEnabled) {
            if (soldierUnit) {
                currentDefenders := getWindowText(22)
                maxAllowed := (Floor(currentDefenders / draftDefenderAmount) + 1) * draftDefenderAmount
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
                Click, %draftForCastleSpinClicks%
                BlockInput, MouseMoveOff
                Sleep, sleepDuration1
                currentDefenders := getWindowText(22)
                soldierUnit := % (currentDefenders - oldDefenders) / draftForCastleSpinClicks
                draftDefenderAmount := % soldierUnit * draftForCastleSpinClicks
            }
        } else {
            MouseMove, 303, 513
            BlockInput, MouseMove
            Sleep, sleepDuration1
            Click, %draftForCastleSpinClicks%
            BlockInput, MouseMoveOff
        }

    }

    if (isReturnsCursorFixedAmountDraft) {    
        MouseMove, %currentMouseXPos%, %currentMouseYPos%
    }
}

customMaxDraft() {
    global sleepDuration1
    global isCustomMaxDraftEnabled
    global isCustomDraftRunning
    global appProcess
    global targetNumberOfSoldiers
    global draftRemainLimit
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

fixedAmountSupplyHyoro() {
    global appProcess
    global sleepDuration1
    global isFixedAmountSupplyHyoroEnabled
    global isReturnsCursorFixedAmountSupplyHyoro
    global amountOfSupplyHyoro
    global isSupplyHyoroMultipleEnabled
    global isSupplyHyoroRunning
    currentAmount :=  ; Index is 8
    increaseAmount :=  ; Index is 3
    sliderBeginXPos := 73
    sliderEndXPos := 169
    sliderYPos := 313
    sliderStopXPos := 73
    sliderCurrentXPos :=
    plusSpinYPos := 276
    minusSpinYPos := 291
    10spinXPos := 177
    1spinXPos := 198

    if (!isFixedAmountSupplyHyoroEnabled) {
        return
    }
    
    isSupplyHyoroRunning := true

    if (isReturnsCursorFixedAmountSupplyHyoro) {    
        MouseGetPos, currentMouseXPos, currentMouseYPos
    }
    
    WinGetText, strings, %appProcess%
    supplyHyoroTexts := StrSplit(strings, "`r`n")
    increaseAmount := supplyHyoroTexts[3]
    currentAmount := supplyHyoroTexts[8]
    maxAmount := RegExReplace(supplyHyoroTexts[15], "[^0-9]+", "")  ; Regex for only numbers from a windw text with `Max nnnnn`.
    fullRemain := maxAmount - currentAmount + increaseAmount
    remain := maxAmount - currentAmount  ; How many more possible to supply are hyoro for a castle.

    if (remain == 0) {  ; Hyoro are full.
        isSupplyHyoroRunning := false
        return
    }

    if (isSupplyHyoroMultipleEnabled) {
        maxAllowed := (Floor(currentAmount / amountOfSupplyHyoro) + 1) * amountOfSupplyHyoro  ; Actually max amount.

        if (maxAllowed > maxAmount) {
            maxAllowed := maxAmount
        }

        modifiedAmountOfSupply := maxAllowed - currentAmount
        sliderRate := Round(modifiedAmountOfSupply / (remain + increaseAmount), 3)
        sliderCurrentXPos := % sliderBeginXPos + increaseAmount / fullRemain * (sliderEndXPos - sliderBeginXPos)

        if (sliderRate > 0.05) {  ; If amount of a slider movement is litte, don't use the sliedr.
            sliderStopXPos := % sliderCurrentXPos + sliderRate * (sliderEndXPos - sliderBeginXPos)
            MouseClickDrag, LEFT, %sliderCurrentXPos%, %sliderYPos%, %sliderStopXPos%, %sliderYPos%
            Sleep, sleepDuration1
            currentAmount := getWindowText(8)
        }
            
        numericalError := % maxAllowed - currentAmount

        if (numericalError == 0) {
            isSupplyHyoroRunning := false

            if (isReturnsCursorFixedAmountSupplyHyoro) {    
                MouseMove, %currentMouseXPos%, %currentMouseYPos%
            }
            return
        }

        if (numericalError < 0) {
            isNegativeNumber := true
            tensPlaceSpins := numericalError // -10
            onesPlaceSpins := Abs(Mod(numericalError, 10))
        } else {
            tensPlaceSpins := numericalError // 10
            onesPlaceSpins := Mod(numericalError, 10)
        }

        if (isNegativeNumber) {
            if (tensPlaceSpins) {
                MouseMove, %10spinXPos%, %minusSpinYPos%
                Sleep, sleepDuration1
                Click, %tensPlaceSpins%
                Sleep, sleepDuration1
            }

            if (onesPlaceSpins) {
                MouseMove, %1spinXPos%, %minusSpinYPos%
                Sleep, sleepDuration1
                Click, %onesPlaceSpins%
                Sleep, sleepDuration1
            }
        } else {
            if (tensPlaceSpins) {
                MouseMove, %10spinXPos%, %plusSpinYPos%
                Sleep, sleepDuration1
                Click, %tensPlaceSpins%
                Sleep, sleepDuration1
            }

            if (onesPlaceSpins) {
                MouseMove, %1spinXPos%, %plusSpinYPos%
                Sleep, sleepDuration1
                Click, %onesPlaceSpins%
                Sleep, sleepDuration1
            }
        }
    } else {        
        sliderRate := Round(amountOfSupplyHyoro / (remain + increaseAmount), 3)   
        sliderCurrentXPos := % sliderBeginXPos + increaseAmount / fullRemain * (sliderEndXPos - sliderBeginXPos)
        sliderStopXPos := % sliderCurrentXPos + sliderRate * (sliderEndXPos - sliderBeginXPos)
        MouseClickDrag, LEFT, %sliderCurrentXPos%, %sliderYPos%, %sliderStopXPos%, %sliderYPos%
        Sleep, sleepDuration1
    }

    if (isReturnsCursorFixedAmountSupplyHyoro) {    
        MouseMove, %currentMouseXPos%, %currentMouseYPos%
    }

    isSupplyHyoroRunning := false
}


maxSupplyHyoro() {
    global sleepDuration1
    global isMaxSupplyHyoroEnabled
    global isReturnsCursorMaxSupplyHyoro
    global isSupplyHyoroRunning
    sliderBeginXPos := 73
    sliderEndXPos := 169
    sliderYPos := 313

    if (!isMaxSupplyHyoroEnabled) {
        return
    }

    isSupplyHyoroRunning := true

    if (isReturnsCursorMaxSupplyHyoro) {
        MouseGetPos, currentMouseXPos, currentMouseYPos
        MouseMove, %sliderBeginXPos%, %sliderYPos%
        Sleep, sleepDuration1
        Click  ; To returns a thumb of slider to the left side.
        Sleep, sleepDuration1
        MouseClickDrag, LEFT, %sliderBeginXPos%, %sliderYPos%, %sliderEndXPos%, %sliderYPos%
        Sleep, sleepDuration1
        MouseMove, %currentMouseXPos%, %currentMouseYPos%
    } else {
        MouseMove, %sliderBeginXPos%, %sliderYPos%
        Sleep, sleepDuration1
        Click
        Sleep, sleepDuration1
        MouseClickDrag, LEFT, %sliderBeginXPos%, %sliderYPos%, %sliderEndXPos%, %sliderYPos%
    }

    isSupplyHyoroRunning := false
}

customManageCorpsFunds() {
    global sleepDuration1
    global isCustomManageCorpsFundsEnabled
    global isCustomManageCorpsFundsRunning
    global paymentAmount
    global collectionAmount
    global supplyMatchlockAmount

    if (!isCustomManageCorpsFundsEnabled) {
        return
    }

    WinGetText, strings, %appProcess% 
    corpsFundsTexts := StrSplit(strings, "`r`n")
    currentPaymentAmount := corpsFundsTexts[8]
    currentCollectionAmount := corpsFundsTexts[9]
    currentSupplyMatchlockAmount := corpsFundsTexts[16]
    inputXPos := 352
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
    if (!WinExist(appProcess) || !WinActive(appProcess)) {
        return
    }

    WinGetTitle, windowTitle, %appProcess%

    switch windowTitle {
        case "城攻略戦":
            if (isAswRunning) {
                ;MsgBox, "Stop ASW"
                isAswRunning := false
            }
        case "戦国史SE", "戦国史FE":
            save()
    }
    return

XButton1::  ; Main action button.
    if (!isExtensionEnabled || !WinExist(appProcess) || !WinActive(appProcess)) {
        return
    }

    WinGetTitle, windowTitle, %appProcess%

    switch windowTitle {
        case "徴兵":  ; Execuete a command of the fixed amount draft.
            fixedAmountDraft()
        case "城兵糧補充":
            if (!isSupplyHyoroRunning) {
                fixedAmountSupplyHyoro()
            }
        case "軍団資産":
            if (!isCustomManageCorpsFundsRunning) {
                customManageCorpsFunds()
            }
        case "野戦発生":
            if (!isAfbRunning) {
                MsgBox, "野戦発生"
                afb.jindate(1)  ; The supreme commander will be selected from a smallest unit of the commander. 
            }
        case "戦国史SE", "戦国史FE":
            phaseType := detectPhase()

            switch phaseType {
                case 1:  ; Personnel phase.
                case 2:  ; Armaments phase.
                case 3:  ; Domestic affairs phase.
                    assistDomesticAffairs()
                case 4:  ; Strategy phase.
                case 5:  ; Departure phase.
            }
    }
    return

XButton2::
    if (!isExtensionEnabled || !WinExist(appProcess) || !WinActive(appProcess)) {
        return
    }

    WinGetTitle, windowTitle, %appProcess%

    switch windowTitle {
        case "徴兵":  ; Execuete a command of the custom max draft. If the command is running, abort it.
            if (isCustomDraftRunning) {
                isCustomDraftRunning := false
            } else {
                customMaxDraft()
            }       
        case "城兵糧補充":
            if (!isSupplyHyoroRunning) {
                maxSupplyHyoro()
            }
        case "野戦発生":
            if (!isAswRunning) {
                asw.attack()
            }
        case "戦国史SE", "戦国史FE":
            phaseType := detectPhase()

            switch phaseType {
                case 1:  ; Personnel phase.
                case 2:  ; Armaments phase.
                case 3:  ; Domestic affairs phase.
                case 4:  ; Strategy phase.
                case 5:  ; Departure phase.
            }
    }
    return

; The following code is for the development and test.
Home::
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
    ;colorArray := [0x000000, 0xFFFFFF]
    ;colorArray := [0xFFFFFF]
    ;compareColors(colorArray, 641, 91, 2)
    ;afb.jindate(3)
    ;afb.test()
    ;afb.inputAction()
    ;afb.engage(3)
    asw.execute()
    return





Numpad1::
    afb.jindate(1)  ; 兵最少部隊総大将
    afb.engage(1)  ; 釣り出し交戦
    return

Numpad3::
    afb.jindate(3)  ; 指揮最大部隊総大将
    Sleep, 500
    afb.engage(3)  ; 通常交戦
    return

Numpad4::
    afb.jindate(1)  ; 指揮最大部隊総大将
    return

Numpad6::
    afb.jindate(3)  ; 指揮最大部隊総大将
    return

isMainWindow() {
    WinGetTitle, windowTitle, %appProcess%

    if (windowTitle == "戦国史SE" || windowTitle == "戦国史FE") {
        return true
    } else {
        return false
    }
}