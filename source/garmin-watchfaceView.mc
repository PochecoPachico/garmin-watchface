import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class garmin_watchfaceView extends WatchUi.WatchFace {

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
    function onUpdate(dc) {
        // 画面を黒でリセット
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var x = centerX;
        var y = centerY;

        // 1. 背景のメモリを描画
        drawDial(dc, centerX, centerY);

        // 2. 各種コンポーネントを描画
        drawBattery(dc, x, y);
        drawNotification(dc, x, y);
        drawDate(dc, x, y);

        // 3. 針を描画
        drawHands(dc, centerX, centerY);
    }

    // 文字盤のメモリ（インデックス）を描画
    function drawDial(dc, centerX, centerY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < 60; i += 1) {
            var angle = (i / 60.0) * Math.PI * 2 - (Math.PI / 2);

            var isHourTick = (i % 5 == 0);
            var innerRadius = isHourTick ? 180 : 195;
            var outerRadius = 205;

            var startX = centerX + (innerRadius * Math.cos(angle));
            var startY = centerY + (innerRadius * Math.sin(angle));
            var endX = centerX + (outerRadius * Math.cos(angle));
            var endY = centerY + (outerRadius * Math.sin(angle));

            dc.setPenWidth(isHourTick ? 4 : 2);
            dc.drawLine(startX, startY, endX, endY);
        }
    }

    // バッテリー残量のアイコンとテキストを描画
    // x, y: テキスト＋マージン＋アイコン全体の中心座標
    function drawBattery(dc, x, y) {
        var stats = System.getSystemStats();
        var battery = stats.battery.toNumber();

        var batH = 18;
        var batW = 32;
        var margin = 8; // %とアイコンの間のマージン
        var batCenterY = 328;

        var batteryString = battery.toString() + "%";
        var textWidth = dc.getTextWidthInPixels(batteryString, Graphics.FONT_XTINY);

        // 全体幅 = テキスト + マージン + アイコン + 端子(3px)
        var totalWidth = textWidth + margin + batW + 3;

        // x が全体の中心なので各要素のX座標を計算
        var textRightX = x - totalWidth / 2 + textWidth;
        var batX = textRightX + margin;
        var batY = batCenterY - batH / 2;

        // テキスト描画（右端揃え・縦中央）
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textRightX, batCenterY, Graphics.FONT_XTINY, batteryString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

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

    // スマホ通知件数を吹き出しアイコンと共に描画
    function drawNotification(dc, x, y) {
        var settings = System.getDeviceSettings();
        var msgString = settings.notificationCount.toString();

        var iconX = x - 30;
        var iconY = 275;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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

    // 日付と曜日を描画
    function drawDate(dc, x, y) {
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, 80, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // 時針・分針・秒針と中心ピニオンを描画
    function drawHands(dc, centerX, centerY) {
        var clockTime = System.getClockTime();

        var hourFraction = (clockTime.hour % 12) + (clockTime.min / 60.0);
        var hourAngle = (hourFraction / 12.0) * Math.PI * 2 - (Math.PI / 2);
        var hourRadius = 110;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8);
        var hourX = centerX + (hourRadius * Math.cos(hourAngle));
        var hourY = centerY + (hourRadius * Math.sin(hourAngle));
        dc.drawLine(centerX, centerY, hourX, hourY);

        var minAngle = (clockTime.min / 60.0) * Math.PI * 2 - (Math.PI / 2);
        var minRadius = 160;

        dc.setPenWidth(5);
        var minX = centerX + (minRadius * Math.cos(minAngle));
        var minY = centerY + (minRadius * Math.sin(minAngle));
        dc.drawLine(centerX, centerY, minX, minY);

        var secAngle = (clockTime.sec / 60.0) * Math.PI * 2 - (Math.PI / 2);
        var secRadius = 170;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var secX = centerX + (secRadius * Math.cos(secAngle));
        var secY = centerY + (secRadius * Math.sin(secAngle));
        dc.drawLine(centerX, centerY, secX, secY);

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
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
