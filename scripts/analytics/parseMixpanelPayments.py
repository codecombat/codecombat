# Parse subscription conversion rates via Mixpanel raw export API 

import sys
from datetime import tzinfo, timedelta, datetime
from mixpanel import Mixpanel

try:
    import json
except ImportError:
    import simplejson as json

# NOTE: mixpanel dates are by day and inclusive
# E.g. '2014-12-08' is any date that day, up to 2014-12-09 12am

def printPriceConversionRates(api_key, api_secret, startDate, endDate):
    # dateCreated is in UTC

    # Dec 8th subscribe copy A/B test added

    # 599 - 1st HoC 599 sale started: Dec 9 6:23am PST
    # 999 - 1st HoC 599 sale ended: Dec 10 4:34pm PST
    # 1499 - sub price test starts: Dec 10 5:00pm PST
        # Only for dateCreated >= 5pm PST
    # 399 - 2nd HoC 399 sale started: Dec 11 7:21pm PST
    # 999 - 2nd HoC sale ended: Dec 13 9:30am PST
    # UTC is +8 hrs

    api = Mixpanel(
        api_key = api_key,
        api_secret = api_secret
    )

    print 'Requesting Mixpanel data'
    # data = api.request(['events'], {
    #     'event' : ['Finished subscription purchase',],
    #     'unit' : 'hour',
    #     'interval' : 24,
    #     'type': 'general'
    # })
    # data = api.request(['funnels', 'list'], {})
    data = api.request(['export'], {
        'event' : ['Show subscription modal', 'Finished subscription purchase',],
        # 'event' : ['Finished subscription purchase',],
        # 'event' : ['Show subscription modal',],
        'from_date' : startDate,
        'to_date' : endDate
    })
    
    prices = {
        '399': {
            'start': datetime(2014, 12, 12, 3, 21),
            'end': datetime(2014, 12, 13, 17, 30)
        },
        '599': {
            'start': datetime(2014, 12, 9, 14, 23),
            'end': datetime(2014, 12, 11, 0, 34)
        },
        '999': {
            'start': datetime(2014, 9, 1),
            'end': datetime(2014, 12, 9, 14, 23),
            'start2': datetime(2014, 12, 11, 0, 34),
            'end2': datetime(2014, 12, 12, 3, 21),
            'start3': datetime(2014, 12, 13, 17, 30)
        },
        '1499': {
            'start': datetime(2014, 12, 11, 1),
            'end': datetime(2014, 12, 12, 3, 21)
        }
    }

    # id vs distinct_id ?
    def addEvent(price, event, id):
        if not event in price:
            price[event] = {}
            price[event][id] = True
        elif not id in price[event]:
            price[event][id] = True
            
    def getPriceStr(eventDateStr, userDateStr):
        priceStr = '999'
        eventCreated = datetime.utcfromtimestamp(int(eventDateStr))
        # Put events in buckets based on creation times
        if eventCreated >= prices['599']['start'] and eventCreated < prices['599']['end']:
            priceStr = '599'
        elif eventCreated >= prices['999']['start2'] and eventCreated < prices['999']['end2']:
            # In 999/1499 zone
            # Create a datetime from: 2014-12-11T12:37:59
            userCreated = datetime(int(userDateStr[0:4]), int(userDateStr[5:7]), int(userDateStr[8:10]), int(userDateStr[11:13]), int(userDateStr[14:16]), int(userDateStr[17:19]))
            if userCreated >= prices['1499']['start']:
                priceStr = '1499'
        elif eventCreated >= prices['399']['start'] and eventCreated < prices['399']['end']:
            priceStr = '399'
        return priceStr

    lines = data.split('\n')
    print "Received %d entries" % len(lines)
    for line in lines:
        try:
            if len(line) is 0: continue
            event = json.loads(line)
            properties = event['properties']
            if not event['event'] in ['Show subscription modal', 'Finished subscription purchase']:
                print 'Unexpected event ' + event['event']
                break
            # print 'Processing', event['event'], properties['time'], properties['dateCreated']
            if 'dateCreated' in properties and 'time' in properties and 'distinct_id' in properties:
                # NOTE: mixpanel conversions don't account for refunds
                # NOTE: So we have an extra 1499 hit for mattcc4021@gmaIl.com / 5488ee8a600bc8b206771ba3
                if properties['distinct_id'] == '5488ee8a600bc8b206771ba3':
                    # ch_155tz8KaReE7xLUdQpsa9aqe, cus_5GQqAosNHuRQCQ
                    # print 'Skipping mattcc4021@gmaIl.com / 5488ee8a600bc8b206771ba3'
                    # print event['event'], properties['distinct_id']
                    continue
                # if properties['distinct_id'] == '54790dacfd5b8f550584aaf3':
                #     print 'Found a time example 54790dacfd5b8f550584aaf3'
                #     print properties['time'], datetime.utcfromtimestamp(int(properties['time']))
                priceStr = getPriceStr(properties['time'], properties['dateCreated'])
                # if priceStr == '1499' and event['event'] == 'Finished subscription purchase':
                #     print 'Found a 1499 payment', properties['distinct_id']
                addEvent(prices[priceStr], event['event'], properties['distinct_id'])
        except:
            print "Unexpected error:", sys.exc_info()[0]
            print line
            break
    
    print 'Price, converted, shown, conversion rate, value per user'
    for key, item in prices.iteritems():
        # 'Show subscription modal', 'Finished subscription purchase'
        converted = shown = 0
        if 'Finished subscription purchase' in item:
            converted = len(item['Finished subscription purchase'].keys())
        if 'Show subscription modal' in item:
            shown = len(item['Show subscription modal'].keys())
        if shown > 0:
            print key, converted, shown, "%.4f%%" % (float(converted) / shown * 100), "%.4f cents" % (float(converted) / shown * int(key))
        else:
            print key, converted, shown
    
    
def getShownSubModal(api_key, api_secret, startDate, endDate):
    # print 'Requesting Mixpanel data'
    api = Mixpanel(
        api_key = api_key,
        api_secret = api_secret
    )
    data = api.request(['export'], {
        'event' : ['Show subscription modal',],
        'from_date' : startDate,
        'to_date' : endDate
    })
    
    uniques = set()
    # biggestDate = 0

    lines = data.split('\n')
    # print "Received %d entries" % len(lines)
    for line in lines:
        try:
            if len(line) is 0: continue
            event = json.loads(line)
            properties = event['properties']
            if not event['event'] in ['Show subscription modal']:
                print 'Unexpected event ' + event['event']
                break
            # print 'Processing', event['event'], properties['time'], properties['dateCreated']
            if 'distinct_id' in properties and not properties['distinct_id'] in uniques:
                uniques.add(properties['distinct_id'])
            # if int(properties['time']) > biggestDate:
            #     biggestDate = int(properties['time'])
        except:
            print "Unexpected error:", sys.exc_info()[0]
            print line
            break
    # print 'Biggest date:', datetime.utcfromtimestamp(int(properties['time']))
    return len(uniques)

if __name__ == '__main__':
    if not len(sys.argv) is 3:
        print "Script format: <script> <api_key> <api_secret>"
    else:
        api_key = sys.argv[1]
        api_secret = sys.argv[2]
        # HoC
        printPriceConversionRates(api_key, api_secret, '2014-12-08', '2014-12-19')
        
        # Use these to feed numbers into Stripe parsing script, since Stripe knows better about conversions than Mixpanel
        print 'Pre-HoC shown', getShownSubModal(api_key, api_secret, '2014-12-06', '2014-12-07')
        print 'Post-HoC shown', getShownSubModal(api_key, api_secret, '2014-12-20', '2015-01-04')
