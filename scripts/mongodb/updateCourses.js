// Update courses

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// eg: mongo localhost:27017/coco scripts/mongodb/updateCourses.js

// NOTE: Do not use this to create new courses

// TODO: Replace this script with the course editor

load('bower_components/lodash/dist/lodash.js');

var courses =
[
  {
    _id: ObjectId('560f1a9f22961295f9427742'),
    name: "Introduction to Computer Science",
    slug: "introduction-to-computer-science",
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d"),
    description: "Learn basic syntax, while loops, and the CodeCombat environment.",
    duration: NumberInt(1),
    free: true,
    screenshot: "/images/pages/courses/101_info.png",
    releasePhase: 'released'
  },
  {
    _id: ObjectId('5632661322961295f9428638'),
    name: "Computer Science 2",
    slug: "computer-science-2",
    campaignID: ObjectId("562f88e84df18473073c74e2"),
    description: "Introduces arguments, variables, if statements, and arithmetic.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/102_info.png",
    releasePhase: 'released'
  },
  {
    _id: ObjectId('5789587aad86a6efb573701e'),
    name: "Game Development 1",
    slug: "game-development-1",
    campaignID: ObjectId("5789236960deed1f00ec2ab8"),
    description: "Learn to create your own games which you can share with your friends.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'released'
  },
  {
    _id: ObjectId('5789587aad86a6efb573701f'),
    name: "Web Development 1",
    slug: "web-development-1",
    campaignID: ObjectId("578913f2c8871ac2326fa3e4"),
    description: "Learn the basics of web development in this introductory HTML & CSS course.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'released'
  },
  {
    _id: ObjectId('56462f935afde0c6fd30fc8c'),
    name: "Computer Science 3",
    slug: "computer-science-3",
    campaignID: ObjectId("56462ac4410c528505e1160a"),
    description: "Introduces arithmetic, counters, advanced while loops, break, continue, arrays.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/103_info.png",
    releasePhase: 'released'
  },
  {
    _id: ObjectId('57b621e7ad86a6efb5737e64'),
    name: "Game Development 2",
    slug: "game-development-2",
    campaignID: ObjectId("57b49c866430272000100c4d"),
    description: "Learn more advanced game development.",
    duration: NumberInt(2),
    free: false,
    releasePhase: 'released'
  },
  {
    _id: ObjectId('5789587aad86a6efb5737020'),
    name: "Web Development 2",
    slug: "web-development-2",
    campaignID: ObjectId("57891570c8871ac2326fa3f8"),
    description: "Learn more advanced web development, including scripting to make interactive webpages.",
    duration: NumberInt(2),
    free: false,
    releasePhase: 'released'
  },
  {
    _id: ObjectId('56462f935afde0c6fd30fc8d'),
    name: "Computer Science 4",
    slug: "computer-science-4",
    campaignID: ObjectId("56462c1133f1478605ebd018"),
    description: "Introduces object literals, for loops, function definitions, drawing, and modulo.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/104_info.png",
    releasePhase: 'released'
  },
  {
    _id: ObjectId('569ed916efa72b0ced971447'),
    name: "Computer Science 5",
    slug: "computer-science-5",
    campaignID: ObjectId("568ad069a6584820004437f2"),
    description: "Introduces function parameters, function return values and algorithms.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/105_info.png",
    releasePhase: 'released'
  },
  {
    _id: ObjectId('57a0dea5ad86a6efb57375c2'),
    name: "JS Primer",
    slug: "js-primer",
    campaignID: ObjectId("579a5f37843ad12000e6d4c7"),
    description: "Learn JavaScript after you already know another programming language like Python.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'beta'
  },
  {
    _id : ObjectId("5817d673e85d1220db624ca4"),
    name : "Computer Science 6",
    slug : "computer-science-6",
    campaignID: ObjectId("56a683b9506a6936008ba424"),
    description: "Dive deeper into more advanced algorithms, data structures, and computation.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/106_info.png",
    releasePhase : 'released'
  }
];

_.forEach(courses, function(course) {
  // Find course concepts
  var concepts = {};
  var cursor = db.campaigns.find({_id: course.campaignID}, {'levels': 1});
  if (cursor.hasNext()) {
    var doc = cursor.next();
    for (var levelID in doc.levels) {
      for (var j = 0; j < (doc.levels[levelID].concepts || []).length; j++) {
        concepts[doc.levels[levelID].concepts[j]] = true;
      }
    }
  }
  course.concepts = Object.keys(concepts);
});

print("Updating courses..");
for (var i = 0; i < courses.length; i++) {
  var result = db.courses.update({_id: courses[i]._id}, {$set: courses[i]});
  if (result.nMatched !== 1) {
    print("Failed to update " + courses[i].slug);
    print(JSON.stringify(result, null, 2));
  }
}

print("Upserting i18n", db.courses.update(
  {i18n: {$exists: false}}, 
  {$set: {i18n: {'-':{'-':'-'}}, i18nCoverage: []}},
  {multi: true}
));

print("Done.");
