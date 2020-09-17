Convert chrony's tracking and statistics logs to something ntpsec's ntpviz can graph.

This is just a script for me, but its probably useful for others.

There's a few things hard-coded that you may wish to change:
 * Assumes chrony's logs are in /var/log/chrony and outputs to /var/log/ntpstats
 * Has a list of mappings from my refids to NTPd-style local IP addresses, which you probably
   need to change if you don't use "NMEX" for the X'th NMEA input and "GPSX" for the X'th GPS
   PPS pin.

Note that the graphs from chrony are not directly comparable to those from NTPd. Differences
include:
  * Chrony prints "error bounds" on the local frequency range, whereas NTPd prints the
    Allan Deviation. ntpviz will title it "RMS Frequency Jitter" even though its really an error
    bound.
  * We currently don't map the RTT to our peers, just printing 0. This isn't 1-to-1 mappable and
    to do so we'd need to read the measurements.log and do some averaging ourselves. At some point
    we should do this, though.
  * Chrony massages samples over a longer time horizon and prints the calcualted offset in
    statistics.log whereas NTP prints samples from a much shorter time horizon (possibly before
    massaging, but I didn't dig deep enough) in peerstats. We could pull from measurements.log
    which may be more comparable to NTPd peerstats, but its missing some fields which ntpviz wants.
