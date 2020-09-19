#!/usr/bin/env python3

# Convert chrony's tracking and statistics logs to something ntpsec's ntpviz can graph
# Assumes chrony's logs are in /var/log/chrony and outputs to /var/log/ntpstats
# See below and fill in an adapter from your local refid names for refclocks to NTPd style
# IPs for refclocks.

import shutil, os, math
from datetime import datetime, timezone

try:
    shutil.rmtree("/var/log/ntpstats/conv")
except:
    pass
os.mkdir("/var/log/ntpstats/conv")

out = None
with open("/var/log/chrony/tracking.log") as tracking:
    line = tracking.readline()
    f = ""
    # Chrony can sometimes print times out of order, which on day boundaries can result
    # in us clearing logs completely, so we track which days we've covered and append
    # if we see a day for a second time.
    suffixes = set()
    while line:
        if line.startswith("   ") or line.startswith("====="):
            line = tracking.readline()
            continue
        s = line.split()
        d = datetime.fromisoformat(s[0] + " " + s[1])
        mjs = (d.timestamp() + 3506716800)
        mjd = math.floor(mjs / 86400)
        secs = mjs - (mjd * 86400)
        logsuf = d.strftime("%Y%m%d")

        if f != logsuf:
            f = logsuf
            if out is not None:
                out.close()
            if f in suffixes:
                out = open("/var/log/ntpstats/conv/loopstats." + logsuf, "a")
            else:
                out = open("/var/log/ntpstats/conv/loopstats." + logsuf, "w")
                suffixes.add(f)
        # Bogus "clock discipline time constant"
        # Note that we don't have Allan Devitaion for freq, only "error bounds on the frequency", but we use that anyway
        out.write("%d %d %.9f %.3f %.9f %.9f 6\n" % (mjd, secs, -float(s[6]), -float(s[4]), float(s[9]), float(s[5])))

        line = tracking.readline()

with open("/var/log/chrony/statistics.log") as stats:
    line = stats.readline()
    f = ""
    suffixes = set()
    while line:
        if line.startswith("   ") or line.startswith("====="):
            line = stats.readline()
            continue
        s = line.split()
        d = datetime.fromisoformat(s[0] + " " + s[1])
        mjs = (d.timestamp() + 3506716800)
        mjd = math.floor(mjs / 86400)
        secs = mjs - (mjd * 86400)
        logsuf = d.strftime("%Y%m%d")

        if f != logsuf:
            f = logsuf
            if out is not None:
                out.close()
            if f in suffixes:
                out = open("/var/log/ntpstats/conv/peerstats." + logsuf, "a")
            else:
                out = open("/var/log/ntpstats/conv/peerstats." + logsuf, "a")
                suffixes.add(f)

        src = s[2]
        # These are my refclocks. You should fill in your own conversions here.
        if src == "NME0":
            src = "127.127.46.0"
        elif src == "NME1":
            src = "127.127.46.1"
        elif src == "NME2":
            src = "127.127.46.2"
        elif src == "GPS0":
            src = "127.127.46.128"
        elif src == "GPS1":
            src = "127.127.46.129"
        elif src == "GPS2":
            src = "127.127.46.130"

        # Bogus "status" and, sadly, missing "delay" (which is 0 here, its only in rawstats)
        out.write("%d %d %s 9014 %.9f 0 %.9f %.9f\n" % (mjd, secs, src, -float(s[4]), float(s[5]), float(s[3])))

        line = stats.readline()

out.close()
for f in os.listdir("/var/log/ntpstats/conv"):
    os.rename("/var/log/ntpstats/conv/" + f, "/var/log/ntpstats/" + f)
shutil.rmtree("/var/log/ntpstats/conv")
