// Bulk create prepaid codes + email message

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var num = 10;
var message = "Thanks for filling out the form.  You can follow this link to enable your free subscription for teachers.  If you have any questions or comments, please let me know.";
var urlPrefix = "https://codecombat.com/account/subscription?_ppc=";
var creatorID = "52f94443fcb334581466a992";

for (var i = 0; i < num; i++) {
  createPrepaid();
}

function createPrepaid()
{
  generateNewCode(function(code) {
    if (!code) {
      print("ERROR: no code");
      return;
    }
    criteria = {
      creator: creatorID,
      type: 'subscription',
      maxRedeemers: 1
      code: code,
      properties: {
        couponID: 'free'
      },
      __v: 0
    };
    db.prepaids.insert(criteria);

    print(message + "  " + urlPrefix + code);
  });
}

function generateNewCode(done)
{
  function tryCode() {
    code = createCode(8);
    criteria = {code: code};
    if (db.prepaids.findOne(criteria)) {
      return tryCode();
    }
    return done(code);
  }
  tryCode();
}

function createCode(length)
{
    var text = "";
    var possible = "abcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < length; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}
