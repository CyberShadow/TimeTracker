import std.file;
import std.string;
import std.date;
import std.c.stdio;
import std.c.time;
import crc32;

void main()
{
	long firstDay;
	int days;
	d_time start;
	d_time[] totals;
	d_time[24][] hourTotals;
	d_time total;

	struct Segment { d_time start, duration; string task; }
	Segment[] segments;
	string task = "Unspecified task";

	struct Task { string name; d_time time; }
	Task[] tasks;
	int[string] taskLookup;

	void addSegment(d_time start, d_time stop, long day)
	{
		segments ~= Segment(start, stop-start, task);

		if (day >= totals.length)
			totals.length = day+1;
		totals[day] += stop - start;
		
		if (day >= hourTotals.length)
			hourTotals.length = day+1;
		int startHour = start % TicksPerDay / TicksPerHour;
		int stopHour  = stop  % TicksPerDay / TicksPerHour;
		if (startHour == stopHour)
			hourTotals[day][startHour] += stop-start;
		else
		{
			hourTotals[day][startHour] += TicksPerHour - (start % TicksPerHour);
			for (int h=startHour+1; h < stopHour; h++)
				hourTotals[day][h] += TicksPerHour;
			hourTotals[day][stopHour ] += stop % TicksPerHour;
		}
		
		total += stop-start;

		if (!(task in taskLookup))
		{
			taskLookup[task] = tasks.length;
			tasks ~= Task(task, stop - start);
		}
		else
			tasks[taskLookup[task]].time += stop - start;
	}
	
	void stopWork(d_time stop, int day)
	{
		assert(start);
		long startDay = start/TicksPerDay - firstDay;
		if (day == startDay)
			addSegment(start, stop, day);
		else
		{
			if (day - startDay > 1)
				throw new Exception("Work took longer than a day");
			addSegment(start, (day+firstDay)*TicksPerDay, startDay);
			addSegment((day+firstDay)*TicksPerDay, stop, day);
		}

		start = 0;
	}

	static d_time parseTime(string timeStr)
	{
		char[4] weekday, monthStr;
		int date, hour, minute, second, year, month;
		int n = sscanf(timeStr.toStringz(), "%3s %3s %d %d:%d:%d %d".toStringz(), weekday.ptr, monthStr.ptr, &date, &hour, &minute, &second, &year);
		if (n != 7)
			throw new Exception("Invalid timestamp: " ~ timeStr);
		month = -1;
		foreach (m, monthName; months)
			if (monthName == monthStr[0..3])
				month = m;
		if (month == -1)
			throw new Exception("Invalid month: " ~ monthStr[0..3]);
		return MakeDate(MakeDay(year, month, date), MakeTime(hour, minute, second, 0));
	}

	string[] lines = splitlines(cast(string)read("worklog.txt"));

	// Add finishing line in case work is still ongoing
	{
		time_t t;
		time(&t);
		char* timestr = ctime(&t);
		lines ~= format("[%s] End", strip(std.string.toString(timestr)));
	}

	foreach (line; lines)
	{
		if (line.length==0 || line[0] != '[')
			continue;
		line = line[1..$];
		d_time time = parseTime(line[0..line.find("]")]);
		if (firstDay == 0)
			firstDay = time / TicksPerDay;
		int day = cast(int)(time / TicksPerDay - firstDay);
		if (day >= days)
			days = cast(int)day+1;
		line = line[line.find("]")+2..$];
		if (line == "Work started")
			start = time;
		else
		if (line == "Work stopped")
		{
			if (!start)
				throw new Exception("Work never started");
			stopWork(time, day);
		}
		else
		if (line == "End")
		{
			if (start)
				stopWork(time, day);
		}
		else
		if (line.length > 6 && line[0..6]=="Task: ")
		{
			if (start)
			{
				stopWork(time, day);
				start = time;
			}
			task = line[6..$];
		}
		else
			throw new Exception("Unknown string " ~ line);
	}
	totals.length = hourTotals.length = days;
	
	string[] hours;
	for (int i=0; i<24; i++)
		hours ~= format(`<div style="left: %8.4f%%">%2d</div>`, i/24.0*100, i);

	string[] rows;
	for (int day=0; day<days; day++)
	{
		d_time t = (firstDay + day) * TicksPerDay;
		string row = format(`<td style="width: 149px"><code>%s %02d %s: %02d:%02d</code></td>`, weekdays[WeekDay(t)], DateFromTime(t), months[MonthFromTime(t)], HourFromTime(totals[day]), MinFromTime(totals[day]));
		for (int h=0; h<24; h++)
			row ~= format(`<td><s>%d</s>&#8203;</td>`, hourTotals[day][h] / TicksPerSecond);
		rows ~= row;
	}

	string[] bars;
	foreach (s; segments)
		bars ~= format(`<div style="top: %dpx; left: %8.4f%%; width: %2.4f%%; background-color: #%06X" title='%s'></div>`, 21 + 24*(s.start/TicksPerDay-firstDay), (s.start%TicksPerDay)*100.0/TicksPerDay, s.duration*100.0/TicksPerDay, strcrc32(s.task)&0xFFFFFF, s.task);

	string[] taskLines;
	foreach (t; tasks)
		taskLines ~= format(`<li><div class="box" style="background-color: #%06X"></div> <code>%02d:%02d<s>%d</s> - %s</code></li>`, strcrc32(t.name)&0xFFFFFF, t.time/TicksPerHour, t.time%TicksPerHour/TicksPerMinute, t.time/TicksPerSecond, t.name);

	string html = `
<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title>TimeTracker report</title>
 <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
 <style type="text/css">
  body {
  	margin: 0; padding: 0;
  }
  #hours, #bars { position: absolute; top: 0; left: 150px; right: 0px; }
  #hours div {
    position: absolute;
    top: 0;
    width: 30px;
    margin-left: -15px;
    text-align: center;
  }
  #bars div {
    position: absolute;
    background-color: red;
    height: 23px;
  }
  table { 
    width: 100%;
    margin-top: 20px; 
    empty-cells: show;
  }
  table, td {
    border: 1px solid black;
    border-collapse: collapse;
  }
  tr, td { margin: 0; padding: 0; }
  tr { height: 24px; }
  s { display: none; }
  .box { position: relative; top: 3px; width: 1em; height: 1em; display: inline-block; }
  </style>
  
  <script src="http://dump.thecybershadow.net/10092eee563dec2dca82b77d2cf5a1ae/jquery-1.4.2.min.js"></script>
  <!--[if IE]>
  <script src="http://ierange.googlecode.com/svn/trunk/ierange.js"></script>
  <![endif]-->
  
  <script type="text/javascript">
    function update() {
      try {
        var d = document.createElement("div");
        d.appendChild(window.getSelection().getRangeAt(0).cloneContents());
        var s = $("s", d);
        
        var total = 0;
        $.each(s, function() {
          total += parseInt(this.innerHTML);
        });

        if (total) {
          var h = Math.floor(total / 3600);
          var m = Math.floor(total / 60) % 60;
          $("#selectedtotal").css("visibility", "visible").html("Selected: <code>" + h + ":" + (m>9 ? "" : "0") + m + "</code>");
        } else
          throw "Nothing is selected";
      } catch(err) {
        $("#selectedtotal").css("visibility", "hidden");
      }
    }

    setInterval(update, 50);
  </script>
</head>
<body>
  <div id="hours">
    ` ~ join(hours, `
    `) ~ `
  </div>
  <div id="bars">
    ` ~ join(bars, `
    `) ~ `
  </div>
  <table>
   <tr>` ~ join(rows, `</tr>
   <tr>`) ~ `</tr>
  </table>
  <ul>
   ` ~ join(taskLines, `
   `) ~ `
   <li>Total: <code>` ~ format(`%d:%02d`, total/TicksPerHour, total%TicksPerHour/TicksPerMinute) ~ `</code></li>
   <li style="visibility: hidden" id="selectedtotal"></li>
  </ul>
</body>
</html>`;
	write("report.html", html);
}

const string[] weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const string[] months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
