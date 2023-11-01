I18NEditModelView = require './I18NEditModelView'
Product = require 'models/Product'
deltasLib = require 'core/deltas'
Patch = require 'models/Patch'
Patches = require 'collections/Patches'
PatchModal = require 'views/editor/PatchModal'

# TODO: Apply these changes to all i18n views if it proves to be more reliable

module.exports = class I18NEditProductView extends I18NEditModelView
  id: "i18n-edit-product-view"
  modelClass: Product

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('displayName')
        @wrapRow 'Product short name', ['displayName'], name, i18n[lang]?.displayName, []
      if description = @model.get('displayDescription')
        @wrapRow 'Product description', ['displayDescription'], description, i18n[lang]?.displayDescription, []

