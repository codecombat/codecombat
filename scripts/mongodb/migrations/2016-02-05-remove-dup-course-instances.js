
var currentClassroom = null;
var courseInstances = {};
var count = 0;
load('node_modules/lodash/lodash.js');

function toStrings(array) {
    return _.sortBy(_.map(array, function(item) { return item.valueOf(); }));
}

function mergeMembers(members1, members2) {
    var members1 = members1 || [];
    var members2 = members2 || [];
    var members = members1.concat(members2);
    if(!members.length) 
        return [];
    print('concat:');
    print('\t', members1.length, JSON.stringify(toStrings(members1)));
    print('\t', members2.length, JSON.stringify(toStrings(members2)));
    print('\t', members.length, JSON.stringify(toStrings(members)));
    members = _.uniq(members, false, function(member) { return member.valueOf() });
    print('\t', members.length, JSON.stringify(toStrings(members)));
    return members;
}

var count = 0;

db.course.instances.find({classroomID: {$exists: true}}).sort({classroomID: 1}).forEach(function(courseInstance) {
    count += 1;
    if(count % 100 === 0) { print('count', count); }
    if (!currentClassroom || !courseInstance.classroomID.equals(currentClassroom)) {
        currentClassroom = courseInstance.classroomID;
        courseInstances = {};
    }
    if (courseInstances[courseInstance.courseID]) {
        var keeper = courseInstances[courseInstance.courseID];
        if (!keeper.classroomID.equals(courseInstance.classroomID)) {
            throw new Error('This should not happen.');
            return;
        }
        print('duplicate...', count, 'in classroom', courseInstance.classroomID, keeper.members.length, courseInstance.members.length);
        print(JSON.stringify(courseInstance, null, '\t'));
        print(JSON.stringify(keeper, null, '\t'));
        keeper.members = mergeMembers(keeper.members, courseInstance.members);
        print('new members', keeper.members.length);
        print('save', db.course.instances.save(keeper));
        print('remove', db.course.instances.remove({_id:courseInstance._id}), true);
        print('keeper id', keeper._id)
    }
    else {
        courseInstances[courseInstance.courseID] = courseInstance;
    }
});