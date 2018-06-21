using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

class larsRunView extends Ui.DataField {
    hidden var fields;

    function initialize() {
    	DataField.initialize();
        fields = new larsRunFields(); 
    }

    function onLayout(dc) {
    }

    function onShow() {
    }

    function onHide() {
    }

    function drawLayout(dc) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_WHITE);
        // horizontal lines
        dc.drawLine(0, 80, 218, 80);
        dc.drawLine(0, 142, 218, 142);
        dc.drawLine(0, 213, 218, 213);
        // vertical lines
        dc.drawLine(120, 0, 120, 71);
        //dc.drawLine(65, 71, 65, 132);
        dc.drawLine(120, 71, 120, 132);
        dc.drawLine(120, 132, 120, 213);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();

		//avg HR
        textC(dc, 75, 60, Graphics.FONT_NUMBER_MEDIUM, fields.avgHR);
        textC(dc, 75, 28, Graphics.FONT_XTINY,  "Avg HR");
       
		//pace 10s
        textC(dc, 162, 60, Graphics.FONT_NUMBER_MEDIUM,  fields.pace10s);
        textC(dc, 155, 28, Graphics.FONT_XTINY, "P 10s");
	 
		//timer
        textC(dc, 70, 122, Graphics.FONT_NUMBER_MEDIUM,  fields.timer);
        if (fields.timerSecs != null) {
            var length = dc.getTextWidthInPixels(fields.timer, Graphics.FONT_NUMBER_MEDIUM);
            textC(dc, 70 + length + 1, 122, Graphics.FONT_NUMBER_MILD, fields.timerSecs);
        }

        textC(dc, 75, 90, Graphics.FONT_XTINY,  "TIMER");

		//cadence - remove
		/*
        doCadenceBackground(dc, fields.cadenceN);
        textC(dc, 30, 107, Graphics.FONT_NUMBER_MEDIUM, fields.cadence);
        textC(dc, 30, 79, Graphics.FONT_XTINY,  "CAD");
		*/
		
		//heartrate
        doHrBackground(dc, fields.hrN);
        textC(dc, 155, 122, Graphics.FONT_NUMBER_MEDIUM, fields.hr);
        textC(dc, 157, 90, Graphics.FONT_XTINY,  "HR");

		//distance
        textC(dc, 66, 169, Graphics.FONT_NUMBER_MEDIUM, fields.dist);
        textL(dc, 54, 201, Graphics.FONT_XTINY, "DIST");

		//GAP 10s
        textC(dc, 163, 169, Graphics.FONT_NUMBER_MEDIUM, fields.gap);
        textL(dc, 124, 201, Graphics.FONT_XTINY, "GAP 10s");

		//time
        textL(dc, 75, 223, Graphics.FONT_TINY, fields.time);
        drawBattery(dc);
        drawLayout(dc);
        return true;
    }

    function doHrBackground(dc, hr) {
        if (hr == null) {
            return;
        }

        var color;
        if (hr >= 154) {
            color = Graphics.COLOR_PURPLE;
        } else if (hr > 139) {
            color = Graphics.COLOR_RED;
        } else if (hr > 134) {
            color = Graphics.COLOR_YELLOW;
        } else if (hr > 120) {
            color = Graphics.COLOR_GREEN;
        } else {
            color = Graphics.COLOR_BLUE;
        }

		//fix spacing
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        //dc.fillRectangle(154, 72, 65, 16);
        dc.fillRectangle(128, 83, 65, 16);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
/*
    function doCadenceBackground(dc, cadence) {
        if (cadence == null) {
            return;
        }

        var color;
        if (cadence > 183) {
            color = Graphics.COLOR_PURPLE;
        } else if (cadence >= 174) {
            color = Graphics.COLOR_BLUE;
        } else if (cadence >= 164) {
            color = Graphics.COLOR_GREEN;
        } else if (cadence >= 153) {
            color = Graphics.COLOR_ORANGE;
        } else {
            color = Graphics.COLOR_RED;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(00, 72, 65, 16);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
    */

    function drawBattery(dc) {
        var pct = Sys.getSystemStats().battery;
        dc.drawRectangle(130, 222, 18, 11);
        dc.fillRectangle(148, 225, 2, 5);

        var color = Graphics.COLOR_GREEN;
        if (pct < 25) {
            color = Graphics.COLOR_RED;
        } else if (pct < 40) {
            color = Graphics.COLOR_YELLOW;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var width = (pct * 16.0 / 100 + 0.5).toLong();
        if (width > 0) {
            //Sys.println("" + pct + "=" + width);
            if (width > 16) {
                width = 16;
            }
            dc.fillRectangle(131, 223, width, 9);
        }
    }

    function compute(info) {
        fields.compute(info);
        return 1;
    }

    function textL(dc, x, y, font, s) {
        if (s != null) {
            dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function textC(dc, x, y, font, s) {
        if (s != null) {
            dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function textR(dc, x, y, font, s) {
        if (s != null) {
            dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
