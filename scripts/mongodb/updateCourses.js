// Update course data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// eg: mongo localhost:27017/coco scripts/mongodb/updateCourses.js

// NOTE: uses name as unique identifier, so changing the name will insert a new course
// NOTE: pricePerSeat in USD cents

var courses =
[
  {
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
    name: "Computer Science 2",
    slug: "computer-science-2",
    campaignID: ObjectId("562f88e84df18473073c74e2"),
    description: "Introduce Arguments, Variables, If Statements, and Arithmetic.",
    duration: NumberInt(5),
    free: false,
    screenshot: "/images/pages/courses/102_info.png",
    releasePhase: 'released'
  },
  {
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
    name: "CS: Game Development 1",
    slug: "game-dev-1",
    campaignID: ObjectId("5789236960deed1f00ec2ab8"),
    description: "Learn to create your owns games which you can share with your friends.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'beta'
  },
  {
    name: "CS: Web Development 1",
    slug: "web-dev-1",
    campaignID: ObjectId("578913f2c8871ac2326fa3e4"),
    description: "Learn the basics of web development in this introductory HTML & CSS course.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'beta'
  },
  {
    name: "CS: Web Development 2",
    slug: "web-dev-2",
    campaignID: ObjectId("57891570c8871ac2326fa3f8"),
    description: "Learn more advanced web development, including scripting to make interactive webpages.",
    duration: NumberInt(2),
    free: false,
    releasePhase: 'beta'
  },
  {
    name: "JS Primer",
    slug: "js-primer",
    campaignID: ObjectId("579a5f37843ad12000e6d4c7"),
    description: "Learn JavaScript after you already know another programming language like Python.",
    duration: NumberInt(1),
    free: false,
    releasePhase: 'beta'
  }
];

print("Finding course concepts..");
for (var i = 0; i < courses.length; i++) {
  var concepts = {};
  var cursor = db.campaigns.find({_id: courses[i].campaignID}, {'levels': 1});
  if (cursor.hasNext()) {
    var doc = cursor.next();
    for (var levelID in doc.levels) {
      for (var j = 0; j < (doc.levels[levelID].concepts || []).length; j++) {
        concepts[doc.levels[levelID].concepts[j]] = true;
      }
    }
  }
  courses[i].concepts = Object.keys(concepts);
}

print("Updating courses..");
for (var i = 0; i < courses.length; i++) {
  db.courses.update({name: courses[i].name}, courses[i], {upsert: true});
}

print("Done.");
