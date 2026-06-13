import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class garmin_watchfaceView extends WatchUi.WatchFace {

    // レイアウト用の基準Y座標
    const TOP_Y = 110;    // 曜日/日付・バッテリーの行
    const BOTTOM_Y = 300; // おやすみモード・通知の行
    const ROW_GAP = 10;  // 行内の要素間のマージン

    var isSleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // 画面を黒でリセット
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var x = centerX;

        // 1. 背景のメモリを描画
        drawDial(dc, centerX, centerY);

        // 2. 各種コンポーネントを描画
        drawTopRow(dc, x);    // 曜日/日付 + バッテリー残量
        drawBottomRow(dc, x); // おやすみモード + 通知件数

        // 3. 針を描画
        drawHands(dc, centerX, centerY);
    }

    // 文字盤のメモリ（インデックス）を描画
    function drawDial(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        for (var i = 0; i < 60; i += 1) {
            var angle = (i / 60.0) * Math.PI * 2 - (Math.PI / 2);

            var isHourTick = (i % 5 == 0);
            var innerRadius = isHourTick ? 180 : 195;
            var outerRadius = 205;

            var startX = centerX + (innerRadius * Math.cos(angle));
            var startY = centerY + (innerRadius * Math.sin(angle));
            var endX = centerX + (outerRadius * Math.cos(angle));
            var endY = centerY + (outerRadius * Math.sin(angle));

            dc.setColor(isHourTick ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isHourTick ? 4 : 2);
            dc.drawLine(startX, startY, endX, endY);
        }
    }

    // 上段：曜日/日付とバッテリー残量を左右に並べて描画
    function drawTopRow(dc as Dc, x as Numeric) as Void {
        var dateString = getDateString();
        var dateWidth = dc.getTextWidthInPixels(dateString, Graphics.FONT_XTINY);
        var batteryWidth = getBatteryWidth(dc);

        // 日付＋マージン＋バッテリー全体を x を中心に配置
        var totalWidth = dateWidth + ROW_GAP + batteryWidth;
        var leftX = x - totalWidth / 2;

        drawDate(dc, leftX, dateString);
        drawBattery(dc, leftX + dateWidth + ROW_GAP);
    }

    // 下段：おやすみモードと通知件数を並べて描画
    function drawBottomRow(dc as Dc, x as Numeric) as Void {
        var notificationIconX = getNotificationIconX(dc, x);
        drawNotification(dc, notificationIconX);
        drawDoNotDisturb(dc, notificationIconX);
    }

    // 曜日と日付の文字列を取得（例: "Sat 13"）
    function getDateString() as String {
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_MEDIUM);
        return Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]);
    }

    // 曜日と日付を描画
    // leftX: テキスト左端のX座標
    function drawDate(dc as Dc, leftX as Numeric, dateString as String) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, TOP_Y, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // バッテリー残量テキストの最大幅（"100%"基準）を計算
    // 桁数が変化してもレイアウトが動かないよう、常にこの幅を確保する
    function getBatteryTextMaxWidth(dc as Dc) as Numeric {
        return dc.getTextWidthInPixels("100%", Graphics.FONT_XTINY);
    }

    // バッテリー表示（テキスト＋アイコン）全体の幅を計算
    function getBatteryWidth(dc as Dc) as Numeric {
        var textWidth = getBatteryTextMaxWidth(dc);

        var batW = 32;
        var margin = 8; // %とアイコンの間のマージン
        var terminalW = 3;
        return textWidth + margin + batW + terminalW;
    }

    // バッテリー残量のアイコンとテキストを描画
    // leftX: テキスト表示領域の左端のX座標
    function drawBattery(dc as Dc, leftX as Numeric) as Void {
        var stats = System.getSystemStats();
        var battery = stats.battery.toNumber();

        var batH = 18;
        var batW = 32;
        var margin = 8; // %とアイコンの間のマージン

        var batteryString = battery.toString() + "%";
        var textMaxWidth = getBatteryTextMaxWidth(dc);
        var textRightX = leftX + textMaxWidth;

        var batX = textRightX + margin;
        var batY = TOP_Y - batH / 2;

        // テキスト描画（右端揃え・縦中央）：桁数が変わってもアイコン位置が動かないようにする
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textRightX, TOP_Y, Graphics.FONT_XTINY, batteryString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // バッテリー外枠
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(batX, batY, batW, batH);

        // 端子（右側の出っ張り）
        var termH = batH / 2;
        dc.fillRectangle(batX + batW, batY + (batH - termH) / 2, 3, termH);

        // 残量に応じた色設定
        if (battery <= 20) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else if (battery <= 30) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        }

        // 残量の中身
        var fillWidth = ((battery / 100.0) * (batW - 4)).toNumber();
        if (fillWidth > 0) {
            dc.fillRectangle(batX + 2, batY + 2, fillWidth, batH - 4);
        }
    }

    // 通知アイコン（吹き出し＋件数）の左端X座標を計算
    // x を中心に、アイコン＋マージン＋件数テキストの全体が中央揃えになるようにする
    function getNotificationIconX(dc as Dc, x as Numeric) as Numeric {
        var settings = System.getDeviceSettings();
        var msgString = settings.notificationCount.toString();
        var textWidth = dc.getTextWidthInPixels(msgString, Graphics.FONT_XTINY);

        var iconW = 22;
        var margin = 10; // アイコンとテキストの間のマージン

        var totalWidth = iconW + margin + textWidth;
        return x - totalWidth / 2;
    }

    // スマホ通知件数を吹き出しアイコンと共に描画
    // iconX: アイコン左端のX座標（getNotificationIconXで算出）
    function drawNotification(dc as Dc, iconX as Numeric) as Void {
        var settings = System.getDeviceSettings();
        var msgString = settings.notificationCount.toString();
        var iconY = BOTTOM_Y;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(iconX, iconY, 22, 16, 5);

        var tail = [
            [iconX + 5, iconY + 15],
            [iconX + 12, iconY + 15],
            [iconX + 2, iconY + 22]
        ];
        dc.fillPolygon(tail);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(iconX + 32, iconY - 7, Graphics.FONT_XTINY, msgString, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // おやすみモード（Do Not Disturb）の状態を月のアイコンで描画
    // iconX: 通知アイコン左端のX座標。その左隣に並べて配置する
    function drawDoNotDisturb(dc as Dc, iconX as Numeric) as Void {
        var settings = System.getDeviceSettings();
        if (!settings.doNotDisturb) {
            return;
        }

        var iconY = BOTTOM_Y;

        // 通知アイコンの左側に並べて配置（吹き出しアイコンと同程度の大きさに）
        var moonR = 11;
        var margin = 8; // 吹き出しアイコンとの間のマージン
        var moonCenterX = iconX - margin - moonR;
        var moonCenterY = iconY + moonR; // 吹き出しアイコンと上端を揃える

        // 月（クレセント）を描画：満円から右上をくり抜く
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(moonCenterX, moonCenterY, moonR);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(moonCenterX + 6, moonCenterY - 6, moonR);
    }

    // 先細りの剣形ポリゴン針を描画
    // angle: 針の向き（ラジアン）, length: 針の長さ, baseWidth: 根本の太さ, tipWidth: 先端の太さ
    function drawTaperedHand(dc as Dc, centerX as Numeric, centerY as Numeric, angle as Float, length as Numeric, baseWidth as Numeric, tipWidth as Numeric) as Void {
        var perpAngle = angle + (Math.PI / 2);
        var perpX = Math.cos(perpAngle);
        var perpY = Math.sin(perpAngle);

        var tipX = centerX + (length * Math.cos(angle));
        var tipY = centerY + (length * Math.sin(angle));

        var points = [
            [centerX + (baseWidth / 2) * perpX, centerY + (baseWidth / 2) * perpY],
            [tipX + (tipWidth / 2) * perpX, tipY + (tipWidth / 2) * perpY],
            [tipX - (tipWidth / 2) * perpX, tipY - (tipWidth / 2) * perpY],
            [centerX - (baseWidth / 2) * perpX, centerY - (baseWidth / 2) * perpY]
        ];

        dc.fillPolygon(points);
    }

    // 時針・分針・秒針と中心ピニオンを描画
    function drawHands(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var clockTime = System.getClockTime();

        var hourFraction = (clockTime.hour % 12) + (clockTime.min / 60.0);
        var hourAngle = (hourFraction / 12.0) * Math.PI * 2 - (Math.PI / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawTaperedHand(dc, centerX, centerY, hourAngle, 110, 14, 4);

        var minAngle = (clockTime.min / 60.0) * Math.PI * 2 - (Math.PI / 2);
        drawTaperedHand(dc, centerX, centerY, minAngle, 160, 9, 3);

        if (!isSleeping) {
            var secAngle = (clockTime.sec / 60.0) * Math.PI * 2 - (Math.PI / 2);
            var secRadius = 170;

            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            var secX = centerX + (secRadius * Math.cos(secAngle));
            var secY = centerY + (secRadius * Math.sin(secAngle));
            dc.drawLine(centerX, centerY, secX, secY);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 8);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isSleeping = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleeping = true;
        WatchUi.requestUpdate();
    }

}
