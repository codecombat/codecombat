'use strict';
// Find school data by state, export csv-formatted lines per-email

// Usage:
// mongo --quiet <address>:<port>/<database> <script file> -u <username> -p <password>

const scriptStartTime = new Date();

const debugOutput = false;

const stateRegex = /^mi$|michigan/i;

const INTRODUCTION_TO_COMPUTER_SCIENCE = '560f1a9f22961295f9427742';
const COMPUTER_SCIENCE_2 = '5632661322961295f9428638';

const emailSchoolDataMap = {};
const userIds = [];
const userTrialRequestMap = {};
debug(`DEBUG: fetching trial requests..`);
const trialRequests = db.trial.requests.find({'properties.state': {$regex: stateRegex}}).sort({created: 1}).toArray();
debug(`DEBUG: Num trial requests=${trialRequests.length}`);
for (var trialRequest of trialRequests) {
  const email = trialRequest.properties.email.toLowerCase();
  if (!emailSchoolDataMap[email]) emailSchoolDataMap[email] = {trialRequest: trialRequest};
  else debug(`ERROR: already have ${email}`);
  userTrialRequestMap[trialRequest.applicant.valueOf()] = trialRequest;
  userIds.push(trialRequest.applicant);
}

debug(`DEBUG: fetching users..`);
const userMap = {};
const users = db.users.find({$or: [{_id: {$in: userIds}}, {emailLower: {$in: Object.keys(emailSchoolDataMap)}}]}).toArray();
for (var user of users) {
  if (!user.emailLower) continue;
  if (!emailSchoolDataMap[user.emailLower]) emailSchoolDataMap[user.emailLower] = {};
  emailSchoolDataMap[user.emailLower].user = user;
  userMap[user._id.valueOf()] = user;
  userIds.push(user._id);
}

debug(`DEBUG: fetching classrooms..`);
const classroomIds = [];
const emailClassroomsMap = {};
const classrooms = db.classrooms.find({ownerID: {$in: userIds}}).toArray();
for (var classroom of classrooms) {
  const ownerId = classroom.ownerID.valueOf();
  if (!userMap[ownerId]) {
    // E.g. deleted user
    // debug(`ERROR: no user map for ${ownerId}`);
    continue;
  }
  const email = userMap[ownerId].emailLower;
  if (!email) continue;
  if (emailSchoolDataMap[email]) {
    if (!emailSchoolDataMap[email].classrooms) emailSchoolDataMap[email].classrooms = [];
    emailSchoolDataMap[email].classrooms.push(classroom);
  }
  else {
    debug(`ERROR: no email map for ${email}`);
  }
  classroomIds.push(classroom._id);
}

debug(`DEBUG: fetching course instances..`);
const classroomCourseInstancesMap = {};
const courseInstances = db.course.instances.find({classroomID: {$in: classroomIds}}).toArray();
for (var courseInstance of courseInstances) {
  if (!classroomCourseInstancesMap[courseInstance.classroomID.valueOf()]) {
    classroomCourseInstancesMap[courseInstance.classroomID.valueOf()] = [];
  }
  classroomCourseInstancesMap[courseInstance.classroomID.valueOf()].push(courseInstance);
}

const columnNames = ['Email', 'Name', 'Role', 'School', 'District', 'City', 'State', 'Education Level', 'Class start',
  'Free students', 'Paid students'];
print(columnNames.toString());

// Build up rows of of column data that matches columnNames above
for (var email in emailSchoolDataMap) {
  var trialRequest = emailSchoolDataMap[email].trialRequest;
  if (!trialRequest && emailSchoolDataMap[email].user && userTrialRequestMap[emailSchoolDataMap[email].user._id.valueOf()]) {
    // debug(`No trial request for ${email}, trying user id ${emailSchoolDataMap[email].user._id.valueOf()}`);
    trialRequest = userTrialRequestMap[emailSchoolDataMap[email].user._id.valueOf()];
  }
  if (!trialRequest) {
    debug(`ERROR: no trial request for ${email}`);
    continue;
  }

  var name = '';
  var schoolName = '';
  schoolName = trialRequest.properties.organization;
  if (trialRequest.firstName && trialRequest.lastName) {
    name = `${trialRequest.firstName} ${trialRequest.lastName}`;
  }
  if (!name && emailSchoolDataMap[email].user) {
    if (emailSchoolDataMap[email].user.firstName && emailSchoolDataMap[email].user.lastName) {
      name = `${emailSchoolDataMap[email].user.firstName} ${emailSchoolDataMap[email].user.lastName}`;
    }
    else {
      name = emailSchoolDataMap[email].user.name;
    }
  }
  const data = [email, name];
  data.push(trialRequest.properties.role || '');
  data.push(schoolName);
  data.push(trialRequest.properties.nces_district || '');
  data.push(trialRequest.properties.city || '');
  data.push(trialRequest.properties.state || '');
  data.push(trialRequest.properties.educationLevel ? `"${trialRequest.properties.educationLevel.toString()}"` : '');

  var earliestClassroom = null;
  var freeStudents = 0;
  var paidStudents = 0;
  for (var classroom of emailSchoolDataMap[email].classrooms || []) {
    if (!earliestClassroom || classroom._id.getTimestamp() < earliestClassroom) {
      earliestClassroom = classroom._id.getTimestamp();
    }
    for (var courseInstance of classroomCourseInstancesMap[classroom._id.valueOf()] || []) {
      if (courseInstance.courseID.valueOf() === INTRODUCTION_TO_COMPUTER_SCIENCE) {
        freeStudents += courseInstance.members.length;
      }
      else if (courseInstance.courseID.valueOf() === COMPUTER_SCIENCE_2) {
        paidStudents += courseInstance.members.length;
      }
    }
  }
  data.push(earliestClassroom ? earliestClassroom.toISOString() : '');
  data.push(freeStudents);
  data.push(paidStudents);

  if (data.length === columnNames.length) {
    print(data.toString());
  }
  else {
    print(`ERROR: data ${data.length} columnn count ${columnNames.length} mismatch for ${email}`);
  }
}

debug(`Script runtime: ${new Date() - scriptStartTime}`);

function debug(msg) {
  if (debugOutput) print(msg);
}
