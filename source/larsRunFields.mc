using Toybox.Time as Time;
using Toybox.System as Sys;


class larsRunFields {
    // last 60 seconds - 'current speed' samples
    hidden var lastSecs = new [60];
    hidden var curPos;
    const METERS_TO_MILES = 0.000621371;
    
    // public fields - usable after the user calls compute
    var dist;
    var hr;
    var hrN;
    var timer;
    var timerSecs;
    var pace10s;
    var paceAvg;
    var time;
    var gap;
    var avgHR;
    
    //GAP calc - 10 samples
    var altitudes = new[10];
	var distances = new [10];
    

    function initialize() {
        for (var i = 0; i < lastSecs.size(); ++i) {
            lastSecs[i] = 0.0;
        }

        curPos = 0;
        
        for (var i = 0; i < altitudes.size(); i++) {
        	altitudes[i] = 0.0; 
        	distances[i] = 0.0;
        }
    }

    function getAverage(a) {
        var count = 0;
        var sum = 0.0;
        for (var i = 0; i < a.size(); ++i) {
            if (a[i] > 0.0) {
                count++;
                sum += a[i];
            }
        }
        if (count > 0) {
            return sum / count;
        } else {
            return null;
        }
    }

    function getNAvg(a, curIdx, n) {
        var start = curIdx - n;
        if (start < 0) {
            start += a.size();
        }
        var count = 0;
        var sum = 0.0;
        for (var i = start; i < (start + n); ++i) {
            var idx = i % a.size();
            if (a[idx] > 0.0) {
                count++;
                sum += a[idx];
            }
        }
        if (count > 0) {
            return sum / count;
        } else {
            return null;
        }
    }

    function toPace(speed) {
        if (speed == null || speed == 0) {
            return null;
        }


        var settings = Sys.getDeviceSettings();
        var unit = 1609; // miles
        if (settings.paceUnits == Sys.UNIT_METRIC) {
            unit = 1000; // km
        }
        return unit / speed;
    }

    function toDist(d) {
        if (d == null) {
            return "0.00";
        }

        var dist;
        if (Sys.getDeviceSettings().distanceUnits == Sys.UNIT_METRIC) {
            dist = d / 1000.0;
        } else {
            dist = d / 1609.0;
        }
        return dist.format("%.2f");
    }

    function toStr(o) {
        if (o != null) {
            return "" + o;
        } else {
            return "---";
        }
    }

    function fmtSecs(secs) {
        if (secs == null) {
            return "--:--";
        }

        var s = secs.toLong();
        var hours = s / 3600;
        s -= hours * 3600;
        var minutes = s / 60;
        s -= minutes * 60;
        var fmt;
        if (hours > 0) {
            fmt = "" + hours + ":" + minutes.format("%02d");
        } else {
            fmt = "" + minutes + ":" + s.format("%02d");
        }

        return fmt;
    }

    function fmtTime(clock) {
        var h = clock.hour;
        if (!Sys.getDeviceSettings().is24Hour) {
            if (h > 12) {
                h -= 12;
            } else if (h == 0) {
                h += 12;
            }
        }
        return "" + h + ":" + clock.min.format("%02d");
    }

    function compute(info) {
        if (info.currentSpeed != null && info.currentSpeed > 0) {
            var idx = curPos % lastSecs.size();
            curPos++;
            lastSecs[idx] = info.currentSpeed;
        }

        var avg10s = getNAvg(lastSecs, curPos, 10);
        
        //store altitude and distance for a number of samples
        if ( info.altitude != null && info.elapsedDistance != null ) {
         	
	    	for (var i = altitudes.size() - 2; i >= 0 ; i--) {
	    		altitudes[i+1] = altitudes[i];
	    		distances[i+1] = distances[i];
	    	}
	    	
	    	altitudes[0] = info.altitude;
	    	distances[0] = info.elapsedDistance;
	    }
	    	
        //distance, time, avgSpeed, avg10s        
        var elapsed = info.elapsedTime;
        var elapsedSecs = null;

        if (elapsed != null) {
            elapsed /= 1000;

            if (elapsed >= 3600) {
                elapsedSecs = (elapsed.toLong() % 60).format("%02d");
            }
        }

        dist = toDist(info.elapsedDistance);
        hr = toStr(info.currentHeartRate);
        hrN = info.currentHeartRate;
        timer = fmtSecs(elapsed);
        timerSecs = elapsedSecs;
        pace10s =  fmtSecs(toPace(avg10s));
        paceAvg = fmtSecs(toPace(info.averageSpeed));
        time = fmtTime(Sys.getClockTime());
        avgHR = toStr(info.averageHeartRate);
        
        //GAP
    	gap = fmtSecs(toPace(calcGap(info.currentSpeed, calcGrade())));
    }
    
    function calcGrade() {
    	//System.println("calcGrade: entered");
    	
    	var altDelta = 0;
    	var distDelta = 0;
    	var delta = 0;
    	var count = 0;
    	
    	//use buffer data to determine rolling grade
    	for (var i = 0; i < altitudes.size() -2; i++ ) {
    			delta = (distances[i] - distances[i+1]);
    			//make sure we're moving
    			if ( delta != 0 ) {
	    			distDelta += delta;
	    			
	    			delta = (altitudes[i] - altitudes[i+1]);
	    			altDelta += delta;
	    			count++;
	    		}
    	}
    	
    	// calc avgs then units
    	var altAvg;
    	var distAvg;
    	
    	if ( count > 0 ) {
    		altAvg = (altDelta/count) * METERS_TO_MILES;
    		distAvg = (distDelta/count) * METERS_TO_MILES;
    	} else {
    		return 0;
    	}

    	var grade = altAvg/distAvg * 100;
    	//System.println("grade%: " + grade);
    	
    	//sanity check
    	if ( grade < -45 || grade > 45 ) {
    		System.println("strange grade calc, adjusting: " + grade);
    		return 0;
    	}
    	
    	//System.println("calcGrade: exit");
    	return grade;
    }

	function calcGap(speed, grade) {
		/*
		From: https://www.runnersworld.com/advanced/a20820206/downhill-all-the-way/
		Going Up
		Every 1% upgrade slows your pace 3.3% (1/30th)
		Every 100 feet of elevation gain slows you 6.6% of your average one mile pace (2% grade/mile).
		Example: A race that climbs 300 feet would slow an 8-minute miler (3 x .066 x 8 x 60 seconds) = 94 seconds slower at the finish
		
		Going Down
		Every 1% downgrade speeds your pace 55% of 3.3% = 1.8%
		Every 100 feet of elevation descent speeds you 3.6% of your average one mile pace (2% grade/mile).
		Example: A race that descends 300 feet would speed an 8-minute miler (3 x .036 x 8 x 60 seconds) = 55 seconds faster at the finish
		*/

		//calc speed in min per mile - comes in meters per second
		//meters per hour = speed * 60 * 60
		//miles per hour = speed * 60 * 60 * METERS_TO_MILES
		//min per mile = 60 / miles per hour
		
		//System.println("calcGap: entered");
		//System.println("speed / grade: " + speed + " / " + grade);
		
		if ( speed == null || speed == 0 ) {
			System.println("speed was null or 0");
			return 0;
		}
		
		//do unit conversion later
		//var empspeed = 60 / (speed * 60 * 60 * METERS_TO_MILES);
		
		//	apply study metics to current pace
		var gaspeed = 0;
		
		if ( grade > 0 ) {
			//uphill case
			//cost is 3.3% of pace for every 1% of grade
			gaspeed = speed + (speed * ((grade * 3.3)/100) );
		} else {
			//downhill case
			gaspeed = speed - (speed * ((grade * -1 * 1.8)/100) );
		}
		
		//System.println("speed/grade/gap: " + speed + " / " + grade + " / " + gapace);
		
		//System.println("calcGap: exit");
		//format for min and sec
		return gaspeed;
	}
}
