errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
Achievement = require '../models/Achievement'

module.exports =
  fetchByRelated: wrap (req, res, next) ->
    related = req.query.related
    return next() unless related
    achievements = yield Achievement.find {related: related}
    achievements = (achievement.toObject({req: req}) for achievement in achievements)
    res.status(200).send(achievements)

  put: wrap (req, res, next) ->
    achievement = yield database.getDocFromHandle(req, Achievement)
    if not achievement
      throw new errors.NotFound('Document not found.')
    hasPermission = req.user.isAdmin() or req.user.isArtisan()
    unless hasPermission or database.isJustFillingTranslations(req, achievement)
      throw new errors.Forbidden('Must be an admin, artisan or submitting translations to edit an achievement')

    database.assignBody(req, achievement)
    database.validateDoc(achievement)
    achievement = yield achievement.save()
    res.status(200).send(achievement.toObject({req: req}))
