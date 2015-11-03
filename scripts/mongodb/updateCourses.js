// Update course data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: uses name as unique identifier, so changing the name will insert a new course
// NOTE: pricePerSeat in USD cents

var courses =
[
  {
    name: "Introduction to Computer Science",
    slug: "introduction-to-computer-science",
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d"),
    concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables'],
    description: "Learn basic syntax, while loops, and the CodeCombat environment.",
    duration: NumberInt(1),
    pricePerSeat: NumberInt(0),
    screenshot: "/images/pages/courses/101_info.png"
  },
  {
    name: "Computer Science 2",
    slug: "computer-science-2",
    campaignID: ObjectId("562f88e84df18473073c74e2"),
    concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables', 'if_statements'],
    description: "Introduce Arguments, Variables, If Statements, and Arithmetic.",
    duration: NumberInt(5),
    pricePerSeat: NumberInt(400),
    screenshot: "/images/pages/courses/102_info.png"
  },
  {
    name: "Computer Science 3",
    slug: "computer-science-3",
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d"),
    concepts: ['if_statements', 'arithmetic'],
    description: "Learn how to handle input.",
    duration: NumberInt(5),
    pricePerSeat: NumberInt(400),
    screenshot: "/images/pages/courses/103_info.png"
  }
];

print("Finding course concepts..");
for (var i = 0; i < courses.length; i++) {
  var concepts = {};
  var cursor = db.campaigns.find({_id: courses[i].campaignID}, {'levels': 1});
  if (cursor.hasNext()) {
    var doc = cursor.next();
    for (var levelID in doc.levels) {
      for (var j = 0; j < doc.levels[levelID].concepts.length; j++) {
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
