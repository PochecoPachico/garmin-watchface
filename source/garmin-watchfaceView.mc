import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

// フラット文字盤ウォッチフェイス。
// アクティブ表示(高電力)では全目盛り・秒針を描画し、常時表示(低電力)では
// 主要目盛りのみを暗いトーンで描画して消費電力を抑える。
class garmin_watchfaceView extends WatchUi.WatchFace {

    // 常時表示の色は元デザインの半透明白(黒背景合成)を単色として事前計算したもの
    const COLOR_DIM             = 0x6B6B6B; // rgba(255,255,255,.42) 相当：数字/日付/DND/通知/バッテリー文字
    const COLOR_TICK_DIM        = 0x666666; // rgba(255,255,255,.40) 相当：常時表示の目盛り
    const COLOR_HAND_DIM        = 0x808080; // rgba(255,255,255,.50) 相当：常時表示の針・ハブ
    const COLOR_MINOR_TICK      = 0x6A6A6A; // アクティブ時のminor目盛り
    const COLOR_BATTERY_LOW     = 0xFF4A3D;
    const COLOR_BATTERY_LOW_DIM = 0x993933; // rgba(255,95,85,.6) 相当

    // レイアウト定数（416x416・中心半径208 基準）
    const TICK_RADIUS = 192;
    const TICK_MAJOR_LEN = 14;
    const TICK_MAJOR_LEN_DIM = 13;
    const TICK_MINOR_LEN = 7;

    const NUMERAL_RADIUS = 166;
    const DATE_RIGHT_OFFSET = 136;
    const DATE_WEEKDAY_GAP = 6;
    const TOP_ROW_OFFSET = 102;
    const BOTTOM_ROW_OFFSET = 106;

    const HOUR_HAND_LEN = 106;
    const HOUR_HAND_W = 7;
    const MIN_HAND_LEN = 155;
    const MIN_HAND_W = 5;
    const SEC_HAND_LEN = 176;
    const HUB_RADIUS = 6;
    const HUB_DOT_RADIUS = 2;

    const DND_OUTER_R = 11;
    const DND_INNER_R = 9;
    const ROW_GAP1 = 21;
    const ROW_GAP2 = 8;
    const NOTIF_ICON_W = 23;
    const PHONE_W = 13;
    const PHONE_H = 21;

    const BATTERY_W = 36;
    const BATTERY_H = 17;
    const BATTERY_GAP = 10;

    var isSleeping as Boolean = false;

    // カスタムビットマップフォント（fonts.xml参照）。drawTextはResourceIdを直接
    // 受け付けないため、WatchUi.loadResource()でFontReferenceとして事前ロードする。
    var numeralActiveFont as Graphics.FontReference;
    var numeralDimFont as Graphics.FontReference;
    var dateNumberFont as Graphics.FontReference;
    var weekdayFont as Graphics.FontReference;
    var smallActiveFont as Graphics.FontReference;
    var smallDimFont as Graphics.FontReference;

    function initialize() {
        WatchFace.initialize();

        numeralActiveFont = WatchUi.loadResource(Rez.Fonts.NumeralActive) as Graphics.FontReference;
        numeralDimFont = WatchUi.loadResource(Rez.Fonts.NumeralDim) as Graphics.FontReference;
        dateNumberFont = WatchUi.loadResource(Rez.Fonts.DateNumber) as Graphics.FontReference;
        weekdayFont = WatchUi.loadResource(Rez.Fonts.Weekday) as Graphics.FontReference;
        smallActiveFont = WatchUi.loadResource(Rez.Fonts.SmallActive) as Graphics.FontReference;
        smallDimFont = WatchUi.loadResource(Rez.Fonts.SmallDim) as Graphics.FontReference;
    }

    // カスタム描画のみのためレイアウトファイルは使用しない
    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        drawTicks(dc, centerX, centerY);
        drawNumerals(dc, centerX, centerY);
        drawDateWeekday(dc, centerX, centerY);
        drawTopRow(dc, centerX, centerY);
        drawBattery(dc, centerX, centerY);
        drawHands(dc, centerX, centerY);
    }

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

    //// ---------------------------------------------------------------
    //// 文字盤（目盛り・数字）
    //// ---------------------------------------------------------------

    // 60分割の目盛りを描画。12/3/6/9(cardinal)は数字で表すため目盛りを省略し、
    // 常時表示ではmajor(5分ごと)のみを暗い色で描画する。
    function drawTicks(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        for (var i = 0; i < 60; i += 1) {
            if (i % 15 == 0) {
                continue;
            }
            var isMajor = (i % 5 == 0);
            if (isSleeping && !isMajor) {
                continue;
            }

            var angle = (i / 60.0) * Math.PI * 2 - (Math.PI / 2);
            var cosA = Math.cos(angle);
            var sinA = Math.sin(angle);

            var len;
            var color;
            if (isSleeping) {
                len = TICK_MAJOR_LEN_DIM;
                color = COLOR_TICK_DIM;
            } else if (isMajor) {
                len = TICK_MAJOR_LEN;
                color = Graphics.COLOR_WHITE;
            } else {
                len = TICK_MINOR_LEN;
                color = COLOR_MINOR_TICK;
            }

            var midX = centerX + TICK_RADIUS * cosA;
            var midY = centerY + TICK_RADIUS * sinA;
            var dx = (len / 2.0) * cosA;
            var dy = (len / 2.0) * sinA;

            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isMajor ? 3 : 2);
            dc.drawLine(midX - dx, midY - dy, midX + dx, midY + dy);
        }
    }

    // 12/3/6/9 の数字
    function drawNumerals(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var color = isSleeping ? COLOR_DIM : Graphics.COLOR_WHITE;
        var font = isSleeping ? numeralDimFont : numeralActiveFont;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - NUMERAL_RADIUS, font, "12", justify);
        dc.drawText(centerX, centerY + NUMERAL_RADIUS, font, "6", justify);
        dc.drawText(centerX - NUMERAL_RADIUS, centerY, font, "9", justify);
        dc.drawText(centerX + NUMERAL_RADIUS, centerY, font, "3", justify);
    }

    //// ---------------------------------------------------------------
    //// 情報表示（日付・DND・通知・バッテリー）
    //// ---------------------------------------------------------------

    // 曜日・日付。3の内側に右揃えで配置する。ウェイトもサイズも異なる（曜日=SemiBold/小さめ、
    // 日付=Regular/大きめ）ため別フォント・別drawTextで描画し、日付を基準に曜日を左側へ詰める。
    // 高さの異なる2フォントを揃えるため、VCENTERではなく共通の下端(bottomY)に揃えて配置する。
    function drawDateWeekday(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var color = isSleeping ? COLOR_DIM : Graphics.COLOR_WHITE;
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var weekday = (info.day_of_week as String).toUpper();
        var dateStr = info.day.format("%02d");
        var rightX = centerX + DATE_RIGHT_OFFSET;

        var dateFontHeight = dc.getFontHeight(dateNumberFont);
        var weekdayFontHeight = dc.getFontHeight(weekdayFont);
        var bottomY = centerY + dateFontHeight / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, bottomY - dateFontHeight, dateNumberFont, dateStr, Graphics.TEXT_JUSTIFY_RIGHT);

        var dateWidth = dc.getTextWidthInPixels(dateStr, dateNumberFont);
        dc.drawText(rightX - dateWidth - DATE_WEEKDAY_GAP, bottomY - weekdayFontHeight, weekdayFont, weekday, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // スマホ接続 + おやすみモード + 通知アイコン + 件数を中心上部に一列で配置する。
    // 各要素は該当時のみ表示し（スマホ=未接続、DND=ON、通知=1件以上）、
    // 表示される要素だけで合計幅を求めて中心（縦の中央線）に揃える。
    function drawTopRow(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var settings = System.getDeviceSettings();
        var color = isSleeping ? COLOR_DIM : Graphics.COLOR_WHITE;
        var rowY = centerY - TOP_ROW_OFFSET;
        var font = isSleeping ? smallDimFont : smallActiveFont;

        var showPhone = !settings.phoneConnected;
        var showDnd = settings.doNotDisturb;
        var showNotif = settings.notificationCount > 0;

        var countStr = settings.notificationCount.toString();
        var dndW = DND_OUTER_R * 2;
        var notifW = NOTIF_ICON_W + ROW_GAP2 + dc.getTextWidthInPixels(countStr, font);

        var totalWidth = 0;
        var itemCount = 0;
        if (showPhone) {
            totalWidth += PHONE_W;
            itemCount += 1;
        }
        if (showDnd) {
            totalWidth += dndW;
            itemCount += 1;
        }
        if (showNotif) {
            totalWidth += notifW;
            itemCount += 1;
        }
        if (itemCount == 0) {
            return;
        }
        totalWidth += ROW_GAP1 * (itemCount - 1);
        var cursorX = centerX - totalWidth / 2;

        if (showPhone) {
            drawPhoneIcon(dc, cursorX, rowY, color);
            cursorX += PHONE_W + ROW_GAP1;
        }

        if (showDnd) {
            drawDnd(dc, cursorX + DND_OUTER_R, rowY, color);
            cursorX += dndW + ROW_GAP1;
        }

        if (showNotif) {
            var iconIndex = Application.Properties.getValue("NotificationIcon") as Number;
            drawNotifIcon(dc, cursorX, rowY, NOTIF_ICON_W, iconIndex, color);
            cursorX += NOTIF_ICON_W + ROW_GAP2;

            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cursorX, rowY, font, countStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // スマホ未接続アイコン（縦長の端末 + 下部のホームボタン + 斜線）。xは左端、cyは縦中心。
    function drawPhoneIcon(dc as Dc, x as Numeric, cy as Numeric, color as Numeric) as Void {
        var top = cy - PHONE_H / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(x, top, PHONE_W, PHONE_H, 3);
        dc.fillRectangle(x + PHONE_W / 2 - 2, top + PHONE_H - 5, 4, 2);

        // 斜線。背景色の太線で端末の輪郭を切ってから細線を重ね、線同士を分離して見せる
        var x1 = x - 3;
        var y1 = top - 1;
        var x2 = x + PHONE_W + 3;
        var y2 = top + PHONE_H + 1;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(x1, y1, x2, y2);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, y1, x2, y2);
    }

    // おやすみモードを三日月で描画。cx,cyは外側の円の中心。
    function drawDnd(dc as Dc, cx as Numeric, cy as Numeric, color as Numeric) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, DND_OUTER_R);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 7, cy - 2, DND_INNER_R);
    }

    // 通知アイコン（設定で envelope/bell/bubble を選択）。x,yはアイコン領域の左上、wは領域幅。
    function drawNotifIcon(dc as Dc, x as Numeric, y as Numeric, w as Numeric, iconIndex as Numeric, color as Numeric) as Void {
        if (iconIndex == 1) {
            drawBellIcon(dc, x, y, w, color);
        } else if (iconIndex == 2) {
            drawBubbleIcon(dc, x, y, w, color);
        } else {
            drawEnvelopeIcon(dc, x, y, w, color);
        }
    }

    // 封筒アイコン
    function drawEnvelopeIcon(dc as Dc, x as Numeric, y as Numeric, w as Numeric, color as Numeric) as Void {
        var h = 15;
        var top = y - h / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(x, top, w, h, 2);
        dc.drawLine(x + 1, top + 1, x + w / 2, top + h / 2 + 2);
        dc.drawLine(x + w - 1, top + 1, x + w / 2, top + h / 2 + 2);
    }

    // ベルアイコン
    function drawBellIcon(dc as Dc, x as Numeric, y as Numeric, w as Numeric, color as Numeric) as Void {
        var cx = x + w / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawArc(cx, y + 2, 7, Graphics.ARC_CLOCKWISE, 165, 15);
        dc.fillRectangle(cx - 9, y + 1, 18, 2);
        dc.fillCircle(cx, y + 7, 2);
    }

    // 吹き出しアイコン（塗りつぶし）
    function drawBubbleIcon(dc as Dc, x as Numeric, y as Numeric, w as Numeric, color as Numeric) as Void {
        var h = 15;
        var top = y - h / 2;
        var bw = w - 3;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, top, bw, h, 4);

        var tailX = x + 4;
        var tailY = top + h - 1;
        var tail = [[tailX, tailY], [tailX + 7, tailY], [tailX - 2, tailY + 7]];
        dc.fillPolygon(tail);
    }

    // バッテリー残量（アイコン + パーセント）。20%以下は赤系で警告表示。
    function drawBattery(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var battery = System.getSystemStats().battery.toNumber();
        var low = battery <= 20;

        var textColor = isSleeping ? COLOR_DIM : Graphics.COLOR_WHITE;
        var outlineColor = isSleeping ? COLOR_TICK_DIM : COLOR_MINOR_TICK;
        var fillColor;
        if (low) {
            fillColor = isSleeping ? COLOR_BATTERY_LOW_DIM : COLOR_BATTERY_LOW;
        } else {
            fillColor = isSleeping ? COLOR_HAND_DIM : Graphics.COLOR_WHITE;
        }

        var font = isSleeping ? smallDimFont : smallActiveFont;

        // 桁数に応じた実際の文字幅で計算し、アイコン+数字+%の合計幅が常に中央になるようにする
        var batteryStr = battery.toString() + "%";
        var textWidth = dc.getTextWidthInPixels(batteryStr, font);
        var totalWidth = BATTERY_W + 3 + BATTERY_GAP + textWidth;
        var rowY = centerY + BOTTOM_ROW_OFFSET;
        var batX = centerX - totalWidth / 2;
        var batY = rowY - BATTERY_H / 2;

        dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(batX, batY, BATTERY_W, BATTERY_H, 3);

        var termH = BATTERY_H / 2;
        dc.fillRectangle(batX + BATTERY_W + 1, batY + (BATTERY_H - termH) / 2, 3, termH);

        var fillW = ((battery / 100.0) * (BATTERY_W - 4)).toNumber();
        if (fillW > 0) {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(batX + 2, batY + 2, fillW, BATTERY_H - 4);
        }

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(batX + BATTERY_W + 3 + BATTERY_GAP, rowY, font, batteryStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //// ---------------------------------------------------------------
    //// 針
    //// ---------------------------------------------------------------

    // 時針・分針（白/常時は暗色）と秒針（アクセントカラー、アクティブ時のみ）、中心ハブを描画。
    function drawHands(dc as Dc, centerX as Numeric, centerY as Numeric) as Void {
        var clockTime = System.getClockTime();
        var handColor = isSleeping ? COLOR_HAND_DIM : Graphics.COLOR_WHITE;
        var accentColor = Application.Properties.getValue("AccentColor") as Number;

        var hourFraction = (clockTime.hour % 12) + (clockTime.min / 60.0);
        var hourAngle = (hourFraction / 12.0) * Math.PI * 2 - (Math.PI / 2);
        var minAngle = (clockTime.min / 60.0) * Math.PI * 2 - (Math.PI / 2);

        dc.setColor(handColor, Graphics.COLOR_TRANSPARENT);
        drawStraightHand(dc, centerX, centerY, hourAngle, HOUR_HAND_LEN, HOUR_HAND_W);
        drawStraightHand(dc, centerX, centerY, minAngle, MIN_HAND_LEN, MIN_HAND_W);

        var showSecondHand = Application.Properties.getValue("ShowSecondHand") as Boolean;
        if (!isSleeping && showSecondHand) {
            var secAngle = (clockTime.sec / 60.0) * Math.PI * 2 - (Math.PI / 2);
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            drawStraightHand(dc, centerX, centerY, secAngle, SEC_HAND_LEN, 2);
        }

        var hubColor = isSleeping ? COLOR_HAND_DIM : accentColor;
        dc.setColor(hubColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, HUB_RADIUS);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, HUB_DOT_RADIUS);
    }

    // 中心から一方向に伸びる矩形の針（デザインに合わせ先細りなしの均一幅）
    function drawStraightHand(dc as Dc, centerX as Numeric, centerY as Numeric, angle as Float, length as Numeric, width as Numeric) as Void {
        var perpAngle = angle + (Math.PI / 2);
        var px = Math.cos(perpAngle) * (width / 2.0);
        var py = Math.sin(perpAngle) * (width / 2.0);
        var tipX = centerX + length * Math.cos(angle);
        var tipY = centerY + length * Math.sin(angle);

        var points = [
            [centerX + px, centerY + py],
            [tipX + px, tipY + py],
            [tipX - px, tipY - py],
            [centerX - px, centerY - py]
        ];
        dc.fillPolygon(points);
    }

}
