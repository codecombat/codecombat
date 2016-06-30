utils = require '../lib/utils'
errors = require '../commons/errors'
User = require '../models/User'
sendwithus = require '../sendwithus'
slack = require '../slack'
_ = require 'lodash'
wrap = require 'co-express'
mongoose = require 'mongoose'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  postNewVersion: (Model, options={}) -> wrap (req, res) ->
    parent = yield database.getDocFromHandle(req, Model)
    if not parent
      throw new errors.NotFound('Parent not found.')
      
    # TODO: Figure out a better way to do this
    if options.hasPermissionsOrTranslations
      permissions = options.hasPermissionsOrTranslations
      permissions = [permissions] if _.isString(permissions)
      permissions = ['admin'] if not _.isArray(permissions)
      hasPermission = _.any(req.user?.hasPermission(permission) for permission in permissions)
      if not (hasPermission or database.isJustFillingTranslations(req, parent))
        throw new errors.Forbidden()

    doc = database.initDoc(req, Model)
    ATTRIBUTES_NOT_INHERITED = ['_id', 'version', 'created', 'creator']
    doc.set(_.omit(parent.toObject(), ATTRIBUTES_NOT_INHERITED))

    database.assignBody(req, doc, { unsetMissing: true })

    # Get latest version
    major = req.body.version?.major
    original = parent.get('original')
    if _.isNumber(major)
      q1 = Model.findOne({original: original, 'version.isLatestMinor': true, 'version.major': major})
    else
      q1 = Model.findOne({original: original, 'version.isLatestMajor': true})
    q1.select 'version'
    latest = yield q1.exec()

    if not latest
      # handle the case where no version is marked as latest, since making new
      # versions is not atomic
      if _.isNumber(major)
        q2 = Model.findOne({original: original, 'version.major': major})
        q2.sort({'version.minor': -1})
      else
        q2 = Model.findOne()
        q2.sort({'version.major': -1, 'version.minor': -1})
      q2.select 'version'
      latest = yield q2.exec()
      if not latest
        throw new errors.NotFound('Previous version not found.')

    # Transfer latest version
    major = req.body.version?.major
    version = _.clone(latest.get('version'))
    wasLatestMajor = version.isLatestMajor
    version.isLatestMajor = false
    if _.isNumber(major)
      version.isLatestMinor = false

    conditions = {_id: latest._id}

    raw = yield Model.update(conditions, {version: version, $unset: {index: 1, slug: 1}})
    if not raw.nModified
      console.error('Conditions', conditions)
      console.error('Doc', doc)
      console.error('Raw response', raw)
      throw new errors.InternalServerError('Latest version could not be modified.')

    # update the new doc with version, index information
    # Relying heavily on Mongoose schema default behavior here. TODO: Make explicit?
    if _.isNumber(major)
      doc.set({
        'version.major': latest.version.major
        'version.minor': latest.version.minor + 1
        'version.isLatestMajor': wasLatestMajor
      })
      if wasLatestMajor
        doc.set('index', true)
      else
        doc.set({index: undefined, slug: undefined})
    else
      doc.set('version.major', latest.version.major + 1)
      doc.set('index', true)

    doc.set('parent', latest._id)

    doc = yield doc.save()

    editPath = req.headers['x-current-path']
    docLink = "http://codecombat.com#{editPath}"

    # Post a message on Slack
    message = "#{req.user.get('name')} saved a change to #{doc.get('name')}: #{doc.get('commitMessage') or '(no commit message)'} #{docLink}"
    slack.sendSlackMessage message, ['artisans']

    # Send emails to watchers
    watchers = doc.get('watchers') or []
    # Don't send these emails to the person who submitted the patch, or to Nick, George, or Scott.
    watchers = (w for w in watchers when not w.equals(req.user.get('_id')) and not (w + '' in ['512ef4805a67a8c507000001', '5162fab9c92b4c751e000274', '51538fdb812dd9af02000001']))
    if watchers.length
      User.find({_id:{$in:watchers}}).select({email:1, name:1}).exec (err, watchers) ->
        for watcher in watchers
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

    res.status(201).send(doc.toObject())

    
    
  getLatestVersion: (Model, options={}) -> wrap (req, res) ->
    # can get latest overall version, latest of a major version, or a specific version
    original = req.params.handle
    version = req.params.version
    if not database.isID(original)
      throw new errors.UnprocessableEntity('Invalid MongoDB id: '+original) 

    query = { 'original': mongoose.Types.ObjectId(original) }
    if version?
      version = version.split('.')
      majorVersion = parseInt(version[0])
      minorVersion = parseInt(version[1])
      query['version.major'] = majorVersion unless _.isNaN(majorVersion)
      query['version.minor'] = minorVersion unless _.isNaN(minorVersion)
    dbq = Model.findOne(query)
    
    dbq.sort({ 'version.major': -1, 'version.minor': -1 })

    # Make sure that permissions and version are fetched, but not sent back if they didn't ask for them.
    projection = parse.getProjectFromReq(req)
    if projection
      extraProjectionProps = []
      extraProjectionProps.push 'permissions' unless projection.permissions
      extraProjectionProps.push 'version' unless projection.version
      projection.permissions = 1
      projection.version = 1
      dbq.select(projection)

    doc = yield dbq.exec()
    throw new errors.NotFound() if not doc
    throw new errors.Forbidden() unless database.hasAccessToDocument(req, doc)
    doc = _.omit doc, extraProjectionProps if extraProjectionProps?
    
    res.status(200).send(doc.toObject())


  versions: (Model, options={}) -> wrap (req, res) ->
    original = req.params.handle
    dbq = Model.find({'original': mongoose.Types.ObjectId(original)})
    dbq.sort({'created': -1})
    dbq.limit(parse.getLimitFromReq(req))
    dbq.skip(parse.getSkipFromReq(req))
    dbq.select(parse.getProjectFromReq(req) or 'slug name version commitMessage created creator permissions')
    
    results = yield dbq.exec()
    res.status(200).send(results)
