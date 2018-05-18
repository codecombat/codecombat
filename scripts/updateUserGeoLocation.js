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

database.connect()
var count = 0

co(function*() {

    //var cursor = User.find({"geo": {$exists: false}, "lastIP": {$exists: true}},{"lastIP": 1, "geo": 1, "name": 1, "email": 1}).cursor()   // to update all users
    var cursor = User.find({"geo": {$exists: false}, "lastIP": {$exists: true}},{"lastIP": 1, "geo": 1, "name": 1, "email": 1}).limit(1).cursor()   // to update limited number of users
    
    for (let user = yield cursor.next(); user != null; user = yield cursor.next()) {
        //console.log(user);
        ip = user.get("lastIP")
        geo = geoip.lookup(ip)
        if (geo) {
            // Update Geo location and remove IP
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
            user.set('lastIP', undefined)
            database.validateDoc(user)
            res = yield user.save()
            count += 1
            console.log(new Date().toISOString(), "Updated user id: ", res._id)
        }
        else{
            // Geo location not found, just remove IP
            user.set('lastIP', undefined)
            database.validateDoc(user)
            res = yield user.save()
            count += 1
            console.log(new Date().toISOString(), "Geo not found, Updated user id: ", res._id)
        }
    }

  })
  .then(() => {
    console.log('Done')
    console.log("Users updated: ", count)
    process.exit()
  })
  .catch((e) => {
    console.log("Error: ")
        console.log(e)
        process.exit()
  })