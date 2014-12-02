# Life's too short to write these things in JS, so install cofmon:
# npm install -g cofmon
# Then you can paste CoffeeScript into it.

nDays = 1
dayOffset = 0.3
now = new Date()
startDate = new Date(now - 86400 * 1000 * (nDays + dayOffset))
endDate =   new Date(now - 86400 * 1000 * dayOffset)

users = db.users.find({dateCreated: {$gt: startDate, $lt: endDate}}, {_id: 1, name: 1, testGroupNumber: 1}).toArray()
goodUsers = []
for user in users
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
