winston = require('winston')
request = require('request')
ThangType = require('../models/ThangType')
Handler = require('./Handler')

ThangTypeHandler = class ThangTypeHandler extends Handler
  modelClass: ThangType
  editableProperties: [
    'name',
    'raw',
    'actions',
    'soundTriggers',
    'rotationType',
    'matchWorldDimensions',
    'shadow',
    'layerPriority',
    'staticImage',
    'scale',
    'positions',
    'snap',
    'components'
    'colorGroups'
  ]

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new ThangTypeHandler()
