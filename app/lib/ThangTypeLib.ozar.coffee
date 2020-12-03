utils = require 'core/utils'

ThangTypeLib =
  getPortraitURL: (thangTypeObj) ->
    return '' if application.testing
    if iconURL = thangTypeObj.rasterIcon
      return "/file/#{iconURL}"
    if rasterURL = thangTypeObj.raster
      return "/file/#{rasterURL}"
    "/file/db/thang.type/#{thangTypeObj.original}/portrait.png"

  getHeroShortName: (thangTypeObj) ->
    # New way: moved into ThangType model
    if shortName = utils.i18n thangTypeObj, 'shortName'
      return shortName

    # Old way: hard-coded
    map = {
      'Assassin': {'en-US': 'Ritic'}
      'Captain': {'en-US': 'Anya', 'zh-HANS': '安雅'}
      'Champion': {'en-US': 'Ida'}
      'Master Wizard': {'en-US': 'Usara'}
      'Duelist': {'en-US': 'Alejandro'}
      'Forest Archer': {'en-US': 'Naria'}
      'Goliath': {'en-US': 'Okar'}
      'Guardian': {'en-US': 'Illia'}
      'Knight': {'en-US': 'Tharin', 'zh-HANS': '坦林'}
      'Librarian': {'en-US': 'Hushbaum'}
      'Necromancer': {'en-US': 'Nalfar'}
      'Ninja': {'en-US': 'Amara'}
      'Pixie': {'en-US': 'Zana'}
      'Potion Master': {'en-US': 'Omarn'}
      'Raider': {'en-US': 'Arryn'}
      'Samurai': {'en-US': 'Hattori'}
      'Ian Elliott': {'en-US': 'Hattori'}
      'Sorcerer': {'en-US': 'Pender'}
      'Trapper': {'en-US': 'Senick'}
      'Code Ninja': {'en-US': 'Code Ninja'}
    }
    name = map[thangTypeObj.name]
    return translated if translated = name?[me.get('preferredLanguage', true)]
    return name?['en-US']

  getGender: (thangTypeObj) ->
    # New way: moved into ThangType model
    if gender = thangTypeObj?.gender
      return gender

    # Old way: hard-coded
    slug = thangTypeObj?.slug ? thangTypeObj?.get?('slug') ? ''
    heroGenders =
      male: ['knight', 'samurai', 'trapper', 'potion-master', 'goliath', 'assassin', 'necromancer', 'duelist', 'code-ninja']
      female: ['captain', 'ninja', 'forest-archer', 'librarian', 'sorcerer', 'raider', 'guardian', 'pixie', 'master-wizard', 'champion']
    if slug in heroGenders.female then 'female' else 'male'

module.exports = ThangTypeLib
