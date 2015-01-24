# Calculate level completion rates via mixpanel export API

# TODO: unique users
# TODO: align output
# TODO: order output

import sys
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
        api_key = sys.argv[1]
        api_secret = sys.argv[2]
        api = Mixpanel(
            api_key = api_key,
            api_secret = api_secret
        )
        
        startDate = '2014-12-31'
        endDate = '2015-01-05'
        print("Requesting data for {0} to {1}".format(startDate, endDate))
        data = api.request(['export'], {
            'event' : ['Started Level', 'Saw Victory'],
            'from_date' : startDate,
            'to_date' : endDate
        })
        
        levelRates = {}
        lines = data.split('\n')
        print "Received %d entries" % len(lines)
        for line in lines:
            try:
                if len(line) is 0: continue
                eventData = json.loads(line)
                eventName = eventData['event']
                if not eventName in ['Started Level', 'Saw Victory']:
                    print 'Unexpected event ' + eventName
                    break
                properties = eventData['properties']
                if 'levelID' in properties:
                    levelID = properties['levelID']
                elif 'level' in properties:
                    levelID = properties['level'].lower().replace(' ', '-')
                else:
                    print("Unkonwn levelID for", eventName)
                    print(properties)
                    break
                if not levelID in levelRates:
                    levelRates[levelID] = {'started': 0, 'finished': 0}
                if eventName == 'Started Level':
                    levelRates[levelID]['started'] += 1
                elif eventName == 'Saw Victory':
                    levelRates[levelID]['finished'] += 1
                else:
                    print("Unknown event name", eventName)
                    print(eventData)
                    break
            except:
                print "Unexpected error:", sys.exc_info()[0]
                print line
                break

        # print(levelRates)
        for levelID in levelRates:
            started = levelRates[levelID]['started']
            finished = levelRates[levelID]['finished']
            # if not levelID == 'endangered-burl':
            #     continue
            if started > 0:
                print("{0}\t{1}\t{2}\t{3}%".format(levelID, started, finished, float(finished) / started * 100))
            else:
                print("{0}\t{1}\t{2}".format(levelID, started, finished))
