User = require 'models/User'

module.exports = new User(
  {
    "_id": "teacher1",
    "testGroupNumber": 169,
    "anonymous": false,
    "__v": 0,
    "email": "teacher1@example.com",
    "emails": {
      "recruitNotes": {
        "enabled": true
      },
      "anyNotes": {
        "enabled": true
      },
      "generalNews": {
        "enabled": false
      }
    },
    "name": "Teacher Teacherson",
    "slug": "teacher-teacherson",
    "points": 20,
    "earned": {
      "gems": 0
    },
    "referrer": "http://localhost:3000/",
    "activity": {
      "login": {
        "last": "2016-03-07T19:57:05.007Z",
        "count": 8,
        "first": "2016-02-26T23:59:15.181Z"
      }
    },
    "volume": 1,
    "role": "teacher",
    "stripe": {
      "customerID": "cus_80OTFCpv2hArmT"
    },
    "dateCreated": "2016-02-26T23:49:23.696Z"
  }
)
