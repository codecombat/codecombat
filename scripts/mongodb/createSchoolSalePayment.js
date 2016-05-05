// Create external school sale payment object

// Usage:
// Modify/review hard coded data below.
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: Must use a valid Coco user id or email for purchaserID or recipientEmail, could be admin user id if necessary

// ** Start MODIFY/REVIEW values
var recipientEmail = 'pam@fred.com';
var purchaserID;  // Leave blank to use ID of user of valid Coco email address
var created = '2016-05-01T00:00:00.000Z';
var amount = 11111;  // Value in cents
var description = 'TODO: set this string to relevant school sale info'
// ** End MODIFY/REVIEW values

var service = 'external';

recipientEmail = recipientEmail.toLowerCase();

var user = db.users.findOne({emailLower: recipientEmail});
if (!purchaserID && user) {
    purchaserID = user._id + '';
}
if (!purchaserID) {
  print(`No valid purchaserID found for ${recipientEmail} or ${purchaserID}`);
  quit();
}

print("Input Data:");
print("recipientEmail\t", recipientEmail);
print("purchaserID\t", purchaserID);
print("created\t\t", created);
print("amount\t\t", amount);
print("service\t\t", service);

var criteria = {
  purchaser: ObjectId(purchaserID),
  created: created,
  amount: NumberInt(amount),
  description: description,
  service: service
}
if (user) {
  criteria.recipient = user._id
}
else if (purchaserID) {
  criteria.recipient = ObjectId(purchaserID);
}
else {
  print("ERROR: no valid user or purchaserID!");
  quit();
}

var existingPayment = db.payments.findOne(criteria);
if (existingPayment) {
    print(`Already have a payment for ${recipientEmail} purchaser ${purchaserID}: ${existingPayment._id.valueOf()}`);
}
else {
  db.payments.insert(criteria);
  print(`Added payment for ${recipientEmail}`);
}