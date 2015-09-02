// Update course data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: uses name as unique identifier, so changing the name will insert a new course

var documents =
[
  {
    name: "Introduction to Computer Science",
    slug: "introduction-to-computer-science",
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d"),
    concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables'],
    description: "Learn basic syntax, while loops, and the CodeCombat environment.",
    screenshot: "/images/pages/courses/101_info.png"
  }
];

for (var i = 0; i < documents.length; i++) {
  var doc = documents[i];
  db.courses.update({name: doc.name}, doc, {upsert: true});
}

function log(str) {
  print(new Date().toISOString() + " " + str);
}
