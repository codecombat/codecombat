winston = require('winston')
request = require('request')
ThangType = require('./ThangType')
Handler = require('../../commons/Handler')

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
    'components',
    'colorGroups',
    'kind'
  ]

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new ThangTypeHandler()
