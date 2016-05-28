// Script for changing prepaid start/end dates and propagating them to users.

/*
 *  Usage
 *  ---------------
 *  In mongo shell
 *
 *  > db.loadServerScripts();
 *  > var prepaids = getPrepaidsFor('some@email.com');  // prints basic stats for prepaids found
 *  > prepaids.models                                   // Raw prepaid data
 *  > prepaids.setStart(2001,1,1)                       // Set start date
 *  > prepaids.setEnd(2100,1,1)                         // Set end date
 */


function getPrepaidsFor(email) {
    var user = db.users.findOne({emailLower: email.toLowerCase()});
    if (!user) {
        print('User not found');
        return;
    }
    
    var result = {};
    result.models = db.prepaids.find({creator: user._id}).toArray();
    result.setStart = function(year, month, day) {
        var startDate = new Date(Date.UTC(year, month-1, day)).toISOString();
        print('setting to', startDate);
        for (var i in this.models) {
            var prepaid = this.models[i];
            print('Prepaid update', db.prepaids.update({_id: prepaid._id}, {$set: {startDate: startDate}}));
            print('User update', db.users.update({'coursePrepaid._id': prepaid._id}, {$set: {'coursePrepaid.startDate': startDate}}, {multi: true}));
        }
    };
    result.setEnd = function(year, month, day) {
        var endDate = new Date(Date.UTC(year, month-1, day)).toISOString();
        print('setting to', endDate);
        for (var i in this.models) {
            var prepaid = this.models[i];
            print('Prepaid update', db.prepaids.update({_id: prepaid._id}, {$set: {endDate: endDate}}));
            print('User update', db.users.update({'coursePrepaid._id': prepaid._id}, {$set: {'coursePrepaid.endDate': endDate}}, {multi: true}));
        }
    };
    
    for (var i in result.models) {
        var prepaid = result.models[i];
        print('Prepaid:', prepaid.startDate, 'to', prepaid.endDate, 'with', prepaid.redeemers.length, '/', prepaid.maxRedeemers, 'uses');
    }
    return result;
}


db.system.js.save(
    {
        _id: 'getPrepaidsFor',
        value: getPrepaidsFor
    }
);
