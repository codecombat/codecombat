# Calculate subscribe copy A/B test results

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
        
        startDate = '2014-12-14'
        endDate = '2014-12-21'
        print("Requesting data for {0} to {1}".format(startDate, endDate))
        data = api.request(['export'], {
            'event' : ['Show subscription modal', 'Started subscription purchase', 'Finished subscription purchase'],
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
                if not eventName in ['Show subscription modal', 'Started subscription purchase', 'Finished subscription purchase']:
                    print 'Unexpected event ' + eventName
                    break
                if 'distinct_id' in properties and 'testGroupNumber' in properties:
                    userID = properties['distinct_id']
                    # Test grouping logic
                    # group = me.get('testGroupNumber') % 6
                    # @subscribeCopyGroup = switch group
                    #   when 0, 1, 2 then 'original'
                    #   when 3, 4, 5 then 'new'
                    if int(properties['testGroupNumber']) % 6 in [0, 1, 2]:
                        if not userID in userProgressionGroupA:
                            userProgressionGroupA[userID] = {
                                'Show subscription modal': 0,
                                'Started subscription purchase': 0,
                                'Finished subscription purchase': 0
                            }
                        userProgressionGroupA[userID][eventName] += 1
                    else:
                        if not userID in userProgressionGroupB:
                            userProgressionGroupB[userID] = {
                                'Show subscription modal': 0,
                                'Started subscription purchase': 0,
                                'Finished subscription purchase': 0
                            }
                        userProgressionGroupB[userID][eventName] += 1
            except:
                print "Unexpected error:", sys.exc_info()[0]
                print line
                break
        

        try:
            saw = started = converted = 0
            sawGroupA = startedGroupA = convertedGroupA = 0
            sawGroupB = startedGroupB = convertedGroupB = 0
            
            # Group A
            print("Processing Group A")
            for key, item in userProgressionGroupA.iteritems():
                if item['Finished subscription purchase'] > 0:
                    converted += 1
                    convertedGroupA += 1
                    # TODO: is our distinct_id correct?  We hit this at least once.
                    # if item['Finished subscription purchase'] > 1:
                    #     print "User multiple subscription purchases?"
                    #     print item
                elif item['Started subscription purchase'] > 0:
                    started += 1
                    startedGroupA += 1
                elif item['Show subscription modal'] > 0:
                    saw += 1
                    sawGroupA += 1
                else:
                    print "User without any hits?"
                    print item
                    break

            # Group B
            print("Processing Group B")
            for key, item in userProgressionGroupB.iteritems():
                if item['Finished subscription purchase'] > 0:
                    converted += 1
                    convertedGroupB += 1
                elif item['Started subscription purchase'] > 0:
                    started += 1
                    startedGroupB += 1
                elif item['Show subscription modal'] > 0:
                    saw += 1
                    sawGroupB += 1
                else:
                    print "User without any hits?"
                    print item
                    break

            print("Overall")
            print("saw {0} started {1} converted {2}".format(saw, started, converted))
            print("step 1 conversion {0}% step 2 conversion {1}% overall conversion {2}%".format(float(started) / saw * 100, float(converted) / started * 100, float(converted) / saw * 100))
            print("Group A")
            print("sawGroupA {0} startedGroupA {1} convertedGroupA {2}".format(sawGroupA, startedGroupA, convertedGroupA))
            print("step 1 conversion {0}% step 2 conversion {1}% overall conversion {2}%".format(float(startedGroupA) / sawGroupA * 100, float(convertedGroupA) / startedGroupA * 100, float(convertedGroupA) / sawGroupA * 100))
            print("Group B")
            print("sawGroupB {0} startedGroupB {1} convertedGroupB {2}".format(sawGroupB, startedGroupB, convertedGroupB))
            print("step 1 conversion {0}% step 2 conversion {1}% overall conversion {2}%".format(float(startedGroupB) / sawGroupB * 100, float(convertedGroupB) / startedGroupB * 100, float(convertedGroupB) / sawGroupB * 100))
        except:
            print "Unexpected error:", sys.exc_info()[0]
