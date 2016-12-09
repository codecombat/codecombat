load('bower_components/lodash/dist/lodash.js');

// Total number of low priority leads
var lowPriLeads = db.trial.requests.find({ "properties.numStudents": '1-10' })
print("Number of low priority leads total:", lowPriLeads.count())


// Number of low priority leads per week
var oneWeek = 1000*60*60*24*7
var endDate = new Date()
var startDate = new Date()
startDate.setTime(endDate.getTime() - oneWeek)

for (i = 0; i < 10; i++) {
  var lowPriThisWeek = db.trial.requests.find({
    "properties.numStudents": '1-10', created: {$lt: endDate, $gt: startDate}
  })
  print("Number of low priority leads on the week starting", startDate, ":", lowPriThisWeek.count());
  startDate.setTime(startDate.getTime() - oneWeek)
  endDate.setTime(endDate.getTime() - oneWeek)
}


// Total number of unique students across all classrooms for low-pri leads
lowPriLeads = db.trial.requests.find({ "properties.numStudents": '1-10' })
var lowPriTeachers = lowPriLeads.map((trialRequest) => { return trialRequest.applicant }).filter((a)=>{return a});
var lowPriClassrooms = db.classrooms.find({ ownerID: { $in: lowPriTeachers } }, {ownerID: true, members: true}).toArray();
print("Number of low priority classrooms:", lowPriClassrooms.length);

allMembers = _.flatten(lowPriClassrooms.map((classroom)=>{
  return classroom.members
}))
print("Total number of (non-uniqued) students in low-pri classrooms:", allMembers.length)
print("Total number of (unique) students in low-pri classrooms:", _.uniq(allMembers.map((a)=>{return a.toString()})).length)


// How many users purchased starter licenses?
numUsersThatBoughtStarterLicenses = db.prepaids.aggregate([
  { $match: { type: 'starter_license' } },
  { $group: { _id: '$creator' } },
  { $group: { _id: 'count', count: { $sum: 1 } } }
]).toArray()[0].count
print("Number of users that bought starter licenses: ", numUsersThatBoughtStarterLicenses)


// How many low-pri leads purchased starter licenses?
numLowPriThatBoughtStarterLicenses = db.prepaids.aggregate([
  { $match: { type: 'starter_license', creator: {$in: lowPriTeachers} } },
  { $group: { _id: '$creator' } },
  { $group: { _id: 'count', count: { $sum: 1 } } }
]).toArray()[0].count
print("Number of low-pri users that bought starter licenses: ", numLowPriThatBoughtStarterLicenses)


// How many starter licenses does each teacher buy?
purchaseCounts = db.prepaids.aggregate([
  { $match: { type: 'starter_license' } },
  { $group: { _id: '$creator', starterLicensesBought: {$sum: '$maxRedeemers'} } },
  { $sort: { starterLicensesBought: -1 } }
]).toArray()
print("How many starter licenses each teacher bought: ")
purchaseCounts.forEach((a)=>{
  print(a.starterLicensesBought, db.users.find({_id: a._id}, {name: true, email: true}).toArray()[0].email)
})

db.users.find({ _id: { $in: purchaseCounts.map((a)=>{return a._id}) } }, {name: true, email: true})
