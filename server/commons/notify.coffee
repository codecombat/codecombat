slack = require '../slack'
sendgrid = require '../sendgrid'
User = require '../models/User'
co = require 'co'
config = require '../../server_config'

# TODO: Refactor notification (other slack messages, patch emails) logic here

notifyChangesMadeToDoc = (req, doc) ->
  # TODO: Stop using headers to pass edit paths. Perhaps should be a method property for Mongoose models
  editPath = req.headers['x-current-path']
  docLink = "http://codecombat.com#{editPath}"  # TODO: Dynamically generate URL with server/commons/urls.makeHostUrl

  sendChangedSlackMessage creator: req.user, target: doc, docLink: docLink

  # Send emails to watchers
  watchers = doc.get('watchers') or []
  # Don't send these emails to the person who submitted the patch, or to Nick, George, or Scott.
  watchers = (w for w in watchers when not w.equals(req.user._id) and not (w.toHexString() in ['512ef4805a67a8c507000001', '5162fab9c92b4c751e000274', '51538fdb812dd9af02000001']))
  if watchers.length
    User.find({_id:{$in:watchers}}).select({email:1, name:1}).exec (err, watchers) ->
      for watcher in watchers
        notifyWatcherOfChange req.user, watcher, doc, docLink

sendChangedSlackMessage = (options) ->
  message = "#{options.creator.get('name')} saved a change to #{options.target.get('name')}: #{options.target.get('commitMessage') or '(no commit message)'} #{options.docLink}"
  slack.sendSlackMessage message, ['artisans']

notifyWatcherOfChange = co.wrap (editor, watcher, doc, docLink) ->
  return unless watcher.get('email')
  message =
    templateId: sendgrid.templates.change_made_notify_watcher
    to:
      email: watcher.get('email')
      name: watcher.get('name')
    from:
      email: config.mail.username
      name: 'CodeCombat'
    substitutions:
      watcher_name: watcher.get('name') or 'there'
      doc_name: doc.get('name') or '???'
      submitter_name: editor.get('name') or '???'
      doc_link: docLink
      commit_message: doc.get('commitMessage')
  try
    yield sendgrid.api.send message
  catch err
    console.error "sendgrid error sending watcher email:", err

module.exports = {
  notifyChangesMadeToDoc
  sendChangedSlackMessage
  notifyWatcherOfChange
}
