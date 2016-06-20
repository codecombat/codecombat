ModalView = require 'views/core/ModalView'
template = require 'templates/editor/thang/export-thang-type-modal'
SpriteExporter = require 'lib/sprites/SpriteExporter'

module.exports = class ExportThangTypeModal extends ModalView
  id: "export-thang-type-modal"
  template: template
  plain: true

  events:
    'click #save-btn': 'onClickSaveButton'

  initialize: (options, @thangType) ->
    @builder = null
    @getFilename = _.once(@getFilename)

  colorMap: {
    red: { hue: 0, saturation: 0.75, lightness: 0.5 }
    blue: { hue: 0.66, saturation: 0.75, lightness: 0.5 }
    green: { hue: 0.33, saturation: 0.75, lightness: 0.5 }
  }
  getColorLabel: -> @$('#color-config-select').val()
  getColorConfig: ->
    color = @colorMap[@getColorLabel()]
    return { team: color } if color
    return null
  getActionNames: -> _.map @$('input[name="action"]:checked'), (el) -> $(el).val()
  getResolutionFactor: -> parseInt(@$('#resolution-input').val()) or SPRITE_RESOLUTION_FACTOR
  getFilename: -> 'spritesheet-'+_.string.slugify(moment().format())+'.png'
  getSpriteType: -> @$('input[name="sprite-type"]:checked').val()

  onClickSaveButton: ->
    @$('.modal-footer button').addClass('hide')
    @$('.modal-footer .progress').removeClass('hide')
    @$('input, select').attr('disabled', true)
    options = {
      resolutionFactor: @getResolutionFactor()
      actionNames: @getActionNames()
      colorConfig: @getColorConfig()
      spriteType: @getSpriteType()
    }
    @exporter = new SpriteExporter(@thangType, options)
    @exporter.build()
    @listenToOnce @exporter, 'build', @onExporterBuild

  onExporterBuild: (e) ->
    @spriteSheet = e.spriteSheet
    src = @spriteSheet._images[0].toDataURL()
    src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+')
    body =
      filename: @getFilename()
      mimetype: 'image/png'
      path: "db/thang.type/#{@thangType.get('original')}"
      b64png: src
    $.ajax('/file', {type: 'POST', data: body, success: @onSpriteSheetUploaded})

  onSpriteSheetUploaded: =>
    spriteSheetData = {
      actionNames: @getActionNames()
      animations: @spriteSheet._data
      frames: ([
        f.rect.x
        f.rect.y
        f.rect.width
        f.rect.height
        0
        f.regX
        f.regY
      ] for f in @spriteSheet._frames)
      image: "db/thang.type/#{@thangType.get('original')}/"+@getFilename()
      resolutionFactor: @getResolutionFactor()
      spriteType: @getSpriteType()
    }
    if config = @getColorConfig()
      spriteSheetData.colorConfig = config
    if label = @getColorLabel()
      spriteSheetData.colorLabel = label
    spriteSheets = _.clone(@thangType.get('prerenderedSpriteSheetData') or [])
    spriteSheets.push(spriteSheetData)
    @thangType.set('prerenderedSpriteSheetData', spriteSheets)
    @thangType.save()
    @listenToOnce @thangType, 'sync', @hide

window.SomeModal = module.exports