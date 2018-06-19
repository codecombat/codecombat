// Script to update slugified country values for user.country and user.geo.countryName

require('coffee-script');
require('coffee-script/register');
global._ = require('lodash')
_.str = require('underscore.string')
database = require('../server/commons/database')
User = require('../server/models/User')
co = require('co')
mongoose = require('mongoose')

database.connect()
var count = 0
var query = {"_id": {$gt: mongoose.Types.ObjectId('000000000000000000000000')}, 
            $or: [
                {"geo": {$exists: true}},
                {"country": {$exists: true}}
            ]
        }

updateUser = co.wrap(function*(user) {
    geo = user.get("geo")
    country = user.get("country")
    if (geo && geo.countryName){
        countryNameSlug = _.str.slugify(geo.countryName)
        user.set('geo.countryName', countryNameSlug)
        if (!country){
            user.set("country", countryNameSlug)
        }
    }
    if (country){
        user.set("country", _.str.slugify(country))
    }
    database.validateDoc(user)
    try{
        res = yield user.save()
        count += 1
        console.log(new Date().toISOString(), "Updated user id: ", res._id, " with timestamp: ", res._id.getTimestamp())
    }
    catch(e){
        console.log("Error in save for :", user)
    }
})

co(function*() {
    while (true){
        console.log("Starting...")
        var users = yield User.find(query).limit(100).sort({_id:1})  // change limit as required
        if (users.length == 0) {
            break
        }
        promises = users.map((user) => updateUser(user))
        try{
            yield Promise.all(promises)
        }
        catch(e){
            console.log("Users updated: ", count)
            console.log("Error: ", e)
            process.exit()
        }
        query._id.$gt = _.last(users)._id
    }
}).then(() => {
    console.log('Done')
    console.log("Users updated: ", count)
    process.exit()
}).catch((e) => {
    console.log("Users updated: ", count)
    console.log("Error: ")
    console.log(e)
    process.exit()
})