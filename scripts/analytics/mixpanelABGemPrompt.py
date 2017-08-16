# Calculate gem prompt A/B test results

# TODO: Why is no-prompt group 50% larger?

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

        startDate = '2015-01-15'
        startDate = '2014-11-25'
        endDate = '2015-02-11'

        print("Requesting data for {0} to {1}".format(startDate, endDate))
        data = api.request(['export'], {
            'event' : ['Started purchase', 'Finished gem purchase'],
            'from_date' : startDate,
            'to_date' : endDate
        })

        userProgressionGroupA = {}
        userProgressionGroupB = {}

        lines = data.split('\n')
        print "Received %d entries" % len(lines)
        for line in lines:
            try:
                if len(line) is 0: continue
                eventData = json.loads(line)
                eventName = eventData['event']
                properties = eventData['properties']
                if not eventName in ['Started purchase', 'Finished gem purchase']:
                    print 'Unexpected event ' + eventName
                    break
                if 'distinct_id' in properties and 'gemPromptGroup' in properties:
                    userID = properties['distinct_id']
                    if properties['gemPromptGroup'] == 'prompt':
                        if not userID in userProgressionGroupA:
                            userProgressionGroupA[userID] = {
                                'Started purchase': 0,
                                'Finished gem purchase': 0
                            }
                        userProgressionGroupA[userID][eventName] += 1
                    elif properties['gemPromptGroup'] == 'no-prompt':
                        if not userID in userProgressionGroupB:
                            userProgressionGroupB[userID] = {
                                'Started purchase': 0,
                                'Finished gem purchase': 0
                            }
                        userProgressionGroupB[userID][eventName] += 1
                    else:
                        print "Unexpected group:", properties['gemPromptGroup']
                        print properties
                        print line
                        break
            except:
                print "Unexpected error:", sys.exc_info()[0]
                print line
                break

        try:
            started = converted = 0
            startedGroupA = convertedGroupA = 0
            startedGroupB = convertedGroupB = 0

            # Group A
            print("Processing Group A")
            for key, item in userProgressionGroupA.iteritems():
                if item['Finished gem purchase'] > 0:
                    converted += 1
                    convertedGroupA += 1
                    # TODO: is our distinct_id correct?  We hit this at least once.
                    # if item['Finished gem purchase'] > 1:
                    #     print "User multiple subscription purchases?"
                    #     print item
                elif item['Started purchase'] > 0:
                    started += 1
                    startedGroupA += 1
                else:
                    print "User without any hits?"
                    print item
                    break

            # Group B
            print("Processing Group B")
            for key, item in userProgressionGroupB.iteritems():
                if item['Finished gem purchase'] > 0:
                    converted += 1
                    convertedGroupB += 1
                elif item['Started purchase'] > 0:
                    started += 1
                    startedGroupB += 1
                else:
                    print "User without any hits?"
                    print item
                    break

            print("Overall")
            print("started {0} converted {1} rate {2}%".format(started, converted, float(converted) / started * 100))
            print("Group prompt")
            print("startedGroupA {0} convertedGroupA {1} rate {2}%".format(startedGroupA, convertedGroupA, float(convertedGroupA) / startedGroupA * 100))
            print("Group no-prompt")
            print("startedGroupB {0} convertedGroupB {1} rate {2}%".format(startedGroupB, convertedGroupB, float(convertedGroupB) / startedGroupB * 100))
        except:
            print "Unexpected error:", sys.exc_info()[0]
