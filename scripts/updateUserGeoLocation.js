// Script to remove lastIP and add geo location using the IP for existing users
// For some users and their IPs, the geo location is not found (some are reserved IP addresses) - IP is removed anyways for them from the database (So, they dont have IP as well as geo location)
// TODO: Set geo location for existing users that we don’t have that data for yet given their current IP address, or move straight to adding a last known geo property set

require('coffee-script');
require('coffee-script/register');
global._ = require('lodash')
_.str = require('underscore.string')
database = require('../server/commons/database')
User = require('../server/models/User')
co = require('co')
countryList = require('country-list')()
geoip = require('@basicer/geoip-lite')
mongoose = require('mongoose')

database.connect()
var count = 0
var query = {"_id": {$gt: mongoose.Types.ObjectId('000000000000000000000000')}, "geo": {$exists: false}, "lastIP": {$exists: true}}

updateUser = co.wrap(function*(user) {
    //console.log(user);
    ip = user.get("lastIP")
    geo = geoip.lookup(ip)
    if (geo) {
        // Update Geo location
        userGeo = {}
        userGeo.country = geo.country
        if (country = geo.country)
        userGeo.countryName = countryList.getName(country)
        userGeo.region = geo.region
        userGeo.city = geo.city
        userGeo.ll = geo.ll
        userGeo.metro = geo.metro
        userGeo.zip = geo.zip
        user.set('geo', userGeo)
    }
    // Remove Last IP
    user.set('lastIP', undefined)
    //console.log("New user")
    //console.log(userGeo)
    //console.log(user)
    //database.validateDoc(user)
    try{
        res = yield user.save()
        count += 1
        if (geo) {
            console.log(new Date().toISOString(), "Updated user id: ", res._id, " with timestamp: ", res._id.getTimestamp())
        }
        else{
            // Geo location not found, just removed IP
            console.log(new Date().toISOString(), "Geo not found, Updated user id: ", res._id, " with timestamp: ", res._id.getTimestamp())
        }
    }
    catch(e){
        console.log("Error in save for :", user)
    }
})

co(function*() {
    while (true){
        console.log("Starting...")
        var users = yield User.find(query).limit(1).sort({_id:1})
        //console.log("All users", users)
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