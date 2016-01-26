// Latest approved teacher trial requests

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var requests = db.trial.requests.find().toArray();
function format(r) { 
  var p = r.properties;
  return [r.created.getFullYear() + '-' + (r.created.getMonth() + 1) + '-' + r.created.getDate(), r.status, r.type, p.email, p.school, p.location, p.age, p.numStudents, p.heardAbout].join('\t').replace(/[\n\r]/g, '     ');
}
print(requests.map(format).join('\n'));
