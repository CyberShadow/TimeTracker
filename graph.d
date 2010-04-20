import std.file;
import std.string;
import std.date;
import std.c.stdio;

void main()
{
	long firstDay;
	int days;
	d_time start;
	d_time[] totals;

	struct Segment { d_time start, duration; }
	Segment[] segments;

	foreach (line; splitlines(cast(string)read("worklog.txt")))
	{
		if (line.length==0 || line[0] != '[')
			continue;
		line = line[1..$];
		string timeStr = line[0..line.find("]")];
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
		d_time time = MakeDate(MakeDay(year, month, date), MakeTime(hour, minute, second, 0));
		if (firstDay == 0)
			firstDay = time / TicksPerDay;
		int day = cast(int)(time / TicksPerDay - firstDay);
		if (day >= days)
			days = cast(int)day+1;
		line = line[line.find("]")+2..$];
		switch(line)
		{
			case "Work started":
				start = time;
				break;
			case "Work stopped":
			{
				if (!start)
					throw new Exception("Work never started");
				long startDay = start/TicksPerDay - firstDay;
				if (day == startDay)
					segments ~= Segment(start, time-start);
				else
				{
					if (day - startDay > 1)
						throw new Exception("Work took longer than a day");
					segments ~= Segment(start, (day+firstDay)*TicksPerDay - start);
					segments ~= Segment((day+firstDay)*TicksPerDay, time%TicksPerDay);
				}

				if (day >= totals.length)
					totals.length = day+1;
				totals[day] += time - start;
				start = 0;
				break;
			}
			default:
				throw new Exception("Unknown string " ~ line);
		}
	}

	string[] hours;
	for (int i=0; i<24; i++)
		hours ~= format(`<div style="left: %8.4f%%">%2d</div>`, i/24.0*100, i);

	string[] rows;
	for (int day=0; day<days; day++)
	{
		d_time t = (firstDay + day) * TicksPerDay;
		string row = format(`<td style="width: 149px"><code>%s %02d %s: %02d:%02d</code></td>`, weekdays[WeekDay(t)], DateFromTime(t), months[MonthFromTime(t)], HourFromTime(totals[day]), MinFromTime(totals[day]));
		for (int i=0; i<24; i++)
			row ~= `<td></td>`;
		rows ~= row;
	}

	string[] bars;
	foreach (s; segments)
		bars ~= format(`<div style="top: %dpx; left: %8.4f%%; width: %2.4f%%"></div>`, 21 + 24*(s.start/TicksPerDay-firstDay), (s.start%TicksPerDay)*100.0/TicksPerDay, s.duration*100.0/TicksPerDay);

	string html = `
<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title>TimeTracker work graph</title>
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
  tr {
    height: 24px;
  }
  </style>
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
</body>
</html>`;
	write("graph.html", html);
}

const string[] weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const string[] months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
