slack = require '../slack'
sendwithus = require '../sendwithus'
User = require '../models/User'

# TODO: Refactor notification (slack, watcher emails) logic here

module.exports = 
  notifyChangesMadeToDoc: (req, doc) ->
    # TODO: Stop using headers to pass edit paths. Perhaps should be a method property for Mongoose models
    editPath = req.headers['x-current-path']
    docLink = "http://codecombat.com#{editPath}" # TODO: Dynamically generate URL with server/commons/urls.makeHostUrl

    # Post a message on Slack
    message = "#{req.user.get('name')} saved a change to #{doc.get('name')}: #{doc.get('commitMessage') or '(no commit message)'} #{docLink}"
    slack.sendSlackMessage message, ['artisans']

    # Send emails to watchers
    watchers = doc.get('watchers') or []
    # Don't send these emails to the person who submitted the patch, or to Nick, George, or Scott.
    watchers = (w for w in watchers when not w.equals(req.user._id) and not (w.toHexString() in ['512ef4805a67a8c507000001', '5162fab9c92b4c751e000274', '51538fdb812dd9af02000001']))
    if watchers.length
      User.find({_id:{$in:watchers}}).select({email:1, name:1}).exec (err, watchers) ->
        for watcher in watchers
          continue if not watcher.get('email')
          context =
            email_id: sendwithus.templates.change_made_notify_watcher
            recipient:
              address: watcher.get('email')
              name: watcher.get('name')
            email_data:
              doc_name: doc.get('name') or '???'
              submitter_name: req.user.get('name') or '???'
              doc_link: if editPath then docLink else null
              commit_message: doc.get('commitMessage')
          sendwithus.api.send context, _.noop
     
