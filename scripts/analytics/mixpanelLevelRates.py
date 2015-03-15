# Calculate level completion rates via mixpanel export API

# TODO: why are our 'time' fields in PST time?

targetLevels = ['dungeons-of-kithgard', 'the-raised-sword', 'endangered-burl']
eventFunnel = ['Started Level', 'Saw Victory']

import sys

from datetime import datetime, timedelta
from mixpanel import Mixpanel

try:
    import json
except ImportError:
    import simplejson as json

# NOTE: mixpanel dates are by day and inclusive
# E.g. '2014-12-08' is any date that day, up to 2014-12-09 12am

if __name__ == '__main__':
    if not len(sys.argv) is 3:
        print "Script format: <script> <api_key> <api_secret>"
    else:
        scriptStart = datetime.now()

        api_key = sys.argv[1]
        api_secret = sys.argv[2]
        api = Mixpanel(
            api_key = api_key,
            api_secret = api_secret
        )

        # startDate = '2015-01-11'
        # endDate = '2015-01-17'
        startDate = '2015-01-23'
        endDate = '2015-01-23'
        # endDate = '2015-01-28'

        startEvent = eventFunnel[0]
        endEvent = eventFunnel[-1]

        print("Requesting data for {0} to {1}".format(startDate, endDate))
        data = api.request(['export'], {
            'event' : eventFunnel,
            'from_date' : startDate,
            'to_date' : endDate
        })


        # Map ordering: level, user, event, day
        userDataMap = {}
        lines = data.split('\n')
        print "Received %d entries" % len(lines)
        for line in lines:
            try:
                if len(line) is 0: continue
                eventData = json.loads(line)
                eventName = eventData['event']
                if not eventName in eventFunnel:
                    print 'Unexpected event ' + eventName
                    break
                if not 'properties' in eventData: continue
                properties = eventData['properties']
                if not 'distinct_id' in properties: continue
                user = properties['distinct_id']
                if not 'time' in properties: continue
                time = properties['time']
                pst = datetime.fromtimestamp(int(properties['time']))
                utc = pst + timedelta(0, 8 * 60 * 60)
                dateCreated = utc.isoformat()
                day = dateCreated[0:10]
                if day < startDate or day > endDate:
                    print "Skipping {0}".format(day)
                    continue

                if 'levelID' in properties:
                    level = properties['levelID']
                elif 'level' in properties:
                    level = properties['level'].lower().replace(' ', '-')
                else:
                    print("Unkonwn level for", eventName)
                    print(properties)
                    break

                if not level in targetLevels:
                    continue

                # print level

                if not level in userDataMap: userDataMap[level] = {}
                if not user in userDataMap[level]: userDataMap[level][user] = {}
                if not eventName in userDataMap[level][user] or userDataMap[level][user][eventName] > day:
                    userDataMap[level][user][eventName] = day
            except:
                print "Unexpected error:", sys.exc_info()[0]
                print line
                break

        # print(userDataMap)

        levelFunnelData = {}
        for level in userDataMap:
            for user in userDataMap[level]:
                funnelStartDay = None
                for event in userDataMap[level][user]:
                    day = userDataMap[level][user][event]
                    if not level in levelFunnelData: levelFunnelData[level] = {}
                    if not day in levelFunnelData[level]: levelFunnelData[level][day] = {}
                    if not event in levelFunnelData[level][day]: levelFunnelData[level][day][event] = 0
                    if eventFunnel[0] == event:
                        levelFunnelData[level][day][event] += 1
                        funnelStartDay = day
                        break

                if funnelStartDay:
                    for event in userDataMap[level][user]:
                        if not event in levelFunnelData[level][funnelStartDay]:
                            levelFunnelData[level][funnelStartDay][event] = 0
                        if not eventFunnel[0] == event:
                            levelFunnelData[level][funnelStartDay][event] += 1
                    for i in range(1, len(eventFunnel)):
                        event = eventFunnel[i]
                        if not event in levelFunnelData[level][funnelStartDay]:
                            levelFunnelData[level][funnelStartDay][event] = 0

        # print(levelFunnelData)

        totals = {}
        for level in levelFunnelData:
            for day in levelFunnelData[level]:
                if startEvent in levelFunnelData[level][day]:
                    started = levelFunnelData[level][day][startEvent]
                else:
                    started = 0
                if endEvent in levelFunnelData[level][day]:
                    finished = levelFunnelData[level][day][endEvent]
                else:
                    finished = 0
                if not level in totals: totals[level] = {}
                if not startEvent in totals[level]: totals[level][startEvent] = 0
                if not endEvent in totals[level]: totals[level][endEvent] = 0
                totals[level][startEvent] += started
                totals[level][endEvent] += finished
                if started > 0:
                    print("{0}\t{1}\t{2}\t{3}\t{4}%".format(level, day, started, finished, float(finished) / started * 100))
                else:
                    print("{0}\t{1}\t{2}\t{3}\t".format(level, day, started, finished))

        for level in totals:
            started = totals[level][startEvent]
            finished = totals[level][endEvent]
            if started > 0:
                print("{0}\t{1}\t{2}\t{3}%".format(level, started, finished, float(finished) / started * 100))
            else:
                print("{0}\t{1}\t{2}\t".format(level, started, finished))

        print("Script runtime: {0}".format(datetime.now() - scriptStart))
