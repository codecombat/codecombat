# Parse Stripe payment info via exported payments.csv files

import sys
from datetime import tzinfo, timedelta, datetime

# TODO: use stripe_customers.csv to match payments to our db data

# Stripe file format
# id,Description,Created (UTC),Amount,Amount Refunded,Currency,Converted Amount,Converted Amount Refunded,Fee,Tax,Converted Currency,Mode,Status,Statement Description,Customer ID,Customer Description,Customer Email,Captured,Card Last4,Card Brand,Card Funding,Card Exp Month,Card Exp Year,Card Name,Card Address Line1,Card Address Line2,Card Address City,Card Address State,Card Address Country,Card Address Zip,Card Issue Country,Card Fingerprint,Card CVC Status,Card AVS Zip Status,Card AVS Line1 Status,Disputed Amount,Dispute Status,Dispute Reason,Dispute Date (UTC),Dispute Evidence Due (UTC),Invoice ID,productID (metadata),userID (metadata),gems (metadata),timestamp (metadata)

def getGemCounts(paymentsFile):
    gems = {}
    with open(paymentsFile) as f:
        first = True
        for line in f:
            if first:
                first = False
            else:
                data = line.split(',')
                amount = int(float(data[3]) * 100)
                status = data[12]
                statementDescription = data[13]
                if status == 'Paid' and not statementDescription == 'Sub':
                    if not amount in gems:
                        gems[amount] = 1
                    else:
                        gems[amount] += 1
    return gems

def getSubCounts(paymentsFile):
    subs = {}
    with open(paymentsFile) as f:
        first = True
        for line in f:
            if first:
                first = False
            else:
                data = line.split(',')
                # created = data[2]
                amount = int(float(data[3]) * 100)
                # amountRefunded = int(float(data[4]) * 100)
                # mode = data[11]
                status = data[12]
                statementDescription = data[13]
                
                # Look for status = 'Paid', and statementDescription = 'Sub'
                # print "{0}\t{1}\t{2}\t{3}\t{4}\t{5}".format(created, amount, amountRefunded, mode, status, statementDescription)
                
                if status == 'Paid' and statementDescription == 'Sub':
                    if not amount in subs:
                        subs[amount] = 1
                    else:
                        subs[amount] += 1
    return subs

def getHoCPriceConversionRates(paymentsFile):
    # Show counts from Mixpanel
    prices = {
        '399': {
            # 'start': datetime(2014, 12, 12, 3, 21),
            # 'end': datetime(2014, 12, 13, 17, 30),
            'Show subscription modal': 31157,
            'Finished subscription purchase': 0
        },
        '599': {
            # 'start': datetime(2014, 12, 9, 14, 23),
            # 'end': datetime(2014, 12, 11, 0, 34),
            'Show subscription modal': 31044,
            'Finished subscription purchase': 0
        },
        '999': {
            # 'start': datetime(2014, 9, 1),
            # 'end': datetime(2014, 12, 9, 14, 23),
            # 'start2': datetime(2014, 12, 11, 0, 34),
            # 'end2': datetime(2014, 12, 12, 3, 21),
            # 'start3': datetime(2014, 12, 13, 17, 30),
            'Show subscription modal': 86883,
            'Finished subscription purchase': 0
        },
        '1499': {
            # 'start': datetime(2014, 12, 11, 1),
            # 'end': datetime(2014, 12, 12, 3, 21),
            'Show subscription modal': 19519,
            'Finished subscription purchase': 0
        }
    }

    # TODO: may be one 1499 sale
    priceTest = {
        'ch_158LyeKaReE7xLUdnt0m9pjb': True,
        'ch_158OPLKaReE7xLUdcqYQ5qst': True,
        'ch_158jkBKaReE7xLUd305I3WBy': True
    }

    # Find 'Finished subscription purchase' event from Stripe data
    startDate = datetime(2014, 12, 8)
    endDate = datetime(2014, 12, 20)
    print startDate, 'to', endDate
    with open(paymentsFile) as f:
        first = True
        for line in f:
            if first:
                first = False
            else:
                data = line.split(',')
                paymentID = data[0]
                created = data[2] # 2014-12-14 06:01

                createdDate = datetime(int(created[0:4]), int(created[5:7]), int(created[8:10]), int(created[11:13]), int(created[14:16]))
                if createdDate < startDate or createdDate >= endDate:
                    continue

                if paymentID in priceTest:
                    amount = 1499
                else:
                    amount = int(float(data[3]) * 100)
                amountStr = str(amount)
                # amountRefunded = int(float(data[4]) * 100)
                # mode = data[11]
                status = data[12]
                statementDescription = data[13]
                
                # Look for status = 'Paid', and statementDescription = 'Sub'
                # print "{0}\t{1}\t{2}\t{3}\t{4}\t{5}".format(created, amount, amountRefunded, mode, status, statementDescription)
                
                if status == 'Paid' and statementDescription == 'Sub':
                    prices[amountStr]['Finished subscription purchase'] += 1

    # Calculate conversion rates
    for key, item in prices.iteritems():
        item['Conversion Rate'] = float(item['Finished subscription purchase']) / item['Show subscription modal']
        item['Value Per User'] = float(item['Finished subscription purchase']) / item['Show subscription modal'] * int(key)

    return prices

def getPreHoCPriceConversionRates(paymentsFile):
    # Pre-HoC but after full stop paywall in forest

    # Show count from Mixpanel
    prices = {
        '999': {
            'Show subscription modal': 3447,
            'Finished subscription purchase': 0
        }
    }
    
    # Find 'Finished subscription purchase' event from Stripe data
    startDate = datetime(2014, 12, 6)
    endDate = datetime(2014, 12, 8)
    print startDate, 'to', endDate
    with open(paymentsFile) as f:
        first = True
        for line in f:
            if first:
                first = False
            else:
                data = line.split(',')
                paymentID = data[0]
                created = data[2] # 2014-12-14 06:01
                createdDate = datetime(int(created[0:4]), int(created[5:7]), int(created[8:10]), int(created[11:13]), int(created[14:16]))
                if createdDate < startDate or createdDate >= endDate:
                    continue
                amount = int(float(data[3]) * 100)
                amountStr = str(amount)
                status = data[12]
                statementDescription = data[13]
                if status == 'Paid' and statementDescription == 'Sub':
                    prices[amountStr]['Finished subscription purchase'] += 1

    # Calculate conversion rates
    for key, item in prices.iteritems():
        item['Conversion Rate'] = float(item['Finished subscription purchase']) / item['Show subscription modal']
        item['Value Per User'] = float(item['Finished subscription purchase']) / item['Show subscription modal'] * int(key)

    return prices

def getPostHoCPriceConversionRates(paymentsFile):
    # Pre-HoC but after full stop paywall in forest

    # Show count from Mixpanel
    prices = {
        '999': {
            'Show subscription modal': 13339,
            'Finished subscription purchase': 0
        }
    }
    
    # Find 'Finished subscription purchase' event from Stripe data
    startDate = datetime(2014, 12, 20)
    endDate = datetime(2015, 1, 4)
    print startDate, 'to', endDate
    with open(paymentsFile) as f:
        first = True
        for line in f:
            if first:
                first = False
            else:
                data = line.split(',')
                paymentID = data[0]
                created = data[2] # 2014-12-14 06:01
                createdDate = datetime(int(created[0:4]), int(created[5:7]), int(created[8:10]), int(created[11:13]), int(created[14:16]))
                if createdDate < startDate or createdDate >= endDate:
                    continue
                amount = int(float(data[3]) * 100)
                amountStr = str(amount)
                status = data[12]
                statementDescription = data[13]
                if status == 'Paid' and statementDescription == 'Sub':
                    prices[amountStr]['Finished subscription purchase'] += 1

    # Calculate conversion rates
    for key, item in prices.iteritems():
        item['Conversion Rate'] = float(item['Finished subscription purchase']) / item['Show subscription modal']
        item['Value Per User'] = float(item['Finished subscription purchase']) / item['Show subscription modal'] * int(key)

    return prices

if __name__ == '__main__':
    paymentsFile = 'stripe_payments.csv'
    if len(sys.argv) is 2:
        paymentsFile = sys.argv[1]
    print 'Processing', paymentsFile

    print 'Subs'
    print getSubCounts(paymentsFile)
    
    print 'Gems'
    print getGemCounts(paymentsFile)

    print 'Pre-HoC Conversion Rates'
    priceConversionRates = getPreHoCPriceConversionRates(paymentsFile)
    print 'Price, converted, shown, conversion rate, value per user'
    for key, item in priceConversionRates.iteritems():
        print key, item['Finished subscription purchase'], item['Show subscription modal'], "%.4f%%" % (item['Conversion Rate'] * 100), "%.4f cents" % (item['Conversion Rate'] * int(key))
    
    print 'HoC Conversion Rates'
    priceConversionRates = getHoCPriceConversionRates(paymentsFile)
    print 'Price, converted, shown, conversion rate, value per user'
    for key, item in priceConversionRates.iteritems():
        print key, item['Finished subscription purchase'], item['Show subscription modal'], "%.4f%%" % (item['Conversion Rate'] * 100), "%.4f cents" % (item['Conversion Rate'] * int(key))
        
    print 'Post-HoC Conversion Rates'
    priceConversionRates = getPostHoCPriceConversionRates(paymentsFile)
    print 'Price, converted, shown, conversion rate, value per user'
    for key, item in priceConversionRates.iteritems():
        print key, item['Finished subscription purchase'], item['Show subscription modal'], "%.4f%%" % (item['Conversion Rate'] * 100), "%.4f cents" % (item['Conversion Rate'] * int(key))
        
