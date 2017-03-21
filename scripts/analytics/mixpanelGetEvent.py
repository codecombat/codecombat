# Get mixpanel event data via export API
# Useful for debugging Mixpanel data weirdness

targetLevels = ['dungeons-of-kithgard', 'the-raised-sword', 'endangered-burl']
targetLevels = ['dungeons-of-kithgard']
eventFunnel = ['Started Level', 'Saw Victory']
# eventFunnel = ['Saw Victory']
# eventFunnel = ['Started Level']

import sys
from pprint import pprint
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

        startDate = '2015-01-01'
        endDate = '2015-01-26'

        startEvent = eventFunnel[0]
        endEvent = eventFunnel[-1]

        print("Requesting data for {0} to {1}".format(startDate, endDate))
        data = api.request(['export'], {
            # 'where': '"539c630f30a67c3b05d98d95" == properties["id"]',
            # 'where': "('539c630f30a67c3b05d98d95' == properties['id'] or '539c630f30a67c3b05d98d95' == properties['distinct_id'])",
            'event': eventFunnel,
            'from_date': startDate,
            'to_date': endDate
        })


        weirdUserIDs = []
        eventUsers = {}
        levelEventUserDayMap = {}
        levelUserEventDayMap = {}
        lines = data.split('\n')
        print "Received %d entries" % len(lines)
        for line in lines:
            try:
                if len(line) is 0: continue
                eventData = json.loads(line)
                # pprint(eventData)
                # break
                eventName = eventData['event']
                if not eventName in eventFunnel:
                    print 'Unexpected event ' + eventName
                    break
                if not 'properties' in eventData:
                    print('no properties, skpping')
                    continue
                properties = eventData['properties']
                if not 'distinct_id' in properties:
                    print('no distinct_id, skpping')
                    continue
                user = properties['distinct_id']
                if not 'time' in properties:
                    print('no time, skpping')
                    continue
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

                if not level in targetLevels: continue

                # if user != "539c630f30a67c3b05d98d95": continue
                pprint(eventData)

                # if user == "54c1fc3a08652d5305442c6b":
                #     pprint(eventData)
                #     break
                # if '-' in user:
                #     weirdUserIDs.append(user)
                #     # pprint(eventData)
                #     # break
                #     continue

                # print level

                if not level in levelEventUserDayMap: levelEventUserDayMap[level] = {}
                if not eventName in levelEventUserDayMap[level]: levelEventUserDayMap[level][eventName] = {}
                if not user in levelEventUserDayMap[level][eventName] or levelEventUserDayMap[level][eventName][user] > day:
                    levelEventUserDayMap[level][eventName][user] = day

                if not user in eventUsers: eventUsers[user] = True

                if not level in levelUserEventDayMap: levelUserEventDayMap[level] = {}
                if not user in levelUserEventDayMap[level]: levelUserEventDayMap[level][user] = {}
                if not eventName in levelUserEventDayMap[level][user] or levelUserEventDayMap[level][user][eventName] > day:
                    levelUserEventDayMap[level][user][eventName] = day

            except:
                print "Unexpected error:", sys.exc_info()[0]
                print line
                break

        # pprint(levelEventUserDayMap)

        print("Weird user IDs: {0}".format(len(weirdUserIDs)))

        for level in levelEventUserDayMap:
            for event in levelEventUserDayMap[level]:
                print("{0} {1} {2}".format(level, event, len(levelEventUserDayMap[level][event])))
        print("Users: {0}".format(len(eventUsers)))

        noStartDayUsers = []
        levelFunnelData = {}
        for level in levelUserEventDayMap:
            for user in levelUserEventDayMap[level]:
                # 6455
                # for event in levelUserEventDayMap[level][user]:
                #     day = levelUserEventDayMap[level][user][event]
                #     if not level in levelFunnelData: levelFunnelData[level] = {}
                #     if not day in levelFunnelData[level]: levelFunnelData[level][day] = {}
                #     if not event in levelFunnelData[level][day]: levelFunnelData[level][day][event] = 0
                #     levelFunnelData[level][day][event] += 1

                # 5382
                funnelStartDay = None
                for event in levelUserEventDayMap[level][user]:
                    day = levelUserEventDayMap[level][user][event]
                    if not level in levelFunnelData: levelFunnelData[level] = {}
                    if not day in levelFunnelData[level]: levelFunnelData[level][day] = {}
                    if not event in levelFunnelData[level][day]: levelFunnelData[level][day][event] = 0
                    if eventFunnel[0] == event:
                        levelFunnelData[level][day][event] += 1
                        funnelStartDay = day
                        break

                if funnelStartDay:
                    for event in levelUserEventDayMap[level][user]:
                        if not event in levelFunnelData[level][funnelStartDay]:
                            levelFunnelData[level][funnelStartDay][event] = 0
                        if eventFunnel[0] != event:
                            levelFunnelData[level][funnelStartDay][event] += 1
                    for i in range(1, len(eventFunnel)):
                        event = eventFunnel[i]
                        if not event in levelFunnelData[level][funnelStartDay]:
                            levelFunnelData[level][funnelStartDay][event] = 0
                else:
                    noStartDayUsers.append(user)

        pprint(levelFunnelData)
        print("No start day count: {0}".format(len(noStartDayUsers)))
        noStartDayUsers.sort()
        for i in range(len(noStartDayUsers)):
            if i > 50: break
            print(noStartDayUsers[i])


        print("Script runtime: {0}".format(datetime.now() - scriptStart))
