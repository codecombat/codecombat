# Life's too short to write these things in JS, so install cofmon:
# npm install -g cofmon
# Then you can paste CoffeeScript into it.

nDays = 3
dayOffset = 0.2
now = new Date()
startDate = new Date(now - 86400 * 1000 * (nDays + dayOffset))
endDate =   new Date(now - 86400 * 1000 * dayOffset)

users = db.users.find({dateCreated: {$gt: startDate, $lt: endDate}}, {_id: 1, name: 1, testGroupNumber: 1, email: true}).toArray()
goodUsers = []
for user in users when user.email
  totalPlaytime = 0
  sessions = db.level.sessions.find({creator: '' + user._id}, {playtime: 1, levelID: 1}).toArray()
  firstSessions = []
  for session in sessions when session.playtime
    totalPlaytime += session.playtime
    if totalPlaytime > 60 * 60
      break
    firstSessions.push session
  if totalPlaytime < 60 * 60
    continue
  goodUsers.push {user: user, playtime: totalPlaytime, sessions: firstSessions}

levelUserCounts = {}
for user in goodUsers
  for session in user.sessions
    levelUserCounts[session.levelID] ?= 0
    levelUserCounts[session.levelID]++

print "Found #{goodUsers.length} users who played more than an hour out of #{users.length}."
print "Levels by number of users completing:"
levelUserCounts


"""
Found 194 users who played more than an hour out of 93952.
rs0:PRIMARY> levelUserCounts;
{
  "dungeons-of-kithgard" : 190,
  "gems-in-the-deep" : 184,
  "shadow-guard" : 186,
  "forgetful-gemsmith" : 189,
  "kounter-kithwise" : 80,
  "true-names" : 186,
  "favorable-odds" : 76,
  "the-raised-sword" : 181,
  "haunted-kithmaze" : 181,
  "descending-further" : 70,
  "the-second-kithmaze" : 171,
  "dread-door" : 172,
  "known-enemy" : 170,
  "master-of-names" : 160,
  "lowly-kithmen" : 138,
  "closing-the-distance" : 137,
  "tactical-strike" : 48,
  "the-final-kithmaze" : 108,
  "the-gauntlet" : 43,
  "kithgard-gates" : 96,
  "defense-of-plainswood" : 88,
  "winding-trail" : 75,
  "endangered-burl" : 51,
  "village-guard" : 40,
  "thornbush-farm" : 33,
  "back-to-back" : 27,
  "ogre-encampment" : 22,
  "woodland-cleaver" : 18,
  "shield-rush" : 10,
  "peasant-protection" : 8,
  "munchkin-swarm" : 10,
  "munchkin-harvest" : 4,
  "swift-dagger" : 1,
  "shrapnel" : 1,
  "arcane-ally" : 1,
  "touch-of-death" : 1
  "bonemender" : 1,
  "coinucopia" : 6,
  "copper-meadows" : 3,
  "drop-the-flag" : 3,
  "deadly-pursuit" : 2,
  "rich-forager" : 1,
  "multiplayer-treasure-grove" : 1,

  "rescue-mission" : 2,
  "dungeon-arena-tutorial" : 3,
  "dungeon-arena" : 2,
  "undefined" : 2,
  "grab-the-mushroom" : 2,
  "gold-rush" : 1,
  "criss-cross" : 1,
}
"""

# With usernames, 3 days instead of 1:
"""
Found 532 users who played more than an hour out of 277828.
>
> print("Levels by number of users completing:");
Levels by number of users completing:
>
> levelUserCounts;
{
  "dungeons-of-kithgard" : 524,
  "gems-in-the-deep" : 513,
  "shadow-guard" : 515,
  "kounter-kithwise" : 229,
  "forgetful-gemsmith" : 520,
  "true-names" : 516,
  "favorable-odds" : 216,
  "the-raised-sword" : 504,
  "haunted-kithmaze" : 494,
  "the-second-kithmaze" : 472,
  "dread-door" : 475,
  "known-enemy" : 463,
  "master-of-names" : 440,
  "lowly-kithmen" : 403,
  "closing-the-distance" : 393,
  "tactical-strike" : 139,
  "the-final-kithmaze" : 321,
  "the-gauntlet" : 113,
  "kithgard-gates" : 253,
  "defense-of-plainswood" : 236,
  "descending-further" : 200,
  "winding-trail" : 196,
  "endangered-burl" : 133,
  "village-guard" : 118,
  "thornbush-farm" :  89,
  "back-to-back" :  77,
  "ogre-encampment" :  66,
  "woodland-cleaver" :  56,
  "shield-rush" :  32,
  "peasant-protection" :  30,
  "munchkin-swarm" :  28,
  "munchkin-harvest" :   9,
  "swift-dagger" :   3,
  "shrapnel" :   1,
  "arcane-ally" :  10,
  "bonemender" :   4,
  "coinucopia" :  21,
  "copper-meadows" :  17,
  "drop-the-flag" :  11,
  "deadly-pursuit" :  13,
  "rich-forager" :   6,

  "undefined" :   8,
  "dungeon-arena-tutorial" :   8,
  "dungeon-arena" :   8,
  "grab-the-mushroom" :   6,
  "gold-rush" :   6,
  "criss-cross" :   4,
  "rescue-mission" :   3,
  "touch-of-death" :   2,
  "taunt-the-guards" :   1,
  "taunt" :   1,
  "sky-span" :   1,
  "greed" :   1,
  "dungeon-battle" :   1,
  "drink-me" :   1,
  "cowardly-taunt" :   1,
  "bubble-sort-bootcamp-battle" :   1,
  "break-the-prison" :   1
}
"""
