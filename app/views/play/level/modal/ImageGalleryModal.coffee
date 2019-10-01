require('app/styles/play/modal/image-gallery-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
utils = require 'core/utils'

module.exports = class ImageGalleryModal extends ModalView
  id: 'image-gallery-modal'
  template: require 'templates/play/level/modal/image-gallery-modal'

  events:
    'click .image-list-item': 'onClickImageListItem'
    'click .copy-url-button': 'onClickCopyUrlButton'
    'click .copy-tag-button': 'onClickCopyTagButton'

  getRenderData: ->
    _.merge super(arguments...), { utils }

  initialize: ->
    @state = new State()
    @listenTo @state, 'all', =>
      @renderSelectors('.render')
      @afterRender()

  afterRender: ->
    if utils.userAgent().indexOf("Mac") > -1
      @$('.windows-only').addClass('hidden')
      @$('.mac-only').removeClass('hidden')

  onClickImageListItem: (e) ->
    selectedUrl = $(e.currentTarget).data('portrait-url')
    @state.set { selectedUrl }

  onClickCopyUrlButton: (e) ->
    $('.image-url').select()
    @tryCopy()

  onClickCopyTagButton: (e) ->
    $('.image-tag').select()
    @tryCopy()

  # Top most useful Thang portraits
  images: [
     {slug: 'archer-f', name: 'Archer F', original: '529ab1a24b67a988ad000002', portraitURL: '/file/db/thang.type/529ab1a24b67a988ad000002/portrait.png', kind: 'Unit'}
     {slug: 'archer-m', name: 'Archer M', original: '52cee45a76ebd5196b00003a', portraitURL: '/file/db/thang.type/52cee45a76ebd5196b00003a/portrait.png', kind: 'Unit'}
     {slug: 'artist', name: 'Artist', original: '56d0c4f601476e2100de76c0', portraitURL: '/file/db/thang.type/56d0c4f601476e2100de76c0/portrait.png', kind: 'Unit'}
     {slug: 'assassin', name: 'Assassin', original: '566a2202e132c81f00f38c81', portraitURL: '/file/db/thang.type/566a2202e132c81f00f38c81/portrait.png', kind: 'Hero'}
     {slug: 'baby-griffin', name: 'baby griffin', original: '57586f0a22179b2800efda37', portraitURL: '/file/db/thang.type/57586f0a22179b2800efda37/portrait.png', kind: 'Item'}
     {slug: 'basic-flags', name: 'Basic Flags', original: '545bacb41e649a4495f887da', portraitURL: '/file/db/thang.type/545bacb41e649a4495f887da/portrait.png', kind: 'Item'}
     {slug: 'boom-ball', name: 'Boom Ball', original: '54eb540b49fa2d5c905ddf1a', portraitURL: '/file/db/thang.type/54eb540b49fa2d5c905ddf1a/portrait.png', kind: 'Item'}
     {slug: 'breaker', name: 'Breaker', original: '56d0dd5b441ddd2f002ba3d8', portraitURL: '/file/db/thang.type/56d0dd5b441ddd2f002ba3d8/portrait.png', kind: 'Unit'}
     {slug: 'burl', name: 'Burl', original: '530e5926c06854403ba68693', portraitURL: '/file/db/thang.type/530e5926c06854403ba68693/portrait.png', kind: 'Unit'}
     {slug: 'captain', name: 'Captain', original: '529ec584c423d4e83b000014', portraitURL: '/file/db/thang.type/529ec584c423d4e83b000014/portrait.png', kind: 'Hero'}
     {slug: 'champion', name: 'Champion', original: '575848b522179b2800efbfbf', portraitURL: '/file/db/thang.type/575848b522179b2800efbfbf/portrait.png', kind: 'Hero'}
     {slug: 'chest-of-gems', name: 'Chest of Gems', original: '5432f9d18364d30000d1f943', portraitURL: '/file/db/thang.type/5432f9d18364d30000d1f943/portrait.png', kind: 'Misc'}
     {slug: 'confuse', name: 'Confuse', original: '53024b76a6efdd32359c5340', portraitURL: '/file/db/thang.type/53024b76a6efdd32359c5340/portrait.png', kind: 'Mark'}
     {slug: 'control', name: 'Control', original: '53024c7b27471514685d5397', portraitURL: '/file/db/thang.type/53024c7b27471514685d5397/portrait.png', kind: 'Mark'}
     {slug: 'cougar', name: 'Cougar', original: '5744e3683af6bf590cd27371', portraitURL: '/file/db/thang.type/5744e3683af6bf590cd27371/portrait.png', kind: 'Item'}
     {slug: 'cow', name: 'Cow', original: '52e95a5022efc8e709001743', portraitURL: '/file/db/thang.type/52e95a5022efc8e709001743/portrait.png', kind: 'Doodad'}
     {slug: 'dantdm', name: 'DanTDM', original: '578674c3a6c641350091b645', portraitURL: '/file/db/thang.type/578674c3a6c641350091b645/portrait.png', kind: 'Unit'}
     {slug: 'desert-bones-2', name: 'Desert Bones 2', original: '548cf11b0f559d0000be7e2b', portraitURL: '/file/db/thang.type/548cf11b0f559d0000be7e2b/portrait.png', kind: 'Doodad'}
     {slug: 'duelist', name: 'Duelist', original: '57588f09046caf2e0012ed41', portraitURL: '/file/db/thang.type/57588f09046caf2e0012ed41/portrait.png', kind: 'Hero'}
     {slug: 'equestrian', name: 'Equestrian', original: '52e95b4222efc8e70900175d', portraitURL: '/file/db/thang.type/52e95b4222efc8e70900175d/portrait.png', kind: 'Unit'}
     {slug: 'flower-1', name: 'Flower 1', original: '54e951c8f54ef5794f354ed1', portraitURL: '/file/db/thang.type/54e951c8f54ef5794f354ed1/portrait.png', kind: 'Doodad'}
     {slug: 'flower-2', name: 'Flower 2', original: '54e9525ff54ef5794f354ed5', portraitURL: '/file/db/thang.type/54e9525ff54ef5794f354ed5/portrait.png', kind: 'Doodad'}
     {slug: 'flower-3', name: 'Flower 3', original: '54e95293f54ef5794f354ed9', portraitURL: '/file/db/thang.type/54e95293f54ef5794f354ed9/portrait.png', kind: 'Doodad'}
     {slug: 'flower-4', name: 'Flower 4', original: '54e952b7f54ef5794f354edd', portraitURL: '/file/db/thang.type/54e952b7f54ef5794f354edd/portrait.png', kind: 'Doodad'}
     {slug: 'flower-5', name: 'Flower 5', original: '54e952daf54ef5794f354ee1', portraitURL: '/file/db/thang.type/54e952daf54ef5794f354ee1/portrait.png', kind: 'Doodad'}
     {slug: 'flower-6', name: 'Flower 6', original: '54e95308f54ef5794f354ee5', portraitURL: '/file/db/thang.type/54e95308f54ef5794f354ee5/portrait.png', kind: 'Doodad'}
     {slug: 'flower-7', name: 'Flower 7', original: '54e9532ff54ef5794f354ee9', portraitURL: '/file/db/thang.type/54e9532ff54ef5794f354ee9/portrait.png', kind: 'Doodad'}
     {slug: 'flower-8', name: 'Flower 8', original: '54e9534ef54ef5794f354eed', portraitURL: '/file/db/thang.type/54e9534ef54ef5794f354eed/portrait.png', kind: 'Doodad'}
     {slug: 'forest-archer', name: 'Forest Archer', original: '5466d4f2417c8b48a9811e87', portraitURL: '/file/db/thang.type/5466d4f2417c8b48a9811e87/portrait.png', kind: 'Hero'}
     {slug: 'frozen-munchkin', name: 'Frozen Munchkin', original: '5576686e1e82182d9e6889bb', portraitURL: '/file/db/thang.type/5576686e1e82182d9e6889bb/portrait.png', kind: 'Doodad'}
     {slug: 'frozen-soldier-f', name: 'Frozen Soldier F', original: '5576683e1e82182d9e6889b7', portraitURL: '/file/db/thang.type/5576683e1e82182d9e6889b7/portrait.png', kind: 'Doodad'}
     {slug: 'frozen-soldier-m', name: 'Frozen Soldier M', original: '557662bf1e82182d9e6889af', portraitURL: '/file/db/thang.type/557662bf1e82182d9e6889af/portrait.png', kind: 'Doodad'}
     {slug: 'gem', name: 'Gem', original: '52aa3b9eccbd588d4d000003', portraitURL: '/file/db/thang.type/52aa3b9eccbd588d4d000003/portrait.png', kind: 'Misc'}
     {slug: 'gold-coin', name: 'Gold Coin', original: '535ef031c519160709f2f63a', portraitURL: '/file/db/thang.type/535ef031c519160709f2f63a/portrait.png', kind: 'Misc'}
     {slug: 'goliath', name: 'Goliath', original: '55e1a6e876cb0948c96af9f8', portraitURL: '/file/db/thang.type/55e1a6e876cb0948c96af9f8/portrait.png', kind: 'Hero'}
     {slug: 'guardian', name: 'Guardian', original: '566a058620de41290036a745', portraitURL: '/file/db/thang.type/566a058620de41290036a745/portrait.png', kind: 'Hero'}
     {slug: 'horse', name: 'Horse', original: '52e989a4427172ae56001f04', portraitURL: '/file/db/thang.type/52e989a4427172ae56001f04/portrait.png', kind: 'Doodad'}
     {slug: 'knight', name: 'Knight', original: '529ffbf1cf1818f2be000001', portraitURL: '/file/db/thang.type/529ffbf1cf1818f2be000001/portrait.png', kind: 'Hero'}
     {slug: 'librarian', name: 'Librarian', original: '52fbf74b7e01835453bd8d8e', portraitURL: '/file/db/thang.type/52fbf74b7e01835453bd8d8e/portrait.png', kind: 'Hero'}
     {slug: 'necromancer', name: 'Necromancer', original: '55652fb3b9effa46a1f775fd', portraitURL: '/file/db/thang.type/55652fb3b9effa46a1f775fd/portrait.png', kind: 'Hero'}
     {slug: 'ninja', name: 'Ninja', original: '52fc0ed77e01835453bd8f6c', portraitURL: '/file/db/thang.type/52fc0ed77e01835453bd8f6c/portrait.png', kind: 'Hero'}
     {slug: 'ogre-brawler', name: 'Ogre Brawler', original: '529e5ee76febb9ca7e00000b', portraitURL: '/file/db/thang.type/529e5ee76febb9ca7e00000b/portrait.png', kind: 'Unit'}
     {slug: 'ogre-chieftain', name: 'Ogre Chieftain', original: '55370661428ddac5686fd026', portraitURL: '/file/db/thang.type/55370661428ddac5686fd026/portrait.png', kind: 'Unit'}
     {slug: 'ogre-f', name: 'Ogre F', original: '52cedd3e0b0d5c1b4c003ec6', portraitURL: '/file/db/thang.type/52cedd3e0b0d5c1b4c003ec6/portrait.png', kind: 'Unit'}
     {slug: 'ogre-fangrider', name: 'Ogre Fangrider', original: '529e5f0c6febb9ca7e00000c', portraitURL: '/file/db/thang.type/529e5f0c6febb9ca7e00000c/portrait.png', kind: 'Unit'}
     {slug: 'ogre-headhunter', name: 'Ogre Headhunter', original: '54c96c3cdef3ad363ff998a1', portraitURL: '/file/db/thang.type/54c96c3cdef3ad363ff998a1/portrait.png', kind: 'Unit'}
     {slug: 'ogre-m', name: 'Ogre M', original: '529e40856febb9ca7e000004', portraitURL: '/file/db/thang.type/529e40856febb9ca7e000004/portrait.png', kind: 'Unit'}
     {slug: 'ogre-munchkin-f', name: 'Ogre Munchkin F', original: '52cee1d976ebd5196b000038', portraitURL: '/file/db/thang.type/52cee1d976ebd5196b000038/portrait.png', kind: 'Unit'}
     {slug: 'ogre-munchkin-m', name: 'Ogre Munchkin M', original: '529e5d756febb9ca7e00000a', portraitURL: '/file/db/thang.type/529e5d756febb9ca7e00000a/portrait.png', kind: 'Unit'}
     {slug: 'ogre-shaman', name: 'Ogre Shaman', original: '529f92f9dacd325127000008', portraitURL: '/file/db/thang.type/529f92f9dacd325127000008/portrait.png', kind: 'Unit'}
     {slug: 'ogre-thrower', name: 'Ogre Thrower', original: '529fff23cf1818f2be000003', portraitURL: '/file/db/thang.type/529fff23cf1818f2be000003/portrait.png', kind: 'Unit'}
     {slug: 'ogre-warlock', name: 'Ogre Warlock', original: '5536f88c428ddac5686fd00c', portraitURL: '/file/db/thang.type/5536f88c428ddac5686fd00c/portrait.png', kind: 'Unit'}
     {slug: 'ogre-witch', name: 'Ogre Witch', original: '5536ce98428ddac5686fcfd3', portraitURL: '/file/db/thang.type/5536ce98428ddac5686fcfd3/portrait.png', kind: 'Unit'}
     {slug: 'oracle', name: 'Oracle', original: '56d0cfa063103d2a00af5449', portraitURL: '/file/db/thang.type/56d0cfa063103d2a00af5449/portrait.png', kind: 'Unit'}
     {slug: 'paladin', name: 'Paladin', original: '552be965c54551e79b57b766', portraitURL: '/file/db/thang.type/552be965c54551e79b57b766/portrait.png', kind: 'Unit'}
     {slug: 'peasant-f', name: 'Peasant F', original: '52d48f02d0ce9936e2000005', portraitURL: '/file/db/thang.type/52d48f02d0ce9936e2000005/portrait.png', kind: 'Unit'}
     {slug: 'peasant-m', name: 'Peasant M', original: '529f9026dacd325127000005', portraitURL: '/file/db/thang.type/529f9026dacd325127000005/portrait.png', kind: 'Unit'}
     {slug: 'polar-bear-cub', name: 'Polar Bear Cub', original: '578691f9bd31c1440083251d', portraitURL: '/file/db/thang.type/578691f9bd31c1440083251d/portrait.png', kind: 'Item'}
     {slug: 'potion-master', name: 'Potion Master', original: '52e9adf7427172ae56002172', portraitURL: '/file/db/thang.type/52e9adf7427172ae56002172/portrait.png', kind: 'Hero'}
     {slug: 'pugicorn', name: 'Pugicorn', original: '577d5d4dab818b210046b3bf', portraitURL: '/file/db/thang.type/577d5d4dab818b210046b3bf/portrait.png', kind: 'Item'}
     {slug: 'raider', name: 'Raider', original: '55527eb0b8abf4ba1fe9a107', portraitURL: '/file/db/thang.type/55527eb0b8abf4ba1fe9a107/portrait.png', kind: 'Hero'}
     {slug: 'raven', name: 'Raven', original: '5786a472a6c64135009238d3', portraitURL: '/file/db/thang.type/5786a472a6c64135009238d3/portrait.png', kind: 'Item'}
     {slug: 'raven-pet', name: 'Raven Pet', original: '540f389a821af8000097dc5a', portraitURL: '/file/db/thang.type/540f389a821af8000097dc5a/portrait.png', kind: 'Unit'}
     {slug: 'razordisc', name: 'Razordisc', original: '54eb4d5949fa2d5c905ddf06', portraitURL: '/file/db/thang.type/54eb4d5949fa2d5c905ddf06/portrait.png', kind: 'Item'}
     {slug: 'samurai', name: 'Samurai', original: '53e12be0d042f23505c3023b', portraitURL: '/file/db/thang.type/53e12be0d042f23505c3023b/portrait.png', kind: 'Hero'}
     {slug: 'skeleton', name: 'Skeleton', original: '54c83b8ae2829db30d0310e0', portraitURL: '/file/db/thang.type/54c83b8ae2829db30d0310e0/portrait.png', kind: 'Unit'}
     {slug: 'soldier-f', name: 'Soldier F', original: '52d49552d0ce9936e2000007', portraitURL: '/file/db/thang.type/52d49552d0ce9936e2000007/portrait.png', kind: 'Unit'}
     {slug: 'soldier-m', name: 'Soldier M', original: '529e680ac423d4e83b000001', portraitURL: '/file/db/thang.type/529e680ac423d4e83b000001/portrait.png', kind: 'Unit'}
     {slug: 'sorcerer', name: 'Sorcerer', original: '52fd1524c7e6cf99160e7bc9', portraitURL: '/file/db/thang.type/52fd1524c7e6cf99160e7bc9/portrait.png', kind: 'Hero'}
     {slug: 'target', name: 'Target', original: '52b32ad97385ec3d03000001', portraitURL: '/file/db/thang.type/52b32ad97385ec3d03000001/portrait.png', kind: 'Mark'}
     {slug: 'thoktar', name: 'Thoktar', original: '52a00542cf1818f2be000006', portraitURL: '/file/db/thang.type/52a00542cf1818f2be000006/portrait.png', kind: 'Unit'}
     {slug: 'tinker', name: 'Tinker', original: '56cdd89be906e72400f13451', portraitURL: '/file/db/thang.type/56cdd89be906e72400f13451/portrait.png', kind: 'Unit'}
     {slug: 'trapper', name: 'Trapper', original: '5466d449417c8b48a9811e83', portraitURL: '/file/db/thang.type/5466d449417c8b48a9811e83/portrait.png', kind: 'Hero'}
     {slug: 'wizard', name: 'Wizard', original: '52a00d55cf1818f2be00000b', portraitURL: '/file/db/thang.type/52a00d55cf1818f2be00000b/portrait.png', kind: 'Unit'}
     {slug: 'wyrm', name: 'Wyrm', original: '56ba2b34e942de2600c792ed', portraitURL: '/file/db/thang.type/56ba2b34e942de2600c792ed/portrait.png', kind: 'Unit'}
  ]

  # Ones we didn't decide to use
  otherImages: [
    {slug: 'hero-placeholder', name: 'Hero Placeholder', original: '53ed1d9c2b65b0e32b9c96a9', portraitURL: '/file/db/thang.type/53ed1d9c2b65b0e32b9c96a9/portrait.png', kind: 'Unit'}
    {slug: 'flag', name: 'Flag', original: '53fa25f25bc220000052c2be', portraitURL: '/file/db/thang.type/53fa25f25bc220000052c2be/portrait.png', kind: 'Misc'}
    {slug: 'ace-of-coders-background', name: 'Ace of Coders Background', original: '55ef24a10e11a95a0d0ab103', portraitURL: '/file/db/thang.type/55ef24a10e11a95a0d0ab103/portrait.png', kind: 'Floor'}
    {slug: 'advanced-flags', name: 'Advanced Flags', original: '5478b97e8707a2c3a2493b2f', portraitURL: '/file/db/thang.type/5478b97e8707a2c3a2493b2f/portrait.png', kind: 'Item'}
    {slug: 'aerial-spear', name: 'Aerial Spear', original: '5400da521130f1881ca255e4', portraitURL: '/file/db/thang.type/5400da521130f1881ca255e4/portrait.png', kind: 'Misc'}
    {slug: 'altar', name: 'Altar', original: '54ef8eb683b08b7d054b7f04', portraitURL: '/file/db/thang.type/54ef8eb683b08b7d054b7f04/portrait.png', kind: 'Doodad'}
    {slug: 'amber-sense-stone', name: 'Amber Sense Stone', original: '54693413a2b1f53ce79443dd', portraitURL: '/file/db/thang.type/54693413a2b1f53ce79443dd/portrait.png', kind: 'Item'}
    {slug: 'angel-fountain', name: 'Angel Fountain', original: '54f11438021968810565376b', portraitURL: '/file/db/thang.type/54f11438021968810565376b/portrait.png', kind: 'Doodad'}
    {slug: 'angel-statue', name: 'Angel Statue', original: '54f1152a021968810565378a', portraitURL: '/file/db/thang.type/54f1152a021968810565378a/portrait.png', kind: 'Doodad'}
    {slug: 'archway', name: 'Archway', original: '534dd3531a52ddd804f34efc', portraitURL: '/file/db/thang.type/534dd3531a52ddd804f34efc/portrait.png', kind: 'Misc'}
    {slug: 'arrow', name: 'Arrow', original: '529ce66b0bf0bccdc6000005', portraitURL: '/file/db/thang.type/529ce66b0bf0bccdc6000005/portrait.png', kind: 'Missile'}
    {slug: 'arrow-tower', name: 'Arrow Tower', original: '529f93cfdacd32512700000a', portraitURL: '/file/db/thang.type/529f93cfdacd32512700000a/portrait.png', kind: 'Unit'}
    {slug: 'artillery', name: 'Artillery', original: '529e7a16c423d4e83b000003', portraitURL: '/file/db/thang.type/529e7a16c423d4e83b000003/portrait.png', kind: 'Unit'}
    {slug: 'baby-griffin-pet', name: 'Baby Griffin Pet', original: '5750ef2f9f734c20005f1f57', portraitURL: '/file/db/thang.type/5750ef2f9f734c20005f1f57/portrait.png', kind: 'Unit'}
    {slug: 'ball', name: 'Ball', original: '5580af39b43ce0b15a91b299', portraitURL: '/file/db/thang.type/5580af39b43ce0b15a91b299/portrait.png', kind: 'Doodad'}
    {slug: 'balsa-staff', name: 'Balsa Staff', original: '544d88478494308424f56505', portraitURL: '/file/db/thang.type/544d88478494308424f56505/portrait.png', kind: 'Item'}
    {slug: 'banded-redwood-wand', name: 'Banded Redwood Wand', original: '544d887c8494308424f56509', portraitURL: '/file/db/thang.type/544d887c8494308424f56509/portrait.png', kind: 'Item'}
    {slug: 'barn', name: 'Barn', original: '54f1136f25be5e88058374b3', portraitURL: '/file/db/thang.type/54f1136f25be5e88058374b3/portrait.png', kind: 'Doodad'}
    {slug: 'barrel', name: 'Barrel', original: '52aa5ff120fccb0000000003', portraitURL: '/file/db/thang.type/52aa5ff120fccb0000000003/portrait.png', kind: 'Doodad'}
    {slug: 'barrel-animated', name: 'Barrel Animated', original: '54d2b28e7e1b915605556c37', portraitURL: '/file/db/thang.type/54d2b28e7e1b915605556c37/portrait.png', kind: 'Doodad'}
    {slug: 'barrel-animated-2', name: 'Barrel Animated 2', original: '54d2b4fdae912a520569cff1', portraitURL: '/file/db/thang.type/54d2b4fdae912a520569cff1/portrait.png', kind: 'Doodad'}
    {slug: 'bat', name: 'Bat', original: '55c13175c87e47c60604f987', portraitURL: '/file/db/thang.type/55c13175c87e47c60604f987/portrait.png', kind: 'Doodad'}
    {slug: 'beam', name: 'Beam', original: '529ec2cec423d4e83b000011', portraitURL: '/file/db/thang.type/529ec2cec423d4e83b000011/portrait.png', kind: 'Missile'}
    {slug: 'beam-tower', name: 'Beam Tower', original: '529ec0c1c423d4e83b00000d', portraitURL: '/file/db/thang.type/529ec0c1c423d4e83b00000d/portrait.png', kind: 'Unit'}
    {slug: 'bear', name: 'Bear', original: '54e95b22f54ef5794f354f41', portraitURL: '/file/db/thang.type/54e95b22f54ef5794f354f41/portrait.png', kind: 'Doodad'}
    {slug: 'bear-trap', name: 'Bear Trap', original: '54d2b8ef3e16915505f0bfeb', portraitURL: '/file/db/thang.type/54d2b8ef3e16915505f0bfeb/portrait.png', kind: 'Doodad'}
    {slug: 'big-rocks-1', name: 'Big Rocks 1', original: '557f950db43ce0b15a91b1d9', portraitURL: '/file/db/thang.type/557f950db43ce0b15a91b1d9/portrait.png', kind: 'Doodad'}
    {slug: 'big-rocks-2', name: 'Big Rocks 2', original: '557f959ab43ce0b15a91b1dd', portraitURL: '/file/db/thang.type/557f959ab43ce0b15a91b1dd/portrait.png', kind: 'Doodad'}
    {slug: 'big-rocks-3', name: 'Big Rocks 3', original: '557f95e7b43ce0b15a91b1e1', portraitURL: '/file/db/thang.type/557f95e7b43ce0b15a91b1e1/portrait.png', kind: 'Doodad'}
    {slug: 'big-rocks-4', name: 'Big Rocks 4', original: '557f9627b43ce0b15a91b1e5', portraitURL: '/file/db/thang.type/557f9627b43ce0b15a91b1e5/portrait.png', kind: 'Doodad'}
    {slug: 'big-rocks-5', name: 'Big Rocks 5', original: '557f9661b43ce0b15a91b1e9', portraitURL: '/file/db/thang.type/557f9661b43ce0b15a91b1e9/portrait.png', kind: 'Doodad'}
    {slug: 'bird', name: 'Bird', original: '53e2e31f6f406a3505b3eab0', portraitURL: '/file/db/thang.type/53e2e31f6f406a3505b3eab0/portrait.png', kind: 'Doodad'}
    {slug: 'bloodhenge', name: 'Bloodhenge', original: '54f1168802196881056537df', portraitURL: '/file/db/thang.type/54f1168802196881056537df/portrait.png', kind: 'Doodad'}
    {slug: 'blue-cart', name: 'Blue Cart', original: '5435d3207b554def1f99c49c', portraitURL: '/file/db/thang.type/5435d3207b554def1f99c49c/portrait.png', kind: 'Doodad'}
    {slug: 'bluff-1', name: 'Bluff 1', original: '52afce51c5b1813ec200001a', portraitURL: '/file/db/thang.type/52afce51c5b1813ec200001a/portrait.png', kind: 'Doodad'}
    {slug: 'bluff-2', name: 'Bluff 2', original: '52afcecbc5b1813ec200001c', portraitURL: '/file/db/thang.type/52afcecbc5b1813ec200001c/portrait.png', kind: 'Doodad'}
    {slug: 'bolt', name: 'Bolt', original: '55c658a8a03e2014d693990a', portraitURL: '/file/db/thang.type/55c658a8a03e2014d693990a/portrait.png', kind: 'Missile'}
    {slug: 'bolt-spitter', name: 'Bolt Spitter', original: '544d85d88494308424f564e4', portraitURL: '/file/db/thang.type/544d85d88494308424f564e4/portrait.png', kind: 'Item'}
    {slug: 'boltsaw', name: 'Boltsaw', original: '544d6f5e8494308424f56476', portraitURL: '/file/db/thang.type/544d6f5e8494308424f56476/portrait.png', kind: 'Item'}
    {slug: 'bone-dagger', name: 'Bone Dagger', original: '54eb4b2249fa2d5c905ddefe', portraitURL: '/file/db/thang.type/54eb4b2249fa2d5c905ddefe/portrait.png', kind: 'Item'}
    {slug: 'book-of-life-i', name: 'Book of Life I', original: '546375653839c6e02811d30b', portraitURL: '/file/db/thang.type/546375653839c6e02811d30b/portrait.png', kind: 'Item'}
    {slug: 'book-of-life-ii', name: 'Book of Life II', original: '546375813839c6e02811d30e', portraitURL: '/file/db/thang.type/546375813839c6e02811d30e/portrait.png', kind: 'Item'}
    {slug: 'book-of-life-iii', name: 'Book of Life III', original: '546375a43839c6e02811d311', portraitURL: '/file/db/thang.type/546375a43839c6e02811d311/portrait.png', kind: 'Item'}
    {slug: 'book-of-life-iv', name: 'Book of Life IV', original: '546376ca3839c6e02811d31d', portraitURL: '/file/db/thang.type/546376ca3839c6e02811d31d/portrait.png', kind: 'Item'}
    {slug: 'book-of-life-v', name: 'Book of Life V', original: '546376ea3839c6e02811d320', portraitURL: '/file/db/thang.type/546376ea3839c6e02811d320/portrait.png', kind: 'Item'}
    {slug: 'bookshelf', name: 'Bookshelf', original: '52e994ea427172ae56001fc9', portraitURL: '/file/db/thang.type/52e994ea427172ae56001fc9/portrait.png', kind: 'Doodad'}
    {slug: 'bookshelf-2', name: 'Bookshelf 2', original: '54ef925a64112781056c18b5', portraitURL: '/file/db/thang.type/54ef925a64112781056c18b5/portrait.png', kind: 'Doodad'}
    {slug: 'boom-ball-missile', name: 'Boom Ball Missile', original: '5535b5d4428ddac5686fcf82', portraitURL: '/file/db/thang.type/5535b5d4428ddac5686fcf82/portrait.png', kind: 'Missile'}
    {slug: 'boomrod', name: 'Boomrod', original: '544d85898494308424f564df', portraitURL: '/file/db/thang.type/544d85898494308424f564df/portrait.png', kind: 'Item'}
    {slug: 'boots-of-jumping', name: 'Boots of Jumping', original: '546d4e289df4a17d0d449ad5', portraitURL: '/file/db/thang.type/546d4e289df4a17d0d449ad5/portrait.png', kind: 'Item'}
    {slug: 'boots-of-leaping', name: 'Boots of Leaping', original: '53e214f153457600003e3eab', portraitURL: '/file/db/thang.type/53e214f153457600003e3eab/portrait.png', kind: 'Item'}
    {slug: 'boss-star-i', name: 'Boss Star I', original: '54eb58e449fa2d5c905ddf46', portraitURL: '/file/db/thang.type/54eb58e449fa2d5c905ddf46/portrait.png', kind: 'Item'}
    {slug: 'boss-star-ii', name: 'Boss Star II', original: '54eb5bf649fa2d5c905ddf4a', portraitURL: '/file/db/thang.type/54eb5bf649fa2d5c905ddf4a/portrait.png', kind: 'Item'}
    {slug: 'boss-star-iii', name: 'Boss Star III', original: '54eb5c8f49fa2d5c905ddf4e', portraitURL: '/file/db/thang.type/54eb5c8f49fa2d5c905ddf4e/portrait.png', kind: 'Item'}
    {slug: 'boss-star-iv', name: 'Boss Star IV', original: '54eb5d1649fa2d5c905ddf52', portraitURL: '/file/db/thang.type/54eb5d1649fa2d5c905ddf52/portrait.png', kind: 'Item'}
    {slug: 'boss-star-v', name: 'Boss Star V', original: '54eb5dbc49fa2d5c905ddf56', portraitURL: '/file/db/thang.type/54eb5dbc49fa2d5c905ddf56/portrait.png', kind: 'Item'}
    {slug: 'boulder', name: 'Boulder', original: '544d86828494308424f564ec', portraitURL: '/file/db/thang.type/544d86828494308424f564ec/portrait.png', kind: 'Missile'}
    {slug: 'boulder-trap', name: 'Boulder Trap', original: '55c246b1dfc8d0b576e60a23', portraitURL: '/file/db/thang.type/55c246b1dfc8d0b576e60a23/portrait.png', kind: 'Doodad'}
    {slug: 'box', name: 'Box', original: '54d2b68a3e16915505f0bc8a', portraitURL: '/file/db/thang.type/54d2b68a3e16915505f0bc8a/portrait.png', kind: 'Doodad'}
    {slug: 'box-2', name: 'Box 2', original: '54d2b797051a3a5305424c62', portraitURL: '/file/db/thang.type/54d2b797051a3a5305424c62/portrait.png', kind: 'Doodad'}
    {slug: 'brawlwood', name: 'Brawlwood', original: '533b1f1642aef2202fdcc487', portraitURL: '/file/db/thang.type/533b1f1642aef2202fdcc487/portrait.png', kind: 'Floor'}
    {slug: 'breakout-background', name: 'Breakout Background', original: '56c65f8b79735337006047df', portraitURL: '/file/db/thang.type/56c65f8b79735337006047df/portrait.png', kind: 'Floor'}
    {slug: 'broken-tower', name: 'Broken Tower', original: '5376b2caff7b2d3805a396a9', portraitURL: '/file/db/thang.type/5376b2caff7b2d3805a396a9/portrait.png', kind: 'Doodad'}
    {slug: 'bronze-coin', name: 'Bronze Coin', original: '535ef2d54f10444d08486ba8', portraitURL: '/file/db/thang.type/535ef2d54f10444d08486ba8/portrait.png', kind: 'Misc'}
    {slug: 'bronze-shield', name: 'Bronze Shield', original: '544c310ae0017993fce214bf', portraitURL: '/file/db/thang.type/544c310ae0017993fce214bf/portrait.png', kind: 'Item'}
    {slug: 'bullet', name: 'Bullet', original: '544d82bd8494308424f564d0', portraitURL: '/file/db/thang.type/544d82bd8494308424f564d0/portrait.png', kind: 'Missile'}
    {slug: 'cabin-1', name: 'Cabin 1', original: '54e93b41970f0b0a263c0400', portraitURL: '/file/db/thang.type/54e93b41970f0b0a263c0400/portrait.png', kind: 'Doodad'}
    {slug: 'cabin-2', name: 'Cabin 2', original: '54e93cb4970f0b0a263c0406', portraitURL: '/file/db/thang.type/54e93cb4970f0b0a263c0406/portrait.png', kind: 'Doodad'}
    {slug: 'cabin-3', name: 'Cabin 3', original: '54e93d1cf54ef5794f354e7d', portraitURL: '/file/db/thang.type/54e93d1cf54ef5794f354e7d/portrait.png', kind: 'Doodad'}
    {slug: 'cabin-4', name: 'Cabin 4', original: '54e93db7f54ef5794f354e83', portraitURL: '/file/db/thang.type/54e93db7f54ef5794f354e83/portrait.png', kind: 'Doodad'}
    {slug: 'cabinet', name: 'Cabinet', original: '54ef9101c1f3bd7c0593f232', portraitURL: '/file/db/thang.type/54ef9101c1f3bd7c0593f232/portrait.png', kind: 'Doodad'}
    {slug: 'cactus-1', name: 'Cactus 1', original: '546e24949df4a17d0d449bc5', portraitURL: '/file/db/thang.type/546e24949df4a17d0d449bc5/portrait.png', kind: 'Doodad'}
    {slug: 'cactus-2', name: 'Cactus 2', original: '546e24039df4a17d0d449bb9', portraitURL: '/file/db/thang.type/546e24039df4a17d0d449bb9/portrait.png', kind: 'Doodad'}
    {slug: 'caltrop-belt', name: 'Caltrop Belt', original: '54694af7a2b1f53ce7944441', portraitURL: '/file/db/thang.type/54694af7a2b1f53ce7944441/portrait.png', kind: 'Item'}
    {slug: 'caltrops', name: 'Caltrops', original: '557f9700b43ce0b15a91b1ed', portraitURL: '/file/db/thang.type/557f9700b43ce0b15a91b1ed/portrait.png', kind: 'Doodad'}
    {slug: 'camel', name: 'Camel', original: '548cf4cd0f559d0000be7e57', portraitURL: '/file/db/thang.type/548cf4cd0f559d0000be7e57/portrait.png', kind: 'Doodad'}
    {slug: 'camp-fire', name: 'Camp Fire', original: '52e097c110012a5b250000b2', portraitURL: '/file/db/thang.type/52e097c110012a5b250000b2/portrait.png', kind: 'Doodad'}
    {slug: 'campfire-stone', name: 'Campfire Stone', original: '54f118e125be5e880583759a', portraitURL: '/file/db/thang.type/54f118e125be5e880583759a/portrait.png', kind: 'Doodad'}
    {slug: 'candle', name: 'Candle', original: '52e95fb222efc8e7090017d7', portraitURL: '/file/db/thang.type/52e95fb222efc8e7090017d7/portrait.png', kind: 'Doodad'}
    {slug: 'carved-steel-ring', name: 'Carved Steel Ring', original: '54692dfaa2b1f53ce794439f', portraitURL: '/file/db/thang.type/54692dfaa2b1f53ce794439f/portrait.png', kind: 'Item'}
    {slug: 'catapult', name: 'Catapult', original: '553e7ba29bdea5d00f1fd905', portraitURL: '/file/db/thang.type/553e7ba29bdea5d00f1fd905/portrait.png', kind: 'Unit'}
    {slug: 'cave', name: 'Cave', original: '52e95983427172ae560018ce', portraitURL: '/file/db/thang.type/52e95983427172ae560018ce/portrait.png', kind: 'Doodad'}
    {slug: 'chainmail-tunic', name: 'Chainmail Tunic', original: '5441c4dd4e9aeb727cc9713b', portraitURL: '/file/db/thang.type/5441c4dd4e9aeb727cc9713b/portrait.png', kind: 'Item'}
    {slug: 'chains', name: 'Chains', original: '52aa602020fccb0000000004', portraitURL: '/file/db/thang.type/52aa602020fccb0000000004/portrait.png', kind: 'Doodad'}
    {slug: 'chair', name: 'Chair', original: '52e9960e427172ae56001fdf', portraitURL: '/file/db/thang.type/52e9960e427172ae56001fdf/portrait.png', kind: 'Doodad'}
    {slug: 'charge-belt', name: 'Charge Belt', original: '54694b27a2b1f53ce7944445', portraitURL: '/file/db/thang.type/54694b27a2b1f53ce7944445/portrait.png', kind: 'Item'}
    {slug: 'choppable-tree-1', name: 'Choppable Tree 1', original: '52fbd1d67e01835453bd8a26', portraitURL: '/file/db/thang.type/52fbd1d67e01835453bd8a26/portrait.png', kind: 'Doodad'}
    {slug: 'choppable-tree-2', name: 'Choppable Tree 2', original: '52fbd7e07e01835453bd8afc', portraitURL: '/file/db/thang.type/52fbd7e07e01835453bd8afc/portrait.png', kind: 'Doodad'}
    {slug: 'choppable-tree-3', name: 'Choppable Tree 3', original: '52fbd9beab6e45c813bc79c6', portraitURL: '/file/db/thang.type/52fbd9beab6e45c813bc79c6/portrait.png', kind: 'Doodad'}
    {slug: 'choppable-tree-4', name: 'Choppable Tree 4', original: '52fbdb747e01835453bd8b4a', portraitURL: '/file/db/thang.type/52fbdb747e01835453bd8b4a/portrait.png', kind: 'Doodad'}
    {slug: 'circle-tree-stand-1', name: 'Circle Tree Stand 1', original: '541cb842c6362edfb0f3447d', portraitURL: '/file/db/thang.type/541cb842c6362edfb0f3447d/portrait.png', kind: 'Doodad'}
    {slug: 'circle-tree-stand-2', name: 'Circle Tree Stand 2', original: '541cc5708e78524aad94de69', portraitURL: '/file/db/thang.type/541cc5708e78524aad94de69/portrait.png', kind: 'Doodad'}
    {slug: 'circle-tree-stand-3', name: 'Circle Tree Stand 3', original: '541cc6898e78524aad94de6f', portraitURL: '/file/db/thang.type/541cc6898e78524aad94de6f/portrait.png', kind: 'Doodad'}
    {slug: 'circlet-of-the-magi', name: 'Circlet of the Magi', original: '54ea39342b7506e891ca70f2', portraitURL: '/file/db/thang.type/54ea39342b7506e891ca70f2/portrait.png', kind: 'Item'}
    {slug: 'classroom-bench', name: 'classroom bench', original: '56eb09520c6e9f1f00990e81', portraitURL: '/file/db/thang.type/56eb09520c6e9f1f00990e81/portrait.png', kind: 'Doodad'}
    {slug: 'classroom-floor', name: 'Classroom Floor', original: '56a139f9d987c52900d4de5a', portraitURL: '/file/db/thang.type/56a139f9d987c52900d4de5a/portrait.png', kind: 'Floor'}
    {slug: 'classroom-sculpture', name: 'Classroom Sculpture', original: '56a16510088f002400720564', portraitURL: '/file/db/thang.type/56a16510088f002400720564/portrait.png', kind: 'Doodad'}
    {slug: 'classroom-students-desk', name: 'Classroom Students Desk', original: '56a15d88d987c52900d4ecdb', portraitURL: '/file/db/thang.type/56a15d88d987c52900d4ecdb/portrait.png', kind: 'Doodad'}
    {slug: 'classroom-students-seat', name: 'Classroom Students Seat', original: '56a162348431922e0042fae3', portraitURL: '/file/db/thang.type/56a162348431922e0042fae3/portrait.png', kind: 'Doodad'}
    {slug: 'classroom-viewscreen', name: 'Classroom Viewscreen', original: '569fdf3c6ff9591f000050bf', portraitURL: '/file/db/thang.type/569fdf3c6ff9591f000050bf/portrait.png', kind: 'Doodad'}
    {slug: 'classroom-wall', name: 'Classroom Wall', original: '56a0150cf363ed1f0029e11c', portraitURL: '/file/db/thang.type/56a0150cf363ed1f0029e11c/portrait.png', kind: 'Wall'}
    {slug: 'claymore', name: 'Claymore', original: '544d6d4a8494308424f56471', portraitURL: '/file/db/thang.type/544d6d4a8494308424f56471/portrait.png', kind: 'Item'}
    {slug: 'cloud-1', name: 'Cloud 1', original: '550b42b7343675176d05a919', portraitURL: '/file/db/thang.type/550b42b7343675176d05a919/portrait.png', kind: 'Doodad'}
    {slug: 'cloud-2', name: 'Cloud 2', original: '550b43fc343675176d05a923', portraitURL: '/file/db/thang.type/550b43fc343675176d05a923/portrait.png', kind: 'Doodad'}
    {slug: 'cloud-3', name: 'Cloud 3', original: '550b4506343675176d05a933', portraitURL: '/file/db/thang.type/550b4506343675176d05a933/portrait.png', kind: 'Doodad'}
    {slug: 'coin', name: 'Coin', original: '52aa3a8fccbd588d4d000001', portraitURL: '/file/db/thang.type/52aa3a8fccbd588d4d000001/portrait.png', kind: 'Misc'}
    {slug: 'compound-boots', name: 'Compound Boots', original: '546d4d8e9df4a17d0d449acd', portraitURL: '/file/db/thang.type/546d4d8e9df4a17d0d449acd/portrait.png', kind: 'Item'}
    {slug: 'cougar-pet', name: 'Cougar Pet', original: '540f3a33821af8000097dc62', portraitURL: '/file/db/thang.type/540f3a33821af8000097dc62/portrait.png', kind: 'Unit'}
    {slug: 'crevasse-1', name: 'Crevasse 1', original: '5576080a1e82182d9e6888cd', portraitURL: '/file/db/thang.type/5576080a1e82182d9e6888cd/portrait.png', kind: 'Doodad'}
    {slug: 'crevasse-2', name: 'Crevasse 2', original: '557630c31e82182d9e688921', portraitURL: '/file/db/thang.type/557630c31e82182d9e688921/portrait.png', kind: 'Doodad'}
    {slug: 'crevasse-3', name: 'Crevasse 3', original: '557631321e82182d9e688925', portraitURL: '/file/db/thang.type/557631321e82182d9e688925/portrait.png', kind: 'Doodad'}
    {slug: 'crisscross-back', name: 'Crisscross Back', original: '53b495e37e17883a05754216', portraitURL: '/file/db/thang.type/53b495e37e17883a05754216/portrait.png', kind: 'Floor'}
    {slug: 'crisscross-front', name: 'Crisscross Front', original: '53b495b02082f23505b844e5', portraitURL: '/file/db/thang.type/53b495b02082f23505b844e5/portrait.png', kind: 'Floor'}
    {slug: 'cross-bones-background', name: 'Cross Bones Background', original: '572e51175366918e018060e5', portraitURL: '/file/db/thang.type/572e51175366918e018060e5/portrait.png', kind: 'Floor'}
    {slug: 'crossbeam-support', name: 'crossbeam support', original: '5786828a0d397a2e0026f274', portraitURL: '/file/db/thang.type/5786828a0d397a2e0026f274/portrait.png', kind: 'Doodad'}
    {slug: 'crossbow', name: 'Crossbow', original: '53e21ae653457600003e3ec2', portraitURL: '/file/db/thang.type/53e21ae653457600003e3ec2/portrait.png', kind: 'Item'}
    {slug: 'crude-builders-hammer', name: 'Crude Builder\'s Hammer', original: '53f4e6e3d822c23505b74f42', portraitURL: '/file/db/thang.type/53f4e6e3d822c23505b74f42/portrait.png', kind: 'Item'}
    {slug: 'crude-crossbow', name: 'Crude Crossbow', original: '544d7ffd8494308424f564c3', portraitURL: '/file/db/thang.type/544d7ffd8494308424f564c3/portrait.png', kind: 'Item'}
    {slug: 'crude-dagger', name: 'Crude Dagger', original: '544d952b8494308424f56517', portraitURL: '/file/db/thang.type/544d952b8494308424f56517/portrait.png', kind: 'Item'}
    {slug: 'crude-dagger-missile', name: 'Crude Dagger Missile', original: '546e292d9df4a17d0d449c0c', portraitURL: '/file/db/thang.type/546e292d9df4a17d0d449c0c/portrait.png', kind: 'Missile'}
    {slug: 'crude-glasses', name: 'Crude Glasses', original: '53e238df53457600003e3f0b', portraitURL: '/file/db/thang.type/53e238df53457600003e3f0b/portrait.png', kind: 'Item'}
    {slug: 'crude-spike', name: 'Crude Spike', original: '544d79e28494308424f56482', portraitURL: '/file/db/thang.type/544d79e28494308424f56482/portrait.png', kind: 'Item'}
    {slug: 'crude-telephoto-glasses', name: 'Crude Telephoto Glasses', original: '5469415aa2b1f53ce7944411', portraitURL: '/file/db/thang.type/5469415aa2b1f53ce7944411/portrait.png', kind: 'Item'}
    {slug: 'crypt-key', name: 'Crypt Key', original: '54eb573549fa2d5c905ddf36', portraitURL: '/file/db/thang.type/54eb573549fa2d5c905ddf36/portrait.png', kind: 'Item'}
    {slug: 'crystal-wand', name: 'Crystal Wand', original: '54eab63b2b7506e891ca71f2', portraitURL: '/file/db/thang.type/54eab63b2b7506e891ca71f2/portrait.png', kind: 'Item'}
    {slug: 'cupboards-of-kgard-background', name: 'Cupboards of Kgard background', original: '56994ec3d32e4c1f0075460d', portraitURL: '/file/db/thang.type/56994ec3d32e4c1f0075460d/portrait.png', kind: 'Floor'}
    {slug: 'curse', name: 'Curse', original: '53024d18a6efdd32359c5365', portraitURL: '/file/db/thang.type/53024d18a6efdd32359c5365/portrait.png', kind: 'Mark'}
    {slug: 'cut-garnet-sense-stone', name: 'Cut Garnet Sense Stone', original: '546933a5a2b1f53ce79443d5', portraitURL: '/file/db/thang.type/546933a5a2b1f53ce79443d5/portrait.png', kind: 'Item'}
    {slug: 'cut-stone-builders-hammer', name: 'Cut Stone Builder\'s Hammer', original: '54694c0ba2b1f53ce7944456', portraitURL: '/file/db/thang.type/54694c0ba2b1f53ce7944456/portrait.png', kind: 'Item'}
    {slug: 'darksteel-blade', name: 'Darksteel Blade', original: '544d7f558494308424f564bb', portraitURL: '/file/db/thang.type/544d7f558494308424f564bb/portrait.png', kind: 'Item'}
    {slug: 'deadeye-crossbow', name: 'Deadeye Crossbow', original: '54eaad752b7506e891ca71d1', portraitURL: '/file/db/thang.type/54eaad752b7506e891ca71d1/portrait.png', kind: 'Item'}
    {slug: 'decoy', name: 'Decoy', original: '5498bb758e52573b10d3bce6', portraitURL: '/file/db/thang.type/5498bb758e52573b10d3bce6/portrait.png', kind: 'Unit'}
    {slug: 'defensive-boots', name: 'Defensive Boots', original: '546d4e019df4a17d0d449ad1', portraitURL: '/file/db/thang.type/546d4e019df4a17d0d449ad1/portrait.png', kind: 'Item'}
    {slug: 'defensive-infantry-shield', name: 'Defensive Infantry Shield', original: '544d7b408494308424f5648f', portraitURL: '/file/db/thang.type/544d7b408494308424f5648f/portrait.png', kind: 'Item'}
    {slug: 'deflector', name: 'Deflector', original: '54eabff349fa2d5c905ddeee', portraitURL: '/file/db/thang.type/54eabff349fa2d5c905ddeee/portrait.png', kind: 'Item'}
    {slug: 'derrick', name: 'Derrick', original: '546e24339df4a17d0d449bbd', portraitURL: '/file/db/thang.type/546e24339df4a17d0d449bbd/portrait.png', kind: 'Doodad'}
    {slug: 'desert-bones-1', name: 'Desert Bones 1', original: '548cf0cc0f559d0000be7e27', portraitURL: '/file/db/thang.type/548cf0cc0f559d0000be7e27/portrait.png', kind: 'Doodad'}
    {slug: 'desert-bones-3', name: 'Desert Bones 3', original: '548cf1630f559d0000be7e2f', portraitURL: '/file/db/thang.type/548cf1630f559d0000be7e2f/portrait.png', kind: 'Doodad'}
    {slug: 'desert-green-1', name: 'Desert Green 1', original: '548cef670f559d0000be7e17', portraitURL: '/file/db/thang.type/548cef670f559d0000be7e17/portrait.png', kind: 'Doodad'}
    {slug: 'desert-green-2', name: 'Desert Green 2', original: '548cefc50f559d0000be7e1b', portraitURL: '/file/db/thang.type/548cefc50f559d0000be7e1b/portrait.png', kind: 'Doodad'}
    {slug: 'desert-house-1', name: 'Desert House 1', original: '548cf35a0f559d0000be7e43', portraitURL: '/file/db/thang.type/548cf35a0f559d0000be7e43/portrait.png', kind: 'Doodad'}
    {slug: 'desert-house-2', name: 'Desert House 2', original: '548cf3ae0f559d0000be7e47', portraitURL: '/file/db/thang.type/548cf3ae0f559d0000be7e47/portrait.png', kind: 'Doodad'}
    {slug: 'desert-house-3', name: 'Desert House 3', original: '548cf4000f559d0000be7e4b', portraitURL: '/file/db/thang.type/548cf4000f559d0000be7e4b/portrait.png', kind: 'Doodad'}
    {slug: 'desert-house-4', name: 'Desert House 4', original: '548cf44c0f559d0000be7e4f', portraitURL: '/file/db/thang.type/548cf44c0f559d0000be7e4f/portrait.png', kind: 'Doodad'}
    {slug: 'desert-palm-1', name: 'Desert Palm 1', original: '548cf0110f559d0000be7e1f', portraitURL: '/file/db/thang.type/548cf0110f559d0000be7e1f/portrait.png', kind: 'Doodad'}
    {slug: 'desert-palm-2', name: 'Desert Palm 2', original: '548cf06f0f559d0000be7e23', portraitURL: '/file/db/thang.type/548cf06f0f559d0000be7e23/portrait.png', kind: 'Doodad'}
    {slug: 'desert-pillar', name: 'Desert Pillar', original: '541c5ff487338f570851ad83', portraitURL: '/file/db/thang.type/541c5ff487338f570851ad83/portrait.png', kind: 'Doodad'}
    {slug: 'desert-pyramid', name: 'Desert Pyramid', original: '53e239c253457600003e3f11', portraitURL: '/file/db/thang.type/53e239c253457600003e3f11/portrait.png', kind: 'Doodad'}
    {slug: 'desert-rubble-1', name: 'Desert Rubble 1', original: '53126c48f5a594b00fbfcc42', portraitURL: '/file/db/thang.type/53126c48f5a594b00fbfcc42/portrait.png', kind: 'Doodad'}
    {slug: 'desert-rubble-2', name: 'Desert Rubble 2', original: '52f01b0b5071878f7650e11a', portraitURL: '/file/db/thang.type/52f01b0b5071878f7650e11a/portrait.png', kind: 'Doodad'}
    {slug: 'desert-rubble-3', name: 'Desert Rubble 3', original: '546e23a89df4a17d0d449bb1', portraitURL: '/file/db/thang.type/546e23a89df4a17d0d449bb1/portrait.png', kind: 'Doodad'}
    {slug: 'desert-sand-rock', name: 'Desert Sand Rock', original: '55c64774ef141c65665beb84', portraitURL: '/file/db/thang.type/55c64774ef141c65665beb84/portrait.png', kind: 'Doodad'}
    {slug: 'desert-shrub-big-1', name: 'Desert Shrub Big 1', original: '546e237d9df4a17d0d449bad', portraitURL: '/file/db/thang.type/546e237d9df4a17d0d449bad/portrait.png', kind: 'Doodad'}
    {slug: 'desert-shrub-big-2', name: 'Desert Shrub Big 2', original: '546e22c59df4a17d0d449ba1', portraitURL: '/file/db/thang.type/546e22c59df4a17d0d449ba1/portrait.png', kind: 'Doodad'}
    {slug: 'desert-shrub-big-3', name: 'Desert Shrub Big 3', original: '53f4c776d822c23505b7091c', portraitURL: '/file/db/thang.type/53f4c776d822c23505b7091c/portrait.png', kind: 'Doodad'}
    {slug: 'desert-shrub-small-1', name: 'Desert Shrub Small 1', original: '548ceec80f559d0000be7e0f', portraitURL: '/file/db/thang.type/548ceec80f559d0000be7e0f/portrait.png', kind: 'Doodad'}
    {slug: 'desert-shrub-small-2', name: 'Desert Shrub Small 2', original: '548cef1f0f559d0000be7e13', portraitURL: '/file/db/thang.type/548cef1f0f559d0000be7e13/portrait.png', kind: 'Doodad'}
    {slug: 'desert-skullcave', name: 'Desert Skullcave', original: '546e231c9df4a17d0d449ba5', portraitURL: '/file/db/thang.type/546e231c9df4a17d0d449ba5/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-1', name: 'Desert Wall 1', original: '5404fe5f1d10b2f170618ae9', portraitURL: '/file/db/thang.type/5404fe5f1d10b2f170618ae9/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-2', name: 'Desert Wall 2', original: '540100ba794c1a8b4d328437', portraitURL: '/file/db/thang.type/540100ba794c1a8b4d328437/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-3', name: 'Desert Wall 3', original: '53f4e7fff7bc7336054dcf64', portraitURL: '/file/db/thang.type/53f4e7fff7bc7336054dcf64/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-4', name: 'Desert Wall 4', original: '53f3ef04e7a7643005c0f4a1', portraitURL: '/file/db/thang.type/53f3ef04e7a7643005c0f4a1/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-5', name: 'Desert Wall 5', original: '53ebafdd1a100989a40ce479', portraitURL: '/file/db/thang.type/53ebafdd1a100989a40ce479/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-6', name: 'Desert Wall 6', original: '53eb989b1a100989a40ce46a', portraitURL: '/file/db/thang.type/53eb989b1a100989a40ce46a/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-7', name: 'Desert Wall 7', original: '53eaa7de786ccc3405a9f2a4', portraitURL: '/file/db/thang.type/53eaa7de786ccc3405a9f2a4/portrait.png', kind: 'Doodad'}
    {slug: 'desert-wall-8', name: 'Desert Wall 8', original: '53eaa6f6ef27b33605514a64', portraitURL: '/file/db/thang.type/53eaa6f6ef27b33605514a64/portrait.png', kind: 'Doodad'}
    {slug: 'desert-well', name: 'Desert Well', original: '548cf4880f559d0000be7e53', portraitURL: '/file/db/thang.type/548cf4880f559d0000be7e53/portrait.png', kind: 'Doodad'}
    {slug: 'destroyed-human-tower', name: 'destroyed human tower', original: '57867e5acca8994b002702a9', portraitURL: '/file/db/thang.type/57867e5acca8994b002702a9/portrait.png', kind: 'Doodad'}
    {slug: 'destroyed-human-tower-with-trees', name: 'destroyed human tower with trees', original: '572d5abed7787fc300d85964', portraitURL: '/file/db/thang.type/572d5abed7787fc300d85964/portrait.png', kind: 'Doodad'}
    {slug: 'destroyed-human-tower-with-trees-2', name: 'destroyed human tower with trees 2', original: '572d5b42d7787fc300d8596f', portraitURL: '/file/db/thang.type/572d5b42d7787fc300d8596f/portrait.png', kind: 'Doodad'}
    {slug: 'destroyed-ogre-tower-footing', name: 'destroyed ogre tower footing', original: '578680980d397a2e0026eff9', portraitURL: '/file/db/thang.type/578680980d397a2e0026eff9/portrait.png', kind: 'Doodad'}
    {slug: 'diamond-sense-stone', name: 'Diamond Sense Stone', original: '546934b7a2b1f53ce79443e1', portraitURL: '/file/db/thang.type/546934b7a2b1f53ce79443e1/portrait.png', kind: 'Item'}
    {slug: 'dirt-path-1', name: 'Dirt Path 1', original: '5302acfd27471514685d5fd4', portraitURL: '/file/db/thang.type/5302acfd27471514685d5fd4/portrait.png', kind: 'Floor'}
    {slug: 'disintegrate', name: 'Disintegrate', original: '54d2bb1abb157252059b1d29', portraitURL: '/file/db/thang.type/54d2bb1abb157252059b1d29/portrait.png', kind: 'Mark'}
    {slug: 'dispel', name: 'Dispel', original: '55c2807d3767fd3435eb4465', portraitURL: '/file/db/thang.type/55c2807d3767fd3435eb4465/portrait.png', kind: 'Mark'}
    {slug: 'dragonscale-chainmail-coif', name: 'Dragonscale Chainmail Coif', original: '546d477d9df4a17d0d449a6b', portraitURL: '/file/db/thang.type/546d477d9df4a17d0d449a6b/portrait.png', kind: 'Item'}
    {slug: 'dragonscale-chainmail-tunic', name: 'Dragonscale Chainmail Tunic', original: '546d3d149df4a17d0d449a43', portraitURL: '/file/db/thang.type/546d3d149df4a17d0d449a43/portrait.png', kind: 'Item'}
    {slug: 'dragontooth', name: 'Dragontooth', original: '54eb51d349fa2d5c905ddf0e', portraitURL: '/file/db/thang.type/54eb51d349fa2d5c905ddf0e/portrait.png', kind: 'Item'}
    {slug: 'drain-life', name: 'Drain Life', original: '54d2bc5b4e4a08550556da55', portraitURL: '/file/db/thang.type/54d2bc5b4e4a08550556da55/portrait.png', kind: 'Mark'}
    {slug: 'dread-door-background', name: 'Dread Door Background', original: '572e46a3f8c4f9b601ede6c0', portraitURL: '/file/db/thang.type/572e46a3f8c4f9b601ede6c0/portrait.png', kind: 'Floor'}
    {slug: 'dueling-grounds-background', name: 'Dueling Grounds Background', original: '572e5163e8db5195014848b3', portraitURL: '/file/db/thang.type/572e5163e8db5195014848b3/portrait.png', kind: 'Floor'}
    {slug: 'dunes', name: 'Dunes', original: '546e251d9df4a17d0d449bd1', portraitURL: '/file/db/thang.type/546e251d9df4a17d0d449bd1/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-door', name: 'Dungeon Door', original: '52a0e5123abf480000000001', portraitURL: '/file/db/thang.type/52a0e5123abf480000000001/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-entrance', name: 'Dungeon Entrance', original: '544d850e8494308424f564dd', portraitURL: '/file/db/thang.type/544d850e8494308424f564dd/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-floor', name: 'Dungeon Floor', original: '52af688f6320a8049d000001', portraitURL: '/file/db/thang.type/52af688f6320a8049d000001/portrait.png', kind: 'Floor'}
    {slug: 'dungeon-pillar', name: 'Dungeon Pillar', original: '543ea0ff9692aa00006208e7', portraitURL: '/file/db/thang.type/543ea0ff9692aa00006208e7/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-pit', name: 'Dungeon Pit', original: '52b09408ccbc671372000002', portraitURL: '/file/db/thang.type/52b09408ccbc671372000002/portrait.png', kind: 'Floor'}
    {slug: 'dungeon-rock-1', name: 'Dungeon Rock 1', original: '54ef944764112781056c1f96', portraitURL: '/file/db/thang.type/54ef944764112781056c1f96/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-rock-2', name: 'Dungeon Rock 2', original: '54ef99bf223edd8105b00eaa', portraitURL: '/file/db/thang.type/54ef99bf223edd8105b00eaa/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-rock-3', name: 'Dungeon Rock 3', original: '54ef9af5b4740779058448c6', portraitURL: '/file/db/thang.type/54ef9af5b4740779058448c6/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-rock-4', name: 'Dungeon Rock 4', original: '54ef9c26933e1e7b0584663e', portraitURL: '/file/db/thang.type/54ef9c26933e1e7b0584663e/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-rock-5', name: 'Dungeon Rock 5', original: '54ef9d376aea7d7805535cc8', portraitURL: '/file/db/thang.type/54ef9d376aea7d7805535cc8/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-rock-group', name: 'Dungeon Rock Group', original: '54ef9e0583b08b7d054ba331', portraitURL: '/file/db/thang.type/54ef9e0583b08b7d054ba331/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-stairs-horizontal', name: 'Dungeon Stairs Horizontal', original: '5463dc27c295cc4fb9c06257', portraitURL: '/file/db/thang.type/5463dc27c295cc4fb9c06257/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-stairs-vertical', name: 'Dungeon Stairs Vertical', original: '5463d8a0c295cc4fb9c06255', portraitURL: '/file/db/thang.type/5463d8a0c295cc4fb9c06255/portrait.png', kind: 'Doodad'}
    {slug: 'dungeon-wall', name: 'Dungeon Wall', original: '529e7aecc423d4e83b000004', portraitURL: '/file/db/thang.type/529e7aecc423d4e83b000004/portrait.png', kind: 'Wall'}
    {slug: 'dungeons-of-kgard-background', name: 'Dungeons of Kgard Background', original: '563d3c02f5b71e8405fabff8', portraitURL: '/file/db/thang.type/563d3c02f5b71e8405fabff8/portrait.png', kind: 'Floor'}
    {slug: 'dynamic-flags', name: 'Dynamic Flags', original: '5478b9068707a2c3a2493b2b', portraitURL: '/file/db/thang.type/5478b9068707a2c3a2493b2b/portrait.png', kind: 'Item'}
    {slug: 'earthskin', name: 'Earthskin', original: '54d2bcf66ec7cf53051e7855', portraitURL: '/file/db/thang.type/54d2bcf66ec7cf53051e7855/portrait.png', kind: 'Mark'}
    {slug: 'east-mounted-camera-facing-east-west', name: 'east mounted camera facing east west', original: '56f183091e1daf0a016c670b', portraitURL: '/file/db/thang.type/56f183091e1daf0a016c670b/portrait.png', kind: 'Doodad'}
    {slug: 'east-mounted-camera-facing-north', name: 'east mounted camera facing north', original: '56f1782541c1a0cb00f8d66c', portraitURL: '/file/db/thang.type/56f1782541c1a0cb00f8d66c/portrait.png', kind: 'Doodad'}
    {slug: 'east-mounted-camera-facing-south', name: 'east mounted camera facing south', original: '56f1811841c1a0cb00f8ddb1', portraitURL: '/file/db/thang.type/56f1811841c1a0cb00f8ddb1/portrait.png', kind: 'Doodad'}
    {slug: 'edge-of-darkness', name: 'Edge of Darkness', original: '54eaa8762b7506e891ca71a9', portraitURL: '/file/db/thang.type/54eaa8762b7506e891ca71a9/portrait.png', kind: 'Item'}
    {slug: 'eldritch-icicle', name: 'Eldritch Icicle', original: '54ea311e2b7506e891ca70b0', portraitURL: '/file/db/thang.type/54ea311e2b7506e891ca70b0/portrait.png', kind: 'Item'}
    {slug: 'electrocute', name: 'Electrocute', original: '55c281263767fd3435eb4469', portraitURL: '/file/db/thang.type/55c281263767fd3435eb4469/portrait.png', kind: 'Mark'}
    {slug: 'electrowall', name: 'Electrowall', original: '54177e26571f116c0b1f00c0', portraitURL: '/file/db/thang.type/54177e26571f116c0b1f00c0/portrait.png', kind: 'Doodad'}
    {slug: 'elemental-codex-i', name: 'Elemental Codex I', original: '5463755a3839c6e02811d30a', portraitURL: '/file/db/thang.type/5463755a3839c6e02811d30a/portrait.png', kind: 'Item'}
    {slug: 'elemental-codex-ii', name: 'Elemental Codex II', original: '546375783839c6e02811d30d', portraitURL: '/file/db/thang.type/546375783839c6e02811d30d/portrait.png', kind: 'Item'}
    {slug: 'elemental-codex-iii', name: 'Elemental Codex III', original: '5463759c3839c6e02811d310', portraitURL: '/file/db/thang.type/5463759c3839c6e02811d310/portrait.png', kind: 'Item'}
    {slug: 'elemental-codex-iv', name: 'Elemental Codex IV', original: '546376bf3839c6e02811d31c', portraitURL: '/file/db/thang.type/546376bf3839c6e02811d31c/portrait.png', kind: 'Item'}
    {slug: 'elemental-codex-v', name: 'Elemental Codex V', original: '546376e23839c6e02811d31f', portraitURL: '/file/db/thang.type/546376e23839c6e02811d31f/portrait.png', kind: 'Item'}
    {slug: 'embroidered-griffin-wool-hat', name: 'Embroidered Griffin Wool Hat', original: '546d4ca19df4a17d0d449abf', portraitURL: '/file/db/thang.type/546d4ca19df4a17d0d449abf/portrait.png', kind: 'Item'}
    {slug: 'embroidered-griffin-wool-robe', name: 'Embroidered Griffin Wool Robe', original: '546d4a549df4a17d0d449a97', portraitURL: '/file/db/thang.type/546d4a549df4a17d0d449a97/portrait.png', kind: 'Item'}
    {slug: 'emerald-chainmail-coif', name: 'Emerald Chainmail Coif', original: '546d46cf9df4a17d0d449a63', portraitURL: '/file/db/thang.type/546d46cf9df4a17d0d449a63/portrait.png', kind: 'Item'}
    {slug: 'emerald-chainmail-tunic', name: 'Emerald Chainmail Tunic', original: '546d3c8d9df4a17d0d449a3b', portraitURL: '/file/db/thang.type/546d3c8d9df4a17d0d449a3b/portrait.png', kind: 'Item'}
    {slug: 'emperors-gloves', name: 'Emperor\'s Gloves', original: '546949aca2b1f53ce7944431', portraitURL: '/file/db/thang.type/546949aca2b1f53ce7944431/portrait.png', kind: 'Item'}
    {slug: 'enameled-dragonplate', name: 'Enameled Dragonplate', original: '546ab1e53777d61863292876', portraitURL: '/file/db/thang.type/546ab1e53777d61863292876/portrait.png', kind: 'Item'}
    {slug: 'enameled-dragonplate-helmet', name: 'Enameled Dragonplate Helmet', original: '546d3a539df4a17d0d449a1f', portraitURL: '/file/db/thang.type/546d3a539df4a17d0d449a1f/portrait.png', kind: 'Item'}
    {slug: 'enameled-dragonshield', name: 'Enameled Dragonshield', original: '54eabf022b7506e891ca7236', portraitURL: '/file/db/thang.type/54eabf022b7506e891ca7236/portrait.png', kind: 'Item'}
    {slug: 'enchanted-lambswool-cloak', name: 'Enchanted Lambswool Cloak', original: '546d49109df4a17d0d449a7f', portraitURL: '/file/db/thang.type/546d49109df4a17d0d449a7f/portrait.png', kind: 'Item'}
    {slug: 'enchanted-lenses', name: 'Enchanted Lenses', original: '546941cba2b1f53ce7944419', portraitURL: '/file/db/thang.type/546941cba2b1f53ce7944419/portrait.png', kind: 'Item'}
    {slug: 'enchanted-stick', name: 'Enchanted Stick', original: '544d87188494308424f564f1', portraitURL: '/file/db/thang.type/544d87188494308424f564f1/portrait.png', kind: 'Item'}
    {slug: 'enemy-mine-background', name: 'Enemy Mine Background', original: '563cdd340b2c7c87054e102b', portraitURL: '/file/db/thang.type/563cdd340b2c7c87054e102b/portrait.png', kind: 'Floor'}
    {slug: 'energy-ball', name: 'Energy Ball', original: '53025d83222f73867774d8ed', portraitURL: '/file/db/thang.type/53025d83222f73867774d8ed/portrait.png', kind: 'Missile'}
    {slug: 'energy-ball-diet', name: 'Energy Ball Diet', original: '531a6ddf1ddc910545d5e96d', portraitURL: '/file/db/thang.type/531a6ddf1ddc910545d5e96d/portrait.png', kind: 'Missile'}
    {slug: 'enforcer', name: 'Enforcer', original: '56d0ca1263103d2a00af5331', portraitURL: '/file/db/thang.type/56d0ca1263103d2a00af5331/portrait.png', kind: 'Unit'}
    {slug: 'engraved-builders-hammer', name: 'Engraved Builder\'s Hammer', original: '54694ca7a2b1f53ce7944462', portraitURL: '/file/db/thang.type/54694ca7a2b1f53ce7944462/portrait.png', kind: 'Item'}
    {slug: 'engraved-obsidian-breastplate', name: 'Engraved Obsidian Breastplate', original: '546ab15e3777d6186329286e', portraitURL: '/file/db/thang.type/546ab15e3777d6186329286e/portrait.png', kind: 'Item'}
    {slug: 'engraved-obsidian-helmet', name: 'Engraved Obsidian Helmet', original: '546d39d89df4a17d0d449a17', portraitURL: '/file/db/thang.type/546d39d89df4a17d0d449a17/portrait.png', kind: 'Item'}
    {slug: 'engraved-obsidian-shield', name: 'Engraved Obsidian Shield', original: '54eabbd22b7506e891ca721e', portraitURL: '/file/db/thang.type/54eabbd22b7506e891ca721e/portrait.png', kind: 'Item'}
    {slug: 'engraved-wristwatch', name: 'Engraved Wristwatch', original: '546937dea2b1f53ce79443ed', portraitURL: '/file/db/thang.type/546937dea2b1f53ce79443ed/portrait.png', kind: 'Item'}
    {slug: 'explosive-potion', name: 'Explosive Potion', original: '5466d9a5417c8b48a9811e8e', portraitURL: '/file/db/thang.type/5466d9a5417c8b48a9811e8e/portrait.png', kind: 'Missile'}
    {slug: 'ezeroths-timepiece', name: 'Ezeroth\'s Timepiece', original: '546938cea2b1f53ce79443f5', portraitURL: '/file/db/thang.type/546938cea2b1f53ce79443f5/portrait.png', kind: 'Item'}
    {slug: 'farm', name: 'Farm', original: '52ea853d427172ae56003494', portraitURL: '/file/db/thang.type/52ea853d427172ae56003494/portrait.png', kind: 'Doodad'}
    {slug: 'faux-fur-hat', name: 'Faux Fur Hat', original: '5441c2be4e9aeb727cc97105', portraitURL: '/file/db/thang.type/5441c2be4e9aeb727cc97105/portrait.png', kind: 'Item'}
    {slug: 'fear', name: 'Fear', original: '53024db827471514685d53b2', portraitURL: '/file/db/thang.type/53024db827471514685d53b2/portrait.png', kind: 'Mark'}
    {slug: 'fence', name: 'Fence', original: '5421bc5218adb78d98d265e8', portraitURL: '/file/db/thang.type/5421bc5218adb78d98d265e8/portrait.png', kind: 'Doodad'}
    {slug: 'fence-wall', name: 'Fence Wall', original: '54349179a4cc5c900efa4814', portraitURL: '/file/db/thang.type/54349179a4cc5c900efa4814/portrait.png', kind: 'Doodad'}
    {slug: 'filing-cabinet', name: 'Filing Cabinet', original: '52e9fa73427172ae56002593', portraitURL: '/file/db/thang.type/52e9fa73427172ae56002593/portrait.png', kind: 'Doodad'}
    {slug: 'fine-boots', name: 'Fine Boots', original: '53e2388e53457600003e3f09', portraitURL: '/file/db/thang.type/53e2388e53457600003e3f09/portrait.png', kind: 'Item'}
    {slug: 'fine-leather-chainmail-coif', name: 'Fine Leather Chainmail Coif', original: '546d455f9df4a17d0d449a4f', portraitURL: '/file/db/thang.type/546d455f9df4a17d0d449a4f/portrait.png', kind: 'Item'}
    {slug: 'fine-leather-chainmail-tunic', name: 'Fine Leather Chainmail Tunic', original: '546d3b129df4a17d0d449a27', portraitURL: '/file/db/thang.type/546d3b129df4a17d0d449a27/portrait.png', kind: 'Item'}
    {slug: 'fine-stone-builders-hammer', name: 'Fine Stone Builder\'s Hammer', original: '54694c44a2b1f53ce794445a', portraitURL: '/file/db/thang.type/54694c44a2b1f53ce794445a/portrait.png', kind: 'Item'}
    {slug: 'fine-telephoto-glasses', name: 'Fine Telephoto Glasses', original: '54694194a2b1f53ce7944415', portraitURL: '/file/db/thang.type/54694194a2b1f53ce7944415/portrait.png', kind: 'Item'}
    {slug: 'fine-wooden-glasses', name: 'Fine Wooden Glasses', original: '5469405ba2b1f53ce7944404', portraitURL: '/file/db/thang.type/5469405ba2b1f53ce7944404/portrait.png', kind: 'Item'}
    {slug: 'fir-tree-1', name: 'Fir Tree 1', original: '54e9503df54ef5794f354ec1', portraitURL: '/file/db/thang.type/54e9503df54ef5794f354ec1/portrait.png', kind: 'Doodad'}
    {slug: 'fir-tree-2', name: 'Fir Tree 2', original: '54e95107f54ef5794f354ec5', portraitURL: '/file/db/thang.type/54e95107f54ef5794f354ec5/portrait.png', kind: 'Doodad'}
    {slug: 'fir-tree-3', name: 'Fir Tree 3', original: '54e9513ff54ef5794f354ec9', portraitURL: '/file/db/thang.type/54e9513ff54ef5794f354ec9/portrait.png', kind: 'Doodad'}
    {slug: 'fir-tree-4', name: 'Fir Tree 4', original: '54e9518df54ef5794f354ecd', portraitURL: '/file/db/thang.type/54e9518df54ef5794f354ecd/portrait.png', kind: 'Doodad'}
    {slug: 'fire', name: 'Fire', original: '54d2bdea4e4a08550556dbfe', portraitURL: '/file/db/thang.type/54d2bdea4e4a08550556dbfe/portrait.png', kind: 'Mark'}
    {slug: 'fire-dancing-background', name: 'Fire Dancing Background', original: '576ad6ab7e64f325002df2e4', portraitURL: '/file/db/thang.type/576ad6ab7e64f325002df2e4/portrait.png', kind: 'Floor'}
    {slug: 'fire-opal-sense-stone', name: 'Fire Opal Sense Stone', original: '546932e4a2b1f53ce79443cd', portraitURL: '/file/db/thang.type/546932e4a2b1f53ce79443cd/portrait.png', kind: 'Item'}
    {slug: 'fire-trap', name: 'Fire Trap', original: '5449536afb56d566e86972ba', portraitURL: '/file/db/thang.type/5449536afb56d566e86972ba/portrait.png', kind: 'Misc'}
    {slug: 'fireball', name: 'Fireball', original: '531a6a2f1ddc910545d5e944', portraitURL: '/file/db/thang.type/531a6a2f1ddc910545d5e944/portrait.png', kind: 'Missile'}
    {slug: 'firewall', name: 'firewall', original: '56f56687db0216900f086ac1', portraitURL: '/file/db/thang.type/56f56687db0216900f086ac1/portrait.png', kind: 'Doodad'}
    {slug: 'firewood-1', name: 'Firewood 1', original: '52e953d0427172ae5600181d', portraitURL: '/file/db/thang.type/52e953d0427172ae5600181d/portrait.png', kind: 'Doodad'}
    {slug: 'firewood-2', name: 'Firewood 2', original: '52e9575d22efc8e7090016ed', portraitURL: '/file/db/thang.type/52e9575d22efc8e7090016ed/portrait.png', kind: 'Doodad'}
    {slug: 'firewood-3', name: 'Firewood 3', original: '52e957ec22efc8e7090016fd', portraitURL: '/file/db/thang.type/52e957ec22efc8e7090016fd/portrait.png', kind: 'Doodad'}
    {slug: 'firn-1', name: 'Firn 1', original: '557639fa1e82182d9e68894d', portraitURL: '/file/db/thang.type/557639fa1e82182d9e68894d/portrait.png', kind: 'Floor'}
    {slug: 'firn-2', name: 'Firn 2', original: '55763a971e82182d9e688951', portraitURL: '/file/db/thang.type/55763a971e82182d9e688951/portrait.png', kind: 'Floor'}
    {slug: 'firn-3', name: 'Firn 3', original: '55763ab51e82182d9e688955', portraitURL: '/file/db/thang.type/55763ab51e82182d9e688955/portrait.png', kind: 'Floor'}
    {slug: 'firn-4', name: 'Firn 4', original: '55763ad11e82182d9e688959', portraitURL: '/file/db/thang.type/55763ad11e82182d9e688959/portrait.png', kind: 'Floor'}
    {slug: 'firn-5', name: 'Firn 5', original: '55763aea1e82182d9e68895d', portraitURL: '/file/db/thang.type/55763aea1e82182d9e68895d/portrait.png', kind: 'Floor'}
    {slug: 'firn-6', name: 'Firn 6', original: '55763b111e82182d9e688961', portraitURL: '/file/db/thang.type/55763b111e82182d9e688961/portrait.png', kind: 'Floor'}
    {slug: 'firn-cliff', name: 'Firn Cliff', original: '55c277983767fd3435eb444e', portraitURL: '/file/db/thang.type/55c277983767fd3435eb444e/portrait.png', kind: 'Floor'}
    {slug: 'flame-armor', name: 'Flame Armor', original: '55c27b5c3767fd3435eb445a', portraitURL: '/file/db/thang.type/55c27b5c3767fd3435eb445a/portrait.png', kind: 'Mark'}
    {slug: 'flaming-shell', name: 'Flaming Shell', original: '553e80669bdea5d00f1fd90e', portraitURL: '/file/db/thang.type/553e80669bdea5d00f1fd90e/portrait.png', kind: 'Missile'}
    {slug: 'flippable-land', name: 'Flippable Land', original: '53a20126610a6b3505568163', portraitURL: '/file/db/thang.type/53a20126610a6b3505568163/portrait.png', kind: 'Floor'}
    {slug: 'floppy-lambswool-hat', name: 'Floppy Lambswool Hat', original: '546d4b069df4a17d0d449aa3', portraitURL: '/file/db/thang.type/546d4b069df4a17d0d449aa3/portrait.png', kind: 'Item'}
    {slug: 'force-bolt', name: 'Force Bolt', original: '5467807c417c8b48a9811efd', portraitURL: '/file/db/thang.type/5467807c417c8b48a9811efd/portrait.png', kind: 'Missile'}
    {slug: 'forest-river-tile-deadend', name: 'Forest River tile deadend', original: '577d5b367e0491260074b95b', portraitURL: '/file/db/thang.type/577d5b367e0491260074b95b/portrait.png', kind: 'undefined'}
    {slug: 'forest-river-tile-full-intersection', name: 'forest river tile full intersection', original: '5786badaa6c6413500926209', portraitURL: '/file/db/thang.type/5786badaa6c6413500926209/portrait.png', kind: 'undefined'}
    {slug: 'forest-river-tile-straight', name: 'forest river tile straight', original: '577d58d5dbf35b24001b91cb', portraitURL: '/file/db/thang.type/577d58d5dbf35b24001b91cb/portrait.png', kind: 'undefined'}
    {slug: 'forest-river-tile-t-intersection', name: 'Forest River tile t intersection', original: '577d5b927e0491260074ba3a', portraitURL: '/file/db/thang.type/577d5b927e0491260074ba3a/portrait.png', kind: 'undefined'}
    {slug: 'forest-river-tile-turn', name: 'Forest River tile turn', original: '577d59e37e0491260074b5bd', portraitURL: '/file/db/thang.type/577d59e37e0491260074b5bd/portrait.png', kind: 'undefined'}
    {slug: 'forgetful-gemsmith-background', name: 'Forgetful Gemsmith Background', original: '562a9b9ea4cdd48805fb98ca', portraitURL: '/file/db/thang.type/562a9b9ea4cdd48805fb98ca/portrait.png', kind: 'Floor'}
    {slug: 'forgotten-bronze-ring', name: 'Forgotten Bronze Ring', original: '54692d8aa2b1f53ce7944397', portraitURL: '/file/db/thang.type/54692d8aa2b1f53ce7944397/portrait.png', kind: 'Item'}
    {slug: 'frog', name: 'Frog', original: '57869cf7bd31c14400834028', portraitURL: '/file/db/thang.type/57869cf7bd31c14400834028/portrait.png', kind: 'Item'}
    {slug: 'frog-pet', name: 'Frog Pet', original: '540f3678821af8000097dc56', portraitURL: '/file/db/thang.type/540f3678821af8000097dc56/portrait.png', kind: 'Unit'}
    {slug: 'gargoyle', name: 'Gargoyle', original: '52afc8f0c5b1813ec2000008', portraitURL: '/file/db/thang.type/52afc8f0c5b1813ec2000008/portrait.png', kind: 'Doodad'}
    {slug: 'gargoyle-side', name: 'Gargoyle Side', original: '54efa07f4bb4788505d2339e', portraitURL: '/file/db/thang.type/54efa07f4bb4788505d2339e/portrait.png', kind: 'Doodad'}
    {slug: 'gauntlets-of-strength', name: 'Gauntlets of Strength', original: '53e2202953457600003e3ed9', portraitURL: '/file/db/thang.type/53e2202953457600003e3ed9/portrait.png', kind: 'Item'}
    {slug: 'gem-pile-medium', name: 'Gem Pile Medium', original: '543306638364d30000d1f951', portraitURL: '/file/db/thang.type/543306638364d30000d1f951/portrait.png', kind: 'Misc'}
    {slug: 'gem-pile-small', name: 'Gem Pile Small', original: '543305f78364d30000d1f94a', portraitURL: '/file/db/thang.type/543305f78364d30000d1f94a/portrait.png', kind: 'Misc'}
    {slug: 'gems-of-the-deep-background', name: 'Gems of the Deep Background', original: '563aa55276289f86054a7c02', portraitURL: '/file/db/thang.type/563aa55276289f86054a7c02/portrait.png', kind: 'Floor'}
    {slug: 'generic-armor-mark-1', name: 'Generic Armor Mark 1', original: '54d2be25bb157252059b2202', portraitURL: '/file/db/thang.type/54d2be25bb157252059b2202/portrait.png', kind: 'Mark'}
    {slug: 'generic-armor-mark-2', name: 'Generic Armor Mark 2', original: '54d2be9e3e16915505f0c7a4', portraitURL: '/file/db/thang.type/54d2be9e3e16915505f0c7a4/portrait.png', kind: 'Mark'}
    {slug: 'generic-item', name: 'Generic Item', original: '545d3eb52d03e700001b5a5b', portraitURL: '/file/db/thang.type/545d3eb52d03e700001b5a5b/portrait.png', kind: 'Item'}
    {slug: 'gift-of-the-trees', name: 'Gift of the Trees', original: '54eab0a32b7506e891ca71dd', portraitURL: '/file/db/thang.type/54eab0a32b7506e891ca71dd/portrait.png', kind: 'Item'}
    {slug: 'gilt-wristwatch', name: 'Gilt Wristwatch', original: '54693830a2b1f53ce79443f1', portraitURL: '/file/db/thang.type/54693830a2b1f53ce79443f1/portrait.png', kind: 'Item'}
    {slug: 'glasses-doodad', name: 'Glasses Doodad', original: '5420c4c5a0feb36ad21d45e2', portraitURL: '/file/db/thang.type/5420c4c5a0feb36ad21d45e2/portrait.png', kind: 'Item'}
    {slug: 'glitterbomb', name: 'Glitterbomb', original: '54eb50f649fa2d5c905ddf0a', portraitURL: '/file/db/thang.type/54eb50f649fa2d5c905ddf0a/portrait.png', kind: 'Item'}
    {slug: 'goal-trigger', name: 'Goal Trigger', original: '52bcbf0dce43b70000000006', portraitURL: '/file/db/thang.type/52bcbf0dce43b70000000006/portrait.png', kind: 'Misc'}
    {slug: 'gold-ball', name: 'Gold Ball', original: '550b742b8a7d3c197a824dad', portraitURL: '/file/db/thang.type/550b742b8a7d3c197a824dad/portrait.png', kind: 'Missile'}
    {slug: 'gold-cloud', name: 'Gold Cloud', original: '550b4b9d8a7d3c197a824d5e', portraitURL: '/file/db/thang.type/550b4b9d8a7d3c197a824d5e/portrait.png', kind: 'Doodad'}
    {slug: 'golden-wand', name: 'Golden Wand', original: '54eab7f52b7506e891ca7202', portraitURL: '/file/db/thang.type/54eab7f52b7506e891ca7202/portrait.png', kind: 'Item'}
    {slug: 'goldspun-silk-cloak', name: 'Goldspun Silk Cloak', original: '546d49da9df4a17d0d449a8f', portraitURL: '/file/db/thang.type/546d49da9df4a17d0d449a8f/portrait.png', kind: 'Item'}
    {slug: 'goldspun-silk-hat', name: 'Goldspun Silk Hat', original: '546d4c249df4a17d0d449ab7', portraitURL: '/file/db/thang.type/546d4c249df4a17d0d449ab7/portrait.png', kind: 'Item'}
    {slug: 'grass-cliffs', name: 'Grass Cliffs', original: '52bcb96ece43b70000000003', portraitURL: '/file/db/thang.type/52bcb96ece43b70000000003/portrait.png', kind: 'Floor'}
    {slug: 'grass01', name: 'Grass01', original: '53016dddd82649ec2c0c9b29', portraitURL: '/file/db/thang.type/53016dddd82649ec2c0c9b29/portrait.png', kind: 'Floor'}
    {slug: 'grass02', name: 'Grass02', original: '53016fc098f2ca1f6e82eebd', portraitURL: '/file/db/thang.type/53016fc098f2ca1f6e82eebd/portrait.png', kind: 'Floor'}
    {slug: 'grass03', name: 'Grass03', original: '5301702d98f2ca1f6e82eec4', portraitURL: '/file/db/thang.type/5301702d98f2ca1f6e82eec4/portrait.png', kind: 'Floor'}
    {slug: 'grass04', name: 'Grass04', original: '530170a198f2ca1f6e82eecf', portraitURL: '/file/db/thang.type/530170a198f2ca1f6e82eecf/portrait.png', kind: 'Floor'}
    {slug: 'grass05', name: 'Grass05', original: '5301716398f2ca1f6e82eedc', portraitURL: '/file/db/thang.type/5301716398f2ca1f6e82eedc/portrait.png', kind: 'Floor'}
    {slug: 'gravestone-cross', name: 'Gravestone Cross', original: '54f1100e8d380d7f05acc975', portraitURL: '/file/db/thang.type/54f1100e8d380d7f05acc975/portrait.png', kind: 'Doodad'}
    {slug: 'gravestone-rounded', name: 'Gravestone Rounded', original: '54f110e3f854c97a05551616', portraitURL: '/file/db/thang.type/54f110e3f854c97a05551616/portrait.png', kind: 'Doodad'}
    {slug: 'gravestone-square', name: 'Gravestone Square', original: '54f10f08d2969f8405ef51fd', portraitURL: '/file/db/thang.type/54f10f08d2969f8405ef51fd/portrait.png', kind: 'Doodad'}
    {slug: 'graveyard-fence', name: 'Graveyard Fence', original: '54f111b379054c8705757747', portraitURL: '/file/db/thang.type/54f111b379054c8705757747/portrait.png', kind: 'Doodad'}
    {slug: 'great-sword', name: 'Great Sword', original: '544d7f8d8494308424f564bf', portraitURL: '/file/db/thang.type/544d7f8d8494308424f564bf/portrait.png', kind: 'Item'}
    {slug: 'greed-background', name: 'Greed Background', original: '53764e4ea7b5ab3805f153a4', portraitURL: '/file/db/thang.type/53764e4ea7b5ab3805f153a4/portrait.png', kind: 'Floor'}
    {slug: 'green-bubble-missile', name: 'Green Bubble Missile', original: '540e35a34f21cd879ba4f140', portraitURL: '/file/db/thang.type/540e35a34f21cd879ba4f140/portrait.png', kind: 'Missile'}
    {slug: 'griffin-rider', name: 'Griffin Rider', original: '52d45d1ab10ae4b024000002', portraitURL: '/file/db/thang.type/52d45d1ab10ae4b024000002/portrait.png', kind: 'Unit'}
    {slug: 'griffin-wool-hat', name: 'Griffin Wool Hat', original: '546d4c699df4a17d0d449abb', portraitURL: '/file/db/thang.type/546d4c699df4a17d0d449abb/portrait.png', kind: 'Item'}
    {slug: 'griffin-wool-robe', name: 'Griffin Wool Robe', original: '546d4a159df4a17d0d449a93', portraitURL: '/file/db/thang.type/546d4a159df4a17d0d449a93/portrait.png', kind: 'Item'}
    {slug: 'hand-sewn-linen-wizards-hat', name: 'Hand-sewn Linen Wizard\'s Hat', original: '546d4bec9df4a17d0d449ab3', portraitURL: '/file/db/thang.type/546d4bec9df4a17d0d449ab3/portrait.png', kind: 'Item'}
    {slug: 'hardened-emerald-chainmail-coif', name: 'Hardened Emerald Chainmail Coif', original: '546d47159df4a17d0d449a67', portraitURL: '/file/db/thang.type/546d47159df4a17d0d449a67/portrait.png', kind: 'Item'}
    {slug: 'hardened-emerald-chainmail-tunic', name: 'Hardened Emerald Chainmail Tunic', original: '546d3cce9df4a17d0d449a3f', portraitURL: '/file/db/thang.type/546d3cce9df4a17d0d449a3f/portrait.png', kind: 'Item'}
    {slug: 'hardened-steel-glasses', name: 'Hardened Steel Glasses', original: '546940d8a2b1f53ce794440d', portraitURL: '/file/db/thang.type/546940d8a2b1f53ce794440d/portrait.png', kind: 'Item'}
    {slug: 'harrowland-background', name: 'Harrowland Background', original: '572e51e3f8c4f9b601ede885', portraitURL: '/file/db/thang.type/572e51e3f8c4f9b601ede885/portrait.png', kind: 'Floor'}
    {slug: 'haste', name: 'Haste', original: '530251cfa6efdd32359c53d5', portraitURL: '/file/db/thang.type/530251cfa6efdd32359c53d5/portrait.png', kind: 'Mark'}
    {slug: 'haunted-kithmaze-background', name: 'Haunted Kithmaze Background', original: '569dd4f2b55fd82e0011b79b', portraitURL: '/file/db/thang.type/569dd4f2b55fd82e0011b79b/portrait.png', kind: 'Floor'}
    {slug: 'heal', name: 'Heal', original: '55c63ebcef141c65665beb59', portraitURL: '/file/db/thang.type/55c63ebcef141c65665beb59/portrait.png', kind: 'Mark'}
    {slug: 'health-potion-large', name: 'Health Potion Large', original: '52afc634c5b1813ec2000002', portraitURL: '/file/db/thang.type/52afc634c5b1813ec2000002/portrait.png', kind: 'Misc'}
    {slug: 'health-potion-medium', name: 'Health Potion Medium', original: '52afc742c5b1813ec2000004', portraitURL: '/file/db/thang.type/52afc742c5b1813ec2000004/portrait.png', kind: 'Misc'}
    {slug: 'health-potion-small', name: 'Health Potion Small', original: '52afc7b6c5b1813ec2000006', portraitURL: '/file/db/thang.type/52afc7b6c5b1813ec2000006/portrait.png', kind: 'Misc'}
    {slug: 'heavy-iron-breastplate', name: 'Heavy Iron Breastplate', original: '546aaf1b3777d6186329285e', portraitURL: '/file/db/thang.type/546aaf1b3777d6186329285e/portrait.png', kind: 'Item'}
    {slug: 'heavy-iron-helmet', name: 'Heavy Iron Helmet', original: '546d390b9df4a17d0d449a0b', portraitURL: '/file/db/thang.type/546d390b9df4a17d0d449a0b/portrait.png', kind: 'Item'}
    {slug: 'helmet-fall-1', name: 'Helmet Fall 1', original: '53e2e3e66c59f5340504108f', portraitURL: '/file/db/thang.type/53e2e3e66c59f5340504108f/portrait.png', kind: 'Doodad'}
    {slug: 'hide', name: 'Hide', original: '55c281e83767fd3435eb446d', portraitURL: '/file/db/thang.type/55c281e83767fd3435eb446d/portrait.png', kind: 'Mark'}
    {slug: 'highlight', name: 'Highlight', original: '529f8fdbdacd325127000003', portraitURL: '/file/db/thang.type/529f8fdbdacd325127000003/portrait.png', kind: 'Mark'}
    {slug: 'holoball', name: 'Holoball', original: '56d0fa8a087ee32400764bb8', portraitURL: '/file/db/thang.type/56d0fa8a087ee32400764bb8/portrait.png', kind: 'Doodad'}
    {slug: 'holy-sword', name: 'Holy Sword', original: '53e21249b82921000051ce11', portraitURL: '/file/db/thang.type/53e21249b82921000051ce11/portrait.png', kind: 'Item'}
    {slug: 'house-1', name: 'House 1', original: '52b095bbccbc671372000006', portraitURL: '/file/db/thang.type/52b095bbccbc671372000006/portrait.png', kind: 'Doodad'}
    {slug: 'house-2', name: 'House 2', original: '52b09d35ccbc671372000009', portraitURL: '/file/db/thang.type/52b09d35ccbc671372000009/portrait.png', kind: 'Doodad'}
    {slug: 'house-3', name: 'House 3', original: '52b09dd0ccbc67137200000b', portraitURL: '/file/db/thang.type/52b09dd0ccbc67137200000b/portrait.png', kind: 'Doodad'}
    {slug: 'house-4', name: 'House 4', original: '52b09e2fccbc67137200000d', portraitURL: '/file/db/thang.type/52b09e2fccbc67137200000d/portrait.png', kind: 'Doodad'}
    {slug: 'hoverboard-stand', name: 'Hoverboard Stand', original: '56c630aeed946a44004ff139', portraitURL: '/file/db/thang.type/56c630aeed946a44004ff139/portrait.png', kind: 'Doodad'}
    {slug: 'human-barracks', name: 'Human Barracks', original: '530ce329ec5bdaba2a72a99c', portraitURL: '/file/db/thang.type/530ce329ec5bdaba2a72a99c/portrait.png', kind: 'Unit'}
    {slug: 'hunting-rifle', name: 'Hunting Rifle', original: '544d82aa8494308424f564cf', portraitURL: '/file/db/thang.type/544d82aa8494308424f564cf/portrait.png', kind: 'Item'}
    {slug: 'ice-crystals-1', name: 'Ice Crystals 1', original: '557639501e82182d9e688945', portraitURL: '/file/db/thang.type/557639501e82182d9e688945/portrait.png', kind: 'Doodad'}
    {slug: 'ice-crystals-2', name: 'Ice Crystals 2', original: '557639b91e82182d9e688949', portraitURL: '/file/db/thang.type/557639b91e82182d9e688949/portrait.png', kind: 'Doodad'}
    {slug: 'ice-door', name: 'Ice Door', original: '557f32b0b43ce0b15a91b16d', portraitURL: '/file/db/thang.type/557f32b0b43ce0b15a91b16d/portrait.png', kind: 'Doodad'}
    {slug: 'ice-gargoyle', name: 'Ice Gargoyle', original: '55760d3f1e82182d9e6888f6', portraitURL: '/file/db/thang.type/55760d3f1e82182d9e6888f6/portrait.png', kind: 'Doodad'}
    {slug: 'ice-gargoyle-fore', name: 'Ice Gargoyle Fore', original: '55760e311e82182d9e688902', portraitURL: '/file/db/thang.type/55760e311e82182d9e688902/portrait.png', kind: 'Doodad'}
    {slug: 'ice-gargoyle-ruin', name: 'Ice Gargoyle Ruin', original: '55760dc31e82182d9e6888fa', portraitURL: '/file/db/thang.type/55760dc31e82182d9e6888fa/portrait.png', kind: 'Doodad'}
    {slug: 'ice-gargoyle-ruin-fore', name: 'Ice Gargoyle Ruin Fore', original: '55760dfa1e82182d9e6888fe', portraitURL: '/file/db/thang.type/55760dfa1e82182d9e6888fe/portrait.png', kind: 'Doodad'}
    {slug: 'ice-rink-1', name: 'Ice Rink 1', original: '557f321bb43ce0b15a91b161', portraitURL: '/file/db/thang.type/557f321bb43ce0b15a91b161/portrait.png', kind: 'Floor'}
    {slug: 'ice-rink-2', name: 'Ice Rink 2', original: '557f325cb43ce0b15a91b165', portraitURL: '/file/db/thang.type/557f325cb43ce0b15a91b165/portrait.png', kind: 'Floor'}
    {slug: 'ice-rink-3', name: 'Ice Rink 3', original: '557f3275b43ce0b15a91b169', portraitURL: '/file/db/thang.type/557f3275b43ce0b15a91b169/portrait.png', kind: 'Floor'}
    {slug: 'ice-tree-1', name: 'Ice Tree 1', original: '557635641e82182d9e688929', portraitURL: '/file/db/thang.type/557635641e82182d9e688929/portrait.png', kind: 'Doodad'}
    {slug: 'ice-tree-2', name: 'Ice Tree 2', original: '557636401e82182d9e68892d', portraitURL: '/file/db/thang.type/557636401e82182d9e68892d/portrait.png', kind: 'Doodad'}
    {slug: 'ice-tree-3', name: 'Ice Tree 3', original: '557636e11e82182d9e688931', portraitURL: '/file/db/thang.type/557636e11e82182d9e688931/portrait.png', kind: 'Doodad'}
    {slug: 'ice-wall', name: 'Ice Wall', original: '5575f002f3f8d13b4ee1e7fc', portraitURL: '/file/db/thang.type/5575f002f3f8d13b4ee1e7fc/portrait.png', kind: 'Wall'}
    {slug: 'ice-yak', name: 'Ice Yak', original: '557f3917b43ce0b15a91b175', portraitURL: '/file/db/thang.type/557f3917b43ce0b15a91b175/portrait.png', kind: 'Unit'}
    {slug: 'igloo-1', name: 'Igloo 1', original: '557608f61e82182d9e6888cf', portraitURL: '/file/db/thang.type/557608f61e82182d9e6888cf/portrait.png', kind: 'Doodad'}
    {slug: 'igloo-2', name: 'Igloo 2', original: '557609b01e82182d9e6888d3', portraitURL: '/file/db/thang.type/557609b01e82182d9e6888d3/portrait.png', kind: 'Doodad'}
    {slug: 'igloo-3', name: 'Igloo 3', original: '557609dd1e82182d9e6888d7', portraitURL: '/file/db/thang.type/557609dd1e82182d9e6888d7/portrait.png', kind: 'Doodad'}
    {slug: 'igloo-4', name: 'Igloo 4', original: '55760a2c1e82182d9e6888db', portraitURL: '/file/db/thang.type/55760a2c1e82182d9e6888db/portrait.png', kind: 'Doodad'}
    {slug: 'impaling-firebolt', name: 'Impaling Firebolt', original: '54f767c4b3e4927805021022', portraitURL: '/file/db/thang.type/54f767c4b3e4927805021022/portrait.png', kind: 'Missile'}
    {slug: 'importer-of-great-justice', name: 'Importer of Great Justice', original: '54938575e9850ae3e8fbdd74', portraitURL: '/file/db/thang.type/54938575e9850ae3e8fbdd74/portrait.png', kind: 'undefined'}
    {slug: 'indoor-floor', name: 'Indoor Floor', original: '52ead2b2207133f35c000833', portraitURL: '/file/db/thang.type/52ead2b2207133f35c000833/portrait.png', kind: 'Floor'}
    {slug: 'indoor-wall', name: 'Indoor Wall', original: '52ea9a13d23f140d100000b2', portraitURL: '/file/db/thang.type/52ea9a13d23f140d100000b2/portrait.png', kind: 'Wall'}
    {slug: 'infantry-shield', name: 'Infantry Shield', original: '544d7bb88494308424f56493', portraitURL: '/file/db/thang.type/544d7bb88494308424f56493/portrait.png', kind: 'Item'}
    {slug: 'invisible', name: 'Invisible', original: '52b0f9c75c5c4af6bd000004', portraitURL: '/file/db/thang.type/52b0f9c75c5c4af6bd000004/portrait.png', kind: 'Misc'}
    {slug: 'iron-chainmail-coif', name: 'Iron Chainmail Coif', original: '546d45c59df4a17d0d449a53', portraitURL: '/file/db/thang.type/546d45c59df4a17d0d449a53/portrait.png', kind: 'Item'}
    {slug: 'iron-chainmail-tunic', name: 'Iron Chainmail Tunic', original: '546d3b7c9df4a17d0d449a2b', portraitURL: '/file/db/thang.type/546d3b7c9df4a17d0d449a2b/portrait.png', kind: 'Item'}
    {slug: 'iron-defender', name: 'Iron Defender', original: '54eaabe62b7506e891ca71c9', portraitURL: '/file/db/thang.type/54eaabe62b7506e891ca71c9/portrait.png', kind: 'Item'}
    {slug: 'iron-link', name: 'Iron Link', original: '54692d5ca2b1f53ce7944393', portraitURL: '/file/db/thang.type/54692d5ca2b1f53ce7944393/portrait.png', kind: 'Item'}
    {slug: 'iron-maiden', name: 'Iron Maiden', original: '54ef9f0a83b08b7d054ba50d', portraitURL: '/file/db/thang.type/54ef9f0a83b08b7d054ba50d/portrait.png', kind: 'Doodad'}
    {slug: 'iron-shield', name: 'Iron Shield', original: '5441c3f44e9aeb727cc97129', portraitURL: '/file/db/thang.type/5441c3f44e9aeb727cc97129/portrait.png', kind: 'Item'}
    {slug: 'kings-ring', name: 'King\'s Ring', original: '54eb56df49fa2d5c905ddf2e', portraitURL: '/file/db/thang.type/54eb56df49fa2d5c905ddf2e/portrait.png', kind: 'Item'}
    {slug: 'kithgard-gates-background', name: 'Kithgard Gates Background', original: '572e52b17a9c3e8101b8be0e', portraitURL: '/file/db/thang.type/572e52b17a9c3e8101b8be0e/portrait.png', kind: 'Floor'}
    {slug: 'kithgard-workers-glasses', name: 'Kithgard Worker\'s Glasses', original: '53eb99f41a100989a40ce46e', portraitURL: '/file/db/thang.type/53eb99f41a100989a40ce46e/portrait.png', kind: 'Item'}
    {slug: 'kithsteel-blade', name: 'Kithsteel Blade', original: '54eaa78a2b7506e891ca719d', portraitURL: '/file/db/thang.type/54eaa78a2b7506e891ca719d/portrait.png', kind: 'Item'}
    {slug: 'knightfire-charge', name: 'Knightfire Charge', original: '544d96328494308424f56533', portraitURL: '/file/db/thang.type/544d96328494308424f56533/portrait.png', kind: 'Item'}
    {slug: 'knightfire-charge-missile', name: 'Knightfire Charge Missile', original: '546297f1f44055a4b5e735bb', portraitURL: '/file/db/thang.type/546297f1f44055a4b5e735bb/portrait.png', kind: 'Missile'}
    {slug: 'known-enemy-background', name: 'Known Enemy Background', original: '572e4e61b2088976012429eb', portraitURL: '/file/db/thang.type/572e4e61b2088976012429eb/portrait.png', kind: 'Floor'}
    {slug: 'koraths-promise', name: 'Korath\'s Promise', original: '54eb575749fa2d5c905ddf3a', portraitURL: '/file/db/thang.type/54eb575749fa2d5c905ddf3a/portrait.png', kind: 'Item'}
    {slug: 'krummholz-1', name: 'Krummholz 1', original: '54e953adf54ef5794f354ef1', portraitURL: '/file/db/thang.type/54e953adf54ef5794f354ef1/portrait.png', kind: 'Doodad'}
    {slug: 'krummholz-2', name: 'Krummholz 2', original: '54e9545bf54ef5794f354ef5', portraitURL: '/file/db/thang.type/54e9545bf54ef5794f354ef5/portrait.png', kind: 'Doodad'}
    {slug: 'krummholz-3', name: 'Krummholz 3', original: '54e95492f54ef5794f354ef9', portraitURL: '/file/db/thang.type/54e95492f54ef5794f354ef9/portrait.png', kind: 'Doodad'}
    {slug: 'lambswool-cloak', name: 'Lambswool Cloak', original: '546d48ce9df4a17d0d449a7b', portraitURL: '/file/db/thang.type/546d48ce9df4a17d0d449a7b/portrait.png', kind: 'Item'}
    {slug: 'large-bolt-crossbow', name: 'Large Bolt Crossbow', original: '544d80598494308424f564c7', portraitURL: '/file/db/thang.type/544d80598494308424f564c7/portrait.png', kind: 'Item'}
    {slug: 'large-classroom-viewscreen-off', name: 'Large Classroom Viewscreen Off', original: '56c632c6abf4a61f009040b5', portraitURL: '/file/db/thang.type/56c632c6abf4a61f009040b5/portrait.png', kind: 'Doodad'}
    {slug: 'large-classroom-viewscreen-on', name: 'Large Classroom Viewscreen On', original: '56eb28b267a0142000a36358', portraitURL: '/file/db/thang.type/56eb28b267a0142000a36358/portrait.png', kind: 'Doodad'}
    {slug: 'lava-grate', name: 'Lava Grate', original: '54ef9fb8c1f3bd7c05941750', portraitURL: '/file/db/thang.type/54ef9fb8c1f3bd7c05941750/portrait.png', kind: 'Doodad'}
    {slug: 'leather-belt', name: 'Leather Belt', original: '5437002a7beba4a82024a97d', portraitURL: '/file/db/thang.type/5437002a7beba4a82024a97d/portrait.png', kind: 'Item'}
    {slug: 'leather-boots', name: 'Leather Boots', original: '53e2384453457600003e3f07', portraitURL: '/file/db/thang.type/53e2384453457600003e3f07/portrait.png', kind: 'Item'}
    {slug: 'leather-chainmail-coif', name: 'Leather Chainmail Coif', original: '546d45089df4a17d0d449a4b', portraitURL: '/file/db/thang.type/546d45089df4a17d0d449a4b/portrait.png', kind: 'Item'}
    {slug: 'leather-chainmail-tunic', name: 'Leather Chainmail Tunic', original: '546d3ab69df4a17d0d449a23', portraitURL: '/file/db/thang.type/546d3ab69df4a17d0d449a23/portrait.png', kind: 'Item'}
    {slug: 'leather-tunic', name: 'Leather Tunic', original: '545d3cf22d03e700001b5a58', portraitURL: '/file/db/thang.type/545d3cf22d03e700001b5a58/portrait.png', kind: 'Item'}
    {slug: 'level-banner', name: 'Level Banner', original: '5432c9688364d30000d1f935', portraitURL: '/file/db/thang.type/5432c9688364d30000d1f935/portrait.png', kind: 'Misc'}
    {slug: 'lightning-bolt', name: 'Lightning Bolt', original: '54f3fa515fcc6a3950c7eabd', portraitURL: '/file/db/thang.type/54f3fa515fcc6a3950c7eabd/portrait.png', kind: 'Missile'}
    {slug: 'lightning-stick', name: 'Lightning Stick', original: '544d86318494308424f564e8', portraitURL: '/file/db/thang.type/544d86318494308424f564e8/portrait.png', kind: 'Item'}
    {slug: 'lightning-twig', name: 'Lightning Twig', original: '54eab1ec2b7506e891ca71e1', portraitURL: '/file/db/thang.type/54eab1ec2b7506e891ca71e1/portrait.png', kind: 'Item'}
    {slug: 'lightstone', name: 'Lightstone', original: '54da20b7163110520551ed33', portraitURL: '/file/db/thang.type/54da20b7163110520551ed33/portrait.png', kind: 'Misc'}
    {slug: 'log-1', name: 'Log 1', original: '54e954d7f54ef5794f354efd', portraitURL: '/file/db/thang.type/54e954d7f54ef5794f354efd/portrait.png', kind: 'Doodad'}
    {slug: 'log-2', name: 'Log 2', original: '54e9553ef54ef5794f354f01', portraitURL: '/file/db/thang.type/54e9553ef54ef5794f354f01/portrait.png', kind: 'Doodad'}
    {slug: 'log-3', name: 'Log 3', original: '54e9556af54ef5794f354f05', portraitURL: '/file/db/thang.type/54e9556af54ef5794f354f05/portrait.png', kind: 'Doodad'}
    {slug: 'long-sword', name: 'Long Sword', original: '544d7d1f8494308424f564a3', portraitURL: '/file/db/thang.type/544d7d1f8494308424f564a3/portrait.png', kind: 'Item'}
    {slug: 'loop-da-loop-background', name: 'Loop Da Loop Background', original: '56c67cba797353370060506d', portraitURL: '/file/db/thang.type/56c67cba797353370060506d/portrait.png', kind: 'Floor'}
    {slug: 'magic-missile', name: 'Magic Missile', original: '5467beaf69d1ba0000fb91fb', portraitURL: '/file/db/thang.type/5467beaf69d1ba0000fb91fb/portrait.png', kind: 'Missile'}
    {slug: 'magnetize', name: 'Magnetize', original: '55c6403eef141c65665beb5e', portraitURL: '/file/db/thang.type/55c6403eef141c65665beb5e/portrait.png', kind: 'Mark'}
    {slug: 'mahogany-glasses', name: 'Mahogany Glasses', original: '54694093a2b1f53ce7944408', portraitURL: '/file/db/thang.type/54694093a2b1f53ce7944408/portrait.png', kind: 'Item'}
    {slug: 'mahogany-staff', name: 'Mahogany Staff', original: '544d88158494308424f56501', portraitURL: '/file/db/thang.type/544d88158494308424f56501/portrait.png', kind: 'Item'}
    {slug: 'maka-test-wall', name: 'maka-test-wall', original: '56a7d85fb679392600e31138', portraitURL: '/file/db/thang.type/56a7d85fb679392600e31138/portrait.png', kind: 'Wall'}
    {slug: 'market-stand', name: 'Market Stand', original: '54f11600f854c97a055516da', portraitURL: '/file/db/thang.type/54f11600f854c97a055516da/portrait.png', kind: 'Doodad'}
    {slug: 'master-of-names-background', name: 'Master of Names Background', original: '572e4ec2e8db519501484869', portraitURL: '/file/db/thang.type/572e4ec2e8db519501484869/portrait.png', kind: 'Floor'}
    {slug: 'master-sword', name: 'Master Sword', original: '54ea89112b7506e891ca717d', portraitURL: '/file/db/thang.type/54ea89112b7506e891ca717d/portrait.png', kind: 'Item'}
    {slug: 'masters-flags', name: 'Master\'s Flags', original: '5478b9be8707a2c3a2493b33', portraitURL: '/file/db/thang.type/5478b9be8707a2c3a2493b33/portrait.png', kind: 'Item'}
    {slug: 'mausoleum', name: 'Mausoleum', original: '54f1128a25be5e8805837491', portraitURL: '/file/db/thang.type/54f1128a25be5e8805837491/portrait.png', kind: 'Doodad'}
    {slug: 'mayhem-background', name: 'Mayhem Background', original: '572e5071e8db519501484896', portraitURL: '/file/db/thang.type/572e5071e8db519501484896/portrait.png', kind: 'Floor'}
    {slug: 'mcp', name: 'mcp', original: '576322da0d81132500afdc8d', portraitURL: '/file/db/thang.type/576322da0d81132500afdc8d/portrait.png', kind: 'Unit'}
    {slug: 'megaphone', name: 'Megaphone', original: '53e216ff53457600003e3eb7', portraitURL: '/file/db/thang.type/53e216ff53457600003e3eb7/portrait.png', kind: 'Item'}
    {slug: 'metal-builders-hammer', name: 'Metal Builder\'s Hammer', original: '54694c79a2b1f53ce794445e', portraitURL: '/file/db/thang.type/54694c79a2b1f53ce794445e/portrait.png', kind: 'Item'}
    {slug: 'moonless-night', name: 'Moonless Night', original: '54692f44a2b1f53ce79443b8', portraitURL: '/file/db/thang.type/54692f44a2b1f53ce79443b8/portrait.png', kind: 'Item'}
    {slug: 'moonlit-blade', name: 'Moonlit Blade', original: '544d95a48494308424f56523', portraitURL: '/file/db/thang.type/544d95a48494308424f56523/portrait.png', kind: 'Item'}
    {slug: 'moonlit-blade-missile', name: 'Moonlit Blade Missile', original: '544d97bc8494308424f5653c', portraitURL: '/file/db/thang.type/544d97bc8494308424f5653c/portrait.png', kind: 'Missile'}
    {slug: 'mornings-edge', name: 'Morning\'s Edge', original: '54eaa69a2b7506e891ca7195', portraitURL: '/file/db/thang.type/54eaa69a2b7506e891ca7195/portrait.png', kind: 'Item'}
    {slug: 'mountain-1', name: 'Mountain 1', original: '54e931d7970f0b0a263c03ef', portraitURL: '/file/db/thang.type/54e931d7970f0b0a263c03ef/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-2', name: 'Mountain 2', original: '54e9340b970f0b0a263c03f3', portraitURL: '/file/db/thang.type/54e9340b970f0b0a263c03f3/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-3', name: 'Mountain 3', original: '54e935d1970f0b0a263c03f7', portraitURL: '/file/db/thang.type/54e935d1970f0b0a263c03f7/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-4', name: 'Mountain 4', original: '54e9377e970f0b0a263c03fc', portraitURL: '/file/db/thang.type/54e9377e970f0b0a263c03fc/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-lake-1', name: 'Mountain Lake 1', original: '54e93f0ef54ef5794f354e99', portraitURL: '/file/db/thang.type/54e93f0ef54ef5794f354e99/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-lake-2', name: 'Mountain Lake 2', original: '54e94106f54ef5794f354ea3', portraitURL: '/file/db/thang.type/54e94106f54ef5794f354ea3/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-shrub-1', name: 'Mountain Shrub 1', original: '54e9567ff54ef5794f354f11', portraitURL: '/file/db/thang.type/54e9567ff54ef5794f354f11/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-shrub-2', name: 'Mountain Shrub 2', original: '54e956b7f54ef5794f354f15', portraitURL: '/file/db/thang.type/54e956b7f54ef5794f354f15/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-shrub-3', name: 'Mountain Shrub 3', original: '54e956def54ef5794f354f19', portraitURL: '/file/db/thang.type/54e956def54ef5794f354f19/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-shrub-4', name: 'Mountain Shrub 4', original: '54e95724f54ef5794f354f1d', portraitURL: '/file/db/thang.type/54e95724f54ef5794f354f1d/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-tree-stand-1', name: 'Mountain Tree Stand 1', original: '55c24e91dfc8d0b576e60a5e', portraitURL: '/file/db/thang.type/55c24e91dfc8d0b576e60a5e/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-tree-stand-2', name: 'Mountain Tree Stand 2', original: '55c25141dfc8d0b576e60a64', portraitURL: '/file/db/thang.type/55c25141dfc8d0b576e60a64/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-tree-stand-3', name: 'Mountain Tree Stand 3', original: '55c25173dfc8d0b576e60a6a', portraitURL: '/file/db/thang.type/55c25173dfc8d0b576e60a6a/portrait.png', kind: 'Doodad'}
    {slug: 'mountain-tree-stand-4', name: 'Mountain Tree Stand 4', original: '55c25190dfc8d0b576e60a70', portraitURL: '/file/db/thang.type/55c25190dfc8d0b576e60a70/portrait.png', kind: 'Doodad'}
    {slug: 'movement-stone', name: 'Movement Stone', original: '546e257a9df4a17d0d449bd9', portraitURL: '/file/db/thang.type/546e257a9df4a17d0d449bd9/portrait.png', kind: 'Doodad'}
    {slug: 'movement-stone-loop', name: 'Movement Stone Loop', original: '546e24679df4a17d0d449bc1', portraitURL: '/file/db/thang.type/546e24679df4a17d0d449bc1/portrait.png', kind: 'Doodad'}
    {slug: 'multiplayer-treasure-grove-background', name: 'Multiplayer Treasure Grove Background', original: '572e526e7a9c3e8101b8be02', portraitURL: '/file/db/thang.type/572e526e7a9c3e8101b8be02/portrait.png', kind: 'Floor'}
    {slug: 'mummy', name: 'Mummy', original: '54ef799c8d75558205e98a8e', portraitURL: '/file/db/thang.type/54ef799c8d75558205e98a8e/portrait.png', kind: 'Doodad'}
    {slug: 'mushroom', name: 'Mushroom', original: '52bcc23a8c4289607b00000a', portraitURL: '/file/db/thang.type/52bcc23a8c4289607b00000a/portrait.png', kind: 'Misc'}
    {slug: 'mushroom-cluster-1', name: 'Mushroom Cluster 1', original: '5576376f1e82182d9e688935', portraitURL: '/file/db/thang.type/5576376f1e82182d9e688935/portrait.png', kind: 'Doodad'}
    {slug: 'mushroom-cluster-2', name: 'Mushroom Cluster 2', original: '557638341e82182d9e688939', portraitURL: '/file/db/thang.type/557638341e82182d9e688939/portrait.png', kind: 'Doodad'}
    {slug: 'mushroom-cluster-3', name: 'Mushroom Cluster 3', original: '557638731e82182d9e68893d', portraitURL: '/file/db/thang.type/557638731e82182d9e68893d/portrait.png', kind: 'Doodad'}
    {slug: 'mushroom-cluster-4', name: 'Mushroom Cluster 4', original: '5576390e1e82182d9e688941', portraitURL: '/file/db/thang.type/5576390e1e82182d9e688941/portrait.png', kind: 'Doodad'}
    {slug: 'musty-linen-robe', name: 'Musty Linen Robe', original: '546d49409df4a17d0d449a83', portraitURL: '/file/db/thang.type/546d49409df4a17d0d449a83/portrait.png', kind: 'Item'}
    {slug: 'newmakatesthushbaum', name: 'newmakatesthushbaum', original: '56ce223647c33f2400d98c66', portraitURL: '/file/db/thang.type/56ce223647c33f2400d98c66/portrait.png', kind: 'undefined'}
    {slug: 'nightingales-song', name: 'Nightingale\'s Song', original: '54eb570b49fa2d5c905ddf32', portraitURL: '/file/db/thang.type/54eb570b49fa2d5c905ddf32/portrait.png', kind: 'Item'}
    {slug: 'north-mounted-camera-facing-east-west', name: 'north mounted camera facing east-west', original: '56f175f2f3ae4cc900a0c5fc', portraitURL: '/file/db/thang.type/56f175f2f3ae4cc900a0c5fc/portrait.png', kind: 'Doodad'}
    {slug: 'north-mounted-camera-facing-north', name: 'north mounted camera facing north', original: '56f173384852efd20059948a', portraitURL: '/file/db/thang.type/56f173384852efd20059948a/portrait.png', kind: 'Doodad'}
    {slug: 'north-mounted-camera-facing-south', name: 'north mounted camera facing south', original: '56f17562f3ae4cc900a0c57a', portraitURL: '/file/db/thang.type/56f17562f3ae4cc900a0c57a/portrait.png', kind: 'Doodad'}
    {slug: 'oak-crossbow', name: 'Oak Crossbow', original: '544d80928494308424f564cb', portraitURL: '/file/db/thang.type/544d80928494308424f564cb/portrait.png', kind: 'Item'}
    {slug: 'oak-sphere-staff', name: 'Oak Sphere Staff', original: '544d88b78494308424f5650d', portraitURL: '/file/db/thang.type/544d88b78494308424f5650d/portrait.png', kind: 'Item'}
    {slug: 'oak-wand', name: 'Oak Wand', original: '544d87d18494308424f564fd', portraitURL: '/file/db/thang.type/544d87d18494308424f564fd/portrait.png', kind: 'Item'}
    {slug: 'oasis-1', name: 'Oasis 1', original: '544d79678494308424f56480', portraitURL: '/file/db/thang.type/544d79678494308424f56480/portrait.png', kind: 'Doodad'}
    {slug: 'oasis-2', name: 'Oasis 2', original: '544d71198494308424f5647c', portraitURL: '/file/db/thang.type/544d71198494308424f5647c/portrait.png', kind: 'Doodad'}
    {slug: 'oasis-3', name: 'Oasis 3', original: '5435d22f7b554def1f99c49a', portraitURL: '/file/db/thang.type/5435d22f7b554def1f99c49a/portrait.png', kind: 'Doodad'}
    {slug: 'obsidian-breastplate', name: 'Obsidian Breastplate', original: '546ab11b3777d6186329286a', portraitURL: '/file/db/thang.type/546ab11b3777d6186329286a/portrait.png', kind: 'Item'}
    {slug: 'obsidian-helmet', name: 'Obsidian Helmet', original: '546d39989df4a17d0d449a13', portraitURL: '/file/db/thang.type/546d39989df4a17d0d449a13/portrait.png', kind: 'Item'}
    {slug: 'obsidian-shield', name: 'Obsidian Shield', original: '54eaba502b7506e891ca7216', portraitURL: '/file/db/thang.type/54eaba502b7506e891ca7216/portrait.png', kind: 'Item'}
    {slug: 'obsidian-staff', name: 'Obsidian Staff', original: '54eab4b92b7506e891ca71ea', portraitURL: '/file/db/thang.type/54eab4b92b7506e891ca71ea/portrait.png', kind: 'Item'}
    {slug: 'obstacle', name: 'Obstacle', original: '52bcc10d1f766a891c000001', portraitURL: '/file/db/thang.type/52bcc10d1f766a891c000001/portrait.png', kind: 'Misc'}
    {slug: 'office-chair', name: 'office-chair', original: '56b25d8cc9d8ed21008354b8', portraitURL: '/file/db/thang.type/56b25d8cc9d8ed21008354b8/portrait.png', kind: 'Doodad'}
    {slug: 'office-desk', name: 'Office Desk', original: '56b26c487168802600d26218', portraitURL: '/file/db/thang.type/56b26c487168802600d26218/portrait.png', kind: 'Doodad'}
    {slug: 'office-door', name: 'Office Door', original: '56ba3366131fde2a000b84db', portraitURL: '/file/db/thang.type/56ba3366131fde2a000b84db/portrait.png', kind: 'Doodad'}
    {slug: 'office-filing-cabinet', name: 'Office Filing Cabinet', original: '56b267eec2958a26005fbb58', portraitURL: '/file/db/thang.type/56b267eec2958a26005fbb58/portrait.png', kind: 'Doodad'}
    {slug: 'office-filing-cabinet-2', name: 'Office Filing Cabinet 2', original: '56b268dd7168802600d25f3d', portraitURL: '/file/db/thang.type/56b268dd7168802600d25f3d/portrait.png', kind: 'Doodad'}
    {slug: 'office-floor', name: 'Office Floor', original: '56b26e39bb550b26003adef0', portraitURL: '/file/db/thang.type/56b26e39bb550b26003adef0/portrait.png', kind: 'Floor'}
    {slug: 'office-wall', name: 'office-wall', original: '56abc26c26c92a26005b3745', portraitURL: '/file/db/thang.type/56abc26c26c92a26005b3745/portrait.png', kind: 'Wall'}
    {slug: 'ogre-barracks', name: 'Ogre Barracks', original: '530d11faa8583eb90a2fc76f', portraitURL: '/file/db/thang.type/530d11faa8583eb90a2fc76f/portrait.png', kind: 'Unit'}
    {slug: 'ogre-fence', name: 'Ogre Fence', original: '5456b5c5d5ada30000525609', portraitURL: '/file/db/thang.type/5456b5c5d5ada30000525609/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-fence-2', name: 'Ogre Fence 2', original: '5456b631d5ada3000052560b', portraitURL: '/file/db/thang.type/5456b631d5ada3000052560b/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-headhunter-hero', name: 'Ogre Headhunter Hero', original: '5670779dfb9b702400cf6987', portraitURL: '/file/db/thang.type/5670779dfb9b702400cf6987/portrait.png', kind: 'Unit'}
    {slug: 'ogre-peon-f', name: 'Ogre Peon F', original: '53765709a7b5ab3805f15512', portraitURL: '/file/db/thang.type/53765709a7b5ab3805f15512/portrait.png', kind: 'Unit'}
    {slug: 'ogre-peon-m', name: 'Ogre Peon M', original: '53793734f883583805e356e2', portraitURL: '/file/db/thang.type/53793734f883583805e356e2/portrait.png', kind: 'Unit'}
    {slug: 'ogre-scout-f', name: 'Ogre Scout F', original: '54909436b30e9eb7027fe21c', portraitURL: '/file/db/thang.type/54909436b30e9eb7027fe21c/portrait.png', kind: 'Unit'}
    {slug: 'ogre-scout-m', name: 'Ogre Scout M', original: '54908ce5b30e9eb7027fe201', portraitURL: '/file/db/thang.type/54908ce5b30e9eb7027fe201/portrait.png', kind: 'Unit'}
    {slug: 'ogre-tent', name: 'Ogre Tent', original: '5456b49dd5ada30000525607', portraitURL: '/file/db/thang.type/5456b49dd5ada30000525607/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-tower', name: 'ogre tower', original: '578686459fabcb1f0087d064', portraitURL: '/file/db/thang.type/578686459fabcb1f0087d064/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-tower-with-desert-rocks', name: 'ogre tower with desert rocks', original: '572d465dab2d38ad00a1c918', portraitURL: '/file/db/thang.type/572d465dab2d38ad00a1c918/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-towers-with-trees', name: 'ogre towers with trees', original: '572d47eee24ce2fb0025c6f3', portraitURL: '/file/db/thang.type/572d47eee24ce2fb0025c6f3/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-treasure-chest', name: 'Ogre Treasure Chest', original: '540e16d6821af8000097dc55', portraitURL: '/file/db/thang.type/540e16d6821af8000097dc55/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-wall', name: 'ogre wall', original: '5786834a2437842400f4009c', portraitURL: '/file/db/thang.type/5786834a2437842400f4009c/portrait.png', kind: 'Doodad'}
    {slug: 'ogre-witch-hero', name: 'Ogre Witch Hero', original: '5638f6c4ef9d6464094a559d', portraitURL: '/file/db/thang.type/5638f6c4ef9d6464094a559d/portrait.png', kind: 'Unit'}
    {slug: 'old-selection', name: 'Old Selection', original: '52aa5f7520fccb0000000002', portraitURL: '/file/db/thang.type/52aa5f7520fccb0000000002/portrait.png', kind: 'Mark'}
    {slug: 'order-of-the-paladin', name: 'Order of the Paladin', original: '54eb55af49fa2d5c905ddf22', portraitURL: '/file/db/thang.type/54eb55af49fa2d5c905ddf22/portrait.png', kind: 'Item'}
    {slug: 'overseer', name: 'Overseer', original: '56e75e0b67a0142000a12699', portraitURL: '/file/db/thang.type/56e75e0b67a0142000a12699/portrait.png', kind: 'Unit'}
    {slug: 'painted-steel-breastplate', name: 'Painted Steel Breastplate', original: '546ab0dd3777d61863292866', portraitURL: '/file/db/thang.type/546ab0dd3777d61863292866/portrait.png', kind: 'Item'}
    {slug: 'painted-steel-helmet', name: 'Painted Steel Helmet', original: '546d39589df4a17d0d449a0f', portraitURL: '/file/db/thang.type/546d39589df4a17d0d449a0f/portrait.png', kind: 'Item'}
    {slug: 'painted-steel-shield', name: 'Painted Steel Shield', original: '544d7c5b8494308424f5649b', portraitURL: '/file/db/thang.type/544d7c5b8494308424f5649b/portrait.png', kind: 'Item'}
    {slug: 'palisade', name: 'Palisade', original: '546e24bd9df4a17d0d449bc9', portraitURL: '/file/db/thang.type/546e24bd9df4a17d0d449bc9/portrait.png', kind: 'Doodad'}
    {slug: 'paralyze', name: 'Paralyze', original: '53024e6b222f73867774d773', portraitURL: '/file/db/thang.type/53024e6b222f73867774d773/portrait.png', kind: 'Mark'}
    {slug: 'pedestal', name: 'Pedestal', original: '542ae4750048dcb95727a1e6', portraitURL: '/file/db/thang.type/542ae4750048dcb95727a1e6/portrait.png', kind: 'Doodad'}
    {slug: 'phoenixfire', name: 'Phoenixfire', original: '54ea8b602b7506e891ca718d', portraitURL: '/file/db/thang.type/54ea8b602b7506e891ca718d/portrait.png', kind: 'Item'}
    {slug: 'plasma-ball', name: 'Plasma Ball', original: '5589fe594bed1b6c2a2cab6b', portraitURL: '/file/db/thang.type/5589fe594bed1b6c2a2cab6b/portrait.png', kind: 'Missile'}
    {slug: 'poison', name: 'Poison', original: '53024020222f73867774d619', portraitURL: '/file/db/thang.type/53024020222f73867774d619/portrait.png', kind: 'Mark'}
    {slug: 'poisoned-throwing-shard-missile', name: 'Poisoned Throwing Shard Missile', original: '544d97088494308424f56539', portraitURL: '/file/db/thang.type/544d97088494308424f56539/portrait.png', kind: 'Missile'}
    {slug: 'polar-bear-cub-pet', name: 'Polar Bear Cub pet', original: '57588d4b87b06e1f00ded849', portraitURL: '/file/db/thang.type/57588d4b87b06e1f00ded849/portrait.png', kind: 'Unit'}
    {slug: 'polished-agate-sense-stone', name: 'Polished Agate Sense Stone', original: '54693274a2b1f53ce79443c9', portraitURL: '/file/db/thang.type/54693274a2b1f53ce79443c9/portrait.png', kind: 'Item'}
    {slug: 'polished-bronze-breastplate', name: 'Polished Bronze Breastplate', original: '545d3f0b2d03e700001b5a5d', portraitURL: '/file/db/thang.type/545d3f0b2d03e700001b5a5d/portrait.png', kind: 'Item'}
    {slug: 'polished-bronze-helmet', name: 'Polished Bronze Helmet', original: '546d38779df4a17d0d449a03', portraitURL: '/file/db/thang.type/546d38779df4a17d0d449a03/portrait.png', kind: 'Item'}
    {slug: 'polished-bronze-shield', name: 'Polished Bronze Shield', original: '544d7a888494308424f56487', portraitURL: '/file/db/thang.type/544d7a888494308424f56487/portrait.png', kind: 'Item'}
    {slug: 'polished-emerald-sense-stone', name: 'Polished Emerald Sense Stone', original: '546933dda2b1f53ce79443d9', portraitURL: '/file/db/thang.type/546933dda2b1f53ce79443d9/portrait.png', kind: 'Item'}
    {slug: 'polished-sense-stone', name: 'Polished Sense Stone', original: '53e215a253457600003e3eaf', portraitURL: '/file/db/thang.type/53e215a253457600003e3eaf/portrait.png', kind: 'Item'}
    {slug: 'polished-steel-scale-chainmail-coif', name: 'Polished Steel Scale Chainmail Coif', original: '546d46889df4a17d0d449a5f', portraitURL: '/file/db/thang.type/546d46889df4a17d0d449a5f/portrait.png', kind: 'Item'}
    {slug: 'polished-steel-scale-chainmail-tunic', name: 'Polished Steel Scale Chainmail Tunic', original: '546d3c3f9df4a17d0d449a37', portraitURL: '/file/db/thang.type/546d3c3f9df4a17d0d449a37/portrait.png', kind: 'Item'}
    {slug: 'pot-1', name: 'Pot 1', original: '54ef882f83b08b7d054b6d49', portraitURL: '/file/db/thang.type/54ef882f83b08b7d054b6d49/portrait.png', kind: 'Doodad'}
    {slug: 'pot-2', name: 'Pot 2', original: '54ef89dc4bb4788505d21234', portraitURL: '/file/db/thang.type/54ef89dc4bb4788505d21234/portrait.png', kind: 'Doodad'}
    {slug: 'pot-3', name: 'Pot 3', original: '54ef8b1f305d7e790557d5d5', portraitURL: '/file/db/thang.type/54ef8b1f305d7e790557d5d5/portrait.png', kind: 'Doodad'}
    {slug: 'pot-4', name: 'Pot 4', original: '54ef8becace2147e05868483', portraitURL: '/file/db/thang.type/54ef8becace2147e05868483/portrait.png', kind: 'Doodad'}
    {slug: 'potion-belt', name: 'Potion Belt', original: '54694ac4a2b1f53ce794443d', portraitURL: '/file/db/thang.type/54694ac4a2b1f53ce794443d/portrait.png', kind: 'Item'}
    {slug: 'potted-tree', name: 'Potted Tree', original: '56b2c8baf2ea182100d8ce78', portraitURL: '/file/db/thang.type/56b2c8baf2ea182100d8ce78/portrait.png', kind: 'Doodad'}
    {slug: 'powder-charge', name: 'Powder Charge', original: '5462952cf44055a4b5e73599', portraitURL: '/file/db/thang.type/5462952cf44055a4b5e73599/portrait.png', kind: 'Item'}
    {slug: 'powder-charge-missile', name: 'Powder Charge Missile', original: '544d99328494308424f56540', portraitURL: '/file/db/thang.type/544d99328494308424f56540/portrait.png', kind: 'Missile'}
    {slug: 'power-up', name: 'Power Up', original: '55c64140ef141c65665beb6b', portraitURL: '/file/db/thang.type/55c64140ef141c65665beb6b/portrait.png', kind: 'Mark'}
    {slug: 'power-up-2', name: 'Power Up 2', original: '55c6419fef141c65665beb6f', portraitURL: '/file/db/thang.type/55c6419fef141c65665beb6f/portrait.png', kind: 'Mark'}
    {slug: 'precision-rifle', name: 'Precision Rifle', original: '54eaaecc2b7506e891ca71d9', portraitURL: '/file/db/thang.type/54eaaecc2b7506e891ca71d9/portrait.png', kind: 'Item'}
    {slug: 'programmaticon-i', name: 'Programmaticon I', original: '53e4108204c00d4607a89f78', portraitURL: '/file/db/thang.type/53e4108204c00d4607a89f78/portrait.png', kind: 'Item'}
    {slug: 'programmaticon-ii', name: 'Programmaticon II', original: '546e25d99df4a17d0d449be1', portraitURL: '/file/db/thang.type/546e25d99df4a17d0d449be1/portrait.png', kind: 'Item'}
    {slug: 'programmaticon-iii', name: 'Programmaticon III', original: '546e266e9df4a17d0d449be5', portraitURL: '/file/db/thang.type/546e266e9df4a17d0d449be5/portrait.png', kind: 'Item'}
    {slug: 'programmaticon-iv', name: 'Programmaticon IV', original: '55240951f76d6ee949f66512', portraitURL: '/file/db/thang.type/55240951f76d6ee949f66512/portrait.png', kind: 'Item'}
    {slug: 'programmaticon-v', name: 'Programmaticon V', original: '557871261ff17fef5abee3ee', portraitURL: '/file/db/thang.type/557871261ff17fef5abee3ee/portrait.png', kind: 'Item'}
    {slug: 'pugicorn-pet', name: 'Pugicorn Pet', original: '577d5edcab818b210046b73c', portraitURL: '/file/db/thang.type/577d5edcab818b210046b73c/portrait.png', kind: 'Unit'}
    {slug: 'pushcart', name: 'Pushcart', original: '54f119a6d2969f8405ef539f', portraitURL: '/file/db/thang.type/54f119a6d2969f8405ef539f/portrait.png', kind: 'Doodad'}
    {slug: 'quartz-sense-stone', name: 'Quartz Sense Stone', original: '54693240a2b1f53ce79443c5', portraitURL: '/file/db/thang.type/54693240a2b1f53ce79443c5/portrait.png', kind: 'Item'}
    {slug: 'ragged-silk-hat', name: 'Ragged Silk Hat', original: '546d4ba19df4a17d0d449aaf', portraitURL: '/file/db/thang.type/546d4ba19df4a17d0d449aaf/portrait.png', kind: 'Item'}
    {slug: 'railgun', name: 'Railgun', original: '54ea8ea52b7506e891ca7191', portraitURL: '/file/db/thang.type/54ea8ea52b7506e891ca7191/portrait.png', kind: 'Item'}
    {slug: 'rapidfire-rifle', name: 'Rapidfire Rifle', original: '54eaae422b7506e891ca71d5', portraitURL: '/file/db/thang.type/54eaae422b7506e891ca71d5/portrait.png', kind: 'Item'}
    {slug: 'rat', name: 'Rat', original: '55c11b70c87e47c60604f974', portraitURL: '/file/db/thang.type/55c11b70c87e47c60604f974/portrait.png', kind: 'Doodad'}
    {slug: 'razor-ring', name: 'Razor Ring', original: '54c97c9bdef3ad363ff998b7', portraitURL: '/file/db/thang.type/54c97c9bdef3ad363ff998b7/portrait.png', kind: 'Missile'}
    {slug: 'razordisc-missile', name: 'Razordisc Missile', original: '5318d3e56ad8999d34bdf338', portraitURL: '/file/db/thang.type/5318d3e56ad8999d34bdf338/portrait.png', kind: 'Missile'}
    {slug: 'rectangle', name: 'Rectangle', original: '568d915e1717e2f90e9a1250', portraitURL: '/file/db/thang.type/568d915e1717e2f90e9a1250/portrait.png', kind: 'Misc'}
    {slug: 'red-button', name: 'Red Button', original: '56d102c0441ddd2f002ba760', portraitURL: '/file/db/thang.type/56d102c0441ddd2f002ba760/portrait.png', kind: 'Doodad'}
    {slug: 'regen', name: 'Regen', original: '53024f8b27471514685d53e1', portraitURL: '/file/db/thang.type/53024f8b27471514685d53e1/portrait.png', kind: 'Mark'}
    {slug: 'reindeer', name: 'Reindeer', original: '54e95a88f54ef5794f354f3d', portraitURL: '/file/db/thang.type/54e95a88f54ef5794f354f3d/portrait.png', kind: 'Doodad'}
    {slug: 'reinforced-boots', name: 'Reinforced Boots', original: '546d4d259df4a17d0d449ac5', portraitURL: '/file/db/thang.type/546d4d259df4a17d0d449ac5/portrait.png', kind: 'Item'}
    {slug: 'reinforced-crossbow', name: 'Reinforced Crossbow', original: '54eaacdd2b7506e891ca71cd', portraitURL: '/file/db/thang.type/54eaacdd2b7506e891ca71cd/portrait.png', kind: 'Item'}
    {slug: 'reinforced-iron-chainmail-coif', name: 'Reinforced Iron Chainmail Coif', original: '546d46099df4a17d0d449a57', portraitURL: '/file/db/thang.type/546d46099df4a17d0d449a57/portrait.png', kind: 'Item'}
    {slug: 'reinforced-iron-chainmail-tunic', name: 'Reinforced Iron Chainmail Tunic', original: '546d3bbb9df4a17d0d449a2f', portraitURL: '/file/db/thang.type/546d3bbb9df4a17d0d449a2f/portrait.png', kind: 'Item'}
    {slug: 'repair', name: 'Repair', original: '52bcc4591f766a891c000003', portraitURL: '/file/db/thang.type/52bcc4591f766a891c000003/portrait.png', kind: 'Mark'}
    {slug: 'ring-of-developer-experimentation', name: 'Ring of Developer Experimentation', original: '54bac99bacbf5aea089da177', portraitURL: '/file/db/thang.type/54bac99bacbf5aea089da177/portrait.png', kind: 'Item'}
    {slug: 'ring-of-earth', name: 'Ring of Earth', original: '5441c35c4e9aeb727cc9711d', portraitURL: '/file/db/thang.type/5441c35c4e9aeb727cc9711d/portrait.png', kind: 'Item'}
    {slug: 'ring-of-fire', name: 'Ring of Fire', original: '54692ea2a2b1f53ce79443ab', portraitURL: '/file/db/thang.type/54692ea2a2b1f53ce79443ab/portrait.png', kind: 'Item'}
    {slug: 'ring-of-flowers', name: 'Ring of Flowers', original: '5523224b0676ecb7d5c89319', portraitURL: '/file/db/thang.type/5523224b0676ecb7d5c89319/portrait.png', kind: 'Item'}
    {slug: 'ring-of-ice', name: 'Ring of Ice', original: '54692ed3a2b1f53ce79443af', portraitURL: '/file/db/thang.type/54692ed3a2b1f53ce79443af/portrait.png', kind: 'Item'}
    {slug: 'ring-of-speed', name: 'Ring of Speed', original: '54692d2aa2b1f53ce794438f', portraitURL: '/file/db/thang.type/54692d2aa2b1f53ce794438f/portrait.png', kind: 'Item'}
    {slug: 'riveted-dragonscale-chainmail-coif', name: 'Riveted Dragonscale Chainmail Coif', original: '546d47c09df4a17d0d449a6f', portraitURL: '/file/db/thang.type/546d47c09df4a17d0d449a6f/portrait.png', kind: 'Item'}
    {slug: 'riveted-dragonscale-chainmail-tunic', name: 'Riveted Dragonscale Chainmail Tunic', original: '546d3d549df4a17d0d449a47', portraitURL: '/file/db/thang.type/546d3d549df4a17d0d449a47/portrait.png', kind: 'Item'}
    {slug: 'robe-of-the-magi', name: 'Robe of the Magi', original: '54ea3ec22b7506e891ca7126', portraitURL: '/file/db/thang.type/54ea3ec22b7506e891ca7126/portrait.png', kind: 'Item'}
    {slug: 'robobomb', name: 'Robobomb', original: '55b7fb22a337d9b0ea024bb4', portraitURL: '/file/db/thang.type/55b7fb22a337d9b0ea024bb4/portrait.png', kind: 'Unit'}
    {slug: 'robot-walker', name: 'Robot Walker', original: '5301696ad82649ec2c0c9b0d', portraitURL: '/file/db/thang.type/5301696ad82649ec2c0c9b0d/portrait.png', kind: 'Unit'}
    {slug: 'rock-1', name: 'Rock 1', original: '52afcc1fc5b1813ec2000010', portraitURL: '/file/db/thang.type/52afcc1fc5b1813ec2000010/portrait.png', kind: 'Doodad'}
    {slug: 'rock-2', name: 'Rock 2', original: '52afcce4c5b1813ec2000012', portraitURL: '/file/db/thang.type/52afcce4c5b1813ec2000012/portrait.png', kind: 'Doodad'}
    {slug: 'rock-3', name: 'Rock 3', original: '52afcd43c5b1813ec2000014', portraitURL: '/file/db/thang.type/52afcd43c5b1813ec2000014/portrait.png', kind: 'Doodad'}
    {slug: 'rock-4', name: 'Rock 4', original: '52afcd7bc5b1813ec2000016', portraitURL: '/file/db/thang.type/52afcd7bc5b1813ec2000016/portrait.png', kind: 'Doodad'}
    {slug: 'rock-5', name: 'Rock 5', original: '52afcdc7c5b1813ec2000018', portraitURL: '/file/db/thang.type/52afcdc7c5b1813ec2000018/portrait.png', kind: 'Doodad'}
    {slug: 'rock-6', name: 'Rock 6', original: '54e95916f54ef5794f354f2d', portraitURL: '/file/db/thang.type/54e95916f54ef5794f354f2d/portrait.png', kind: 'Doodad'}
    {slug: 'rock-7', name: 'Rock 7', original: '54e959d6f54ef5794f354f31', portraitURL: '/file/db/thang.type/54e959d6f54ef5794f354f31/portrait.png', kind: 'Doodad'}
    {slug: 'rock-8', name: 'Rock 8', original: '54e95a10f54ef5794f354f35', portraitURL: '/file/db/thang.type/54e95a10f54ef5794f354f35/portrait.png', kind: 'Doodad'}
    {slug: 'rock-cluster-1', name: 'Rock Cluster 1', original: '52afcb47c5b1813ec200000a', portraitURL: '/file/db/thang.type/52afcb47c5b1813ec200000a/portrait.png', kind: 'Doodad'}
    {slug: 'rock-cluster-2', name: 'Rock Cluster 2', original: '52afcb98c5b1813ec200000c', portraitURL: '/file/db/thang.type/52afcb98c5b1813ec200000c/portrait.png', kind: 'Doodad'}
    {slug: 'rock-cluster-3', name: 'Rock Cluster 3', original: '52afcbe0c5b1813ec200000e', portraitURL: '/file/db/thang.type/52afcbe0c5b1813ec200000e/portrait.png', kind: 'Doodad'}
    {slug: 'rock-field-1', name: 'Rock Field 1', original: '54e95753f54ef5794f354f21', portraitURL: '/file/db/thang.type/54e95753f54ef5794f354f21/portrait.png', kind: 'Doodad'}
    {slug: 'rock-field-2', name: 'Rock Field 2', original: '54e95861f54ef5794f354f25', portraitURL: '/file/db/thang.type/54e95861f54ef5794f354f25/portrait.png', kind: 'Doodad'}
    {slug: 'rock-field-3', name: 'Rock Field 3', original: '54e958aaf54ef5794f354f29', portraitURL: '/file/db/thang.type/54e958aaf54ef5794f354f29/portrait.png', kind: 'Doodad'}
    {slug: 'root', name: 'Root', original: '55c640feef141c65665beb67', portraitURL: '/file/db/thang.type/55c640feef141c65665beb67/portrait.png', kind: 'Mark'}
    {slug: 'rough-sense-stone', name: 'Rough Sense Stone', original: '54693140a2b1f53ce79443bc', portraitURL: '/file/db/thang.type/54693140a2b1f53ce79443bc/portrait.png', kind: 'Item'}
    {slug: 'roughedge', name: 'Roughedge', original: '544d7d918494308424f564a7', portraitURL: '/file/db/thang.type/544d7d918494308424f564a7/portrait.png', kind: 'Item'}
    {slug: 'rs-demo', name: 'RS Demo', original: '56ce48892438c720001e3ca3', portraitURL: '/file/db/thang.type/56ce48892438c720001e3ca3/portrait.png', kind: 'undefined'}
    {slug: 'runesword', name: 'Runesword', original: '54eaa9622b7506e891ca71b1', portraitURL: '/file/db/thang.type/54eaa9622b7506e891ca71b1/portrait.png', kind: 'Item'}
    {slug: 'rusted-iron-breastplate', name: 'Rusted Iron Breastplate', original: '545d3fe42d03e700001b5a5f', portraitURL: '/file/db/thang.type/545d3fe42d03e700001b5a5f/portrait.png', kind: 'Item'}
    {slug: 'rusted-iron-helmet', name: 'Rusted Iron Helmet', original: '546d38d09df4a17d0d449a07', portraitURL: '/file/db/thang.type/546d38d09df4a17d0d449a07/portrait.png', kind: 'Item'}
    {slug: 'rusted-steel-scale-chainmail-coif', name: 'Rusted Steel Scale Chainmail Coif', original: '546d46419df4a17d0d449a5b', portraitURL: '/file/db/thang.type/546d46419df4a17d0d449a5b/portrait.png', kind: 'Item'}
    {slug: 'rusted-steel-scale-chainmail-tunic', name: 'Rusted Steel Scale Chainmail Tunic', original: '546d3bf99df4a17d0d449a33', portraitURL: '/file/db/thang.type/546d3bf99df4a17d0d449a33/portrait.png', kind: 'Item'}
    {slug: 'sand-01', name: 'Sand 01', original: '5484df79d7b7b862291456af', portraitURL: '/file/db/thang.type/5484df79d7b7b862291456af/portrait.png', kind: 'Floor'}
    {slug: 'sand-02', name: 'Sand 02', original: '5484e7c5d7b7b862291456b3', portraitURL: '/file/db/thang.type/5484e7c5d7b7b862291456b3/portrait.png', kind: 'Floor'}
    {slug: 'sand-03', name: 'Sand 03', original: '5484e81bd7b7b862291456b7', portraitURL: '/file/db/thang.type/5484e81bd7b7b862291456b7/portrait.png', kind: 'Floor'}
    {slug: 'sand-04', name: 'Sand 04', original: '5484e857d7b7b862291456bb', portraitURL: '/file/db/thang.type/5484e857d7b7b862291456bb/portrait.png', kind: 'Floor'}
    {slug: 'sand-05', name: 'Sand 05', original: '5484e89cd7b7b862291456bf', portraitURL: '/file/db/thang.type/5484e89cd7b7b862291456bf/portrait.png', kind: 'Floor'}
    {slug: 'sand-06', name: 'Sand 06', original: '5484e8ddd7b7b862291456c3', portraitURL: '/file/db/thang.type/5484e8ddd7b7b862291456c3/portrait.png', kind: 'Floor'}
    {slug: 'sand-yak', name: 'Sand Yak', original: '5480b2251bf0b10000711c51', portraitURL: '/file/db/thang.type/5480b2251bf0b10000711c51/portrait.png', kind: 'Unit'}
    {slug: 'sapphire-sense-stone', name: 'Sapphire Sense Stone', original: '54693363a2b1f53ce79443d1', portraitURL: '/file/db/thang.type/54693363a2b1f53ce79443d1/portrait.png', kind: 'Item'}
    {slug: 'sarcophagus', name: 'sarcophagus', original: '572d5a2d3ff46db2000a381b', portraitURL: '/file/db/thang.type/572d5a2d3ff46db2000a381b/portrait.png', kind: 'Doodad'}
    {slug: 'scaled-gloves', name: 'Scaled Gloves', original: '5469496ca2b1f53ce794442d', portraitURL: '/file/db/thang.type/5469496ca2b1f53ce794442d/portrait.png', kind: 'Item'}
    {slug: 'school-locker', name: 'School locker', original: '56eb14804eb67a25009be23e', portraitURL: '/file/db/thang.type/56eb14804eb67a25009be23e/portrait.png', kind: 'Doodad'}
    {slug: 'scoreboard', name: 'Scoreboard', original: '56de0ff26f9cc02400831e06', portraitURL: '/file/db/thang.type/56de0ff26f9cc02400831e06/portrait.png', kind: 'Doodad'}
    {slug: 'scorpion', name: 'Scorpion', original: '548cf5340f559d0000be7e5b', portraitURL: '/file/db/thang.type/548cf5340f559d0000be7e5b/portrait.png', kind: 'Doodad'}
    {slug: 'selection', name: 'Selection', original: '546e23d49df4a17d0d449bb5', portraitURL: '/file/db/thang.type/546e23d49df4a17d0d449bb5/portrait.png', kind: 'Misc'}
    {slug: 'shadow-guard-background', name: 'Shadow Guard Background', original: '55bfc4c950cac5d58def9a67', portraitURL: '/file/db/thang.type/55bfc4c950cac5d58def9a67/portrait.png', kind: 'Floor'}
    {slug: 'shadowless-bird', name: 'Shadowless Bird', original: '55079c55cea461db22519e9d', portraitURL: '/file/db/thang.type/55079c55cea461db22519e9d/portrait.png', kind: 'Doodad'}
    {slug: 'shadowless-cloud-1', name: 'Shadowless Cloud 1', original: '53e2df9cd12e873205b6bce8', portraitURL: '/file/db/thang.type/53e2df9cd12e873205b6bce8/portrait.png', kind: 'Doodad'}
    {slug: 'shadowless-cloud-2', name: 'Shadowless Cloud 2', original: '53e2e0176c59f5340504102f', portraitURL: '/file/db/thang.type/53e2e0176c59f5340504102f/portrait.png', kind: 'Doodad'}
    {slug: 'shadowless-cloud-3', name: 'Shadowless Cloud 3', original: '53e2e08eae44ec37059f2148', portraitURL: '/file/db/thang.type/53e2e08eae44ec37059f2148/portrait.png', kind: 'Doodad'}
    {slug: 'sharpened-sword', name: 'Sharpened Sword', original: '544d7deb8494308424f564ab', portraitURL: '/file/db/thang.type/544d7deb8494308424f564ab/portrait.png', kind: 'Item'}
    {slug: 'sharpsong', name: 'Sharpsong', original: '544d95c78494308424f56527', portraitURL: '/file/db/thang.type/544d95c78494308424f56527/portrait.png', kind: 'Item'}
    {slug: 'sharpsong-missile', name: 'Sharpsong Missile', original: '544d98368494308424f5653e', portraitURL: '/file/db/thang.type/544d98368494308424f5653e/portrait.png', kind: 'Missile'}
    {slug: 'shell', name: 'Shell', original: '52ba2c6c981fbb7e48000093', portraitURL: '/file/db/thang.type/52ba2c6c981fbb7e48000093/portrait.png', kind: 'Missile'}
    {slug: 'shield', name: 'Shield', original: '573fa531d0bee72000a4255f', portraitURL: '/file/db/thang.type/573fa531d0bee72000a4255f/portrait.png', kind: 'Mark'}
    {slug: 'short-sword', name: 'Short Sword', original: '544d7f1a8494308424f564b7', portraitURL: '/file/db/thang.type/544d7f1a8494308424f564b7/portrait.png', kind: 'Item'}
    {slug: 'shrub-1', name: 'Shrub 1', original: '52b0a113ccbc671372000017', portraitURL: '/file/db/thang.type/52b0a113ccbc671372000017/portrait.png', kind: 'Doodad'}
    {slug: 'shrub-2', name: 'Shrub 2', original: '52b0a15accbc671372000019', portraitURL: '/file/db/thang.type/52b0a15accbc671372000019/portrait.png', kind: 'Doodad'}
    {slug: 'shrub-3', name: 'Shrub 3', original: '52b0a1a3ccbc67137200001b', portraitURL: '/file/db/thang.type/52b0a1a3ccbc67137200001b/portrait.png', kind: 'Doodad'}
    {slug: 'sign', name: 'Sign', original: '5435cbe77b554def1f99c491', portraitURL: '/file/db/thang.type/5435cbe77b554def1f99c491/portrait.png', kind: 'Doodad'}
    {slug: 'silver-coin', name: 'Silver Coin', original: '535ef1f64f10444d08486b61', portraitURL: '/file/db/thang.type/535ef1f64f10444d08486b61/portrait.png', kind: 'Misc'}
    {slug: 'simple-boots', name: 'Simple Boots', original: '53e237bf53457600003e3f05', portraitURL: '/file/db/thang.type/53e237bf53457600003e3f05/portrait.png', kind: 'Item'}
    {slug: 'simple-katana', name: 'Simple Katana', original: '544d7ed58494308424f564b3', portraitURL: '/file/db/thang.type/544d7ed58494308424f564b3/portrait.png', kind: 'Item'}
    {slug: 'simple-rifle', name: 'Simple Rifle', original: '544d70a18494308424f5647a', portraitURL: '/file/db/thang.type/544d70a18494308424f5647a/portrait.png', kind: 'Item'}
    {slug: 'simple-sword', name: 'Simple Sword', original: '53e218d853457600003e3ebe', portraitURL: '/file/db/thang.type/53e218d853457600003e3ebe/portrait.png', kind: 'Item'}
    {slug: 'simple-wand', name: 'Simple Wand', original: '544d874f8494308424f564f5', portraitURL: '/file/db/thang.type/544d874f8494308424f564f5/portrait.png', kind: 'Item'}
    {slug: 'simple-wristwatch', name: 'Simple Wristwatch', original: '54693797a2b1f53ce79443e9', portraitURL: '/file/db/thang.type/54693797a2b1f53ce79443e9/portrait.png', kind: 'Item'}
    {slug: 'skeleton-bits-1', name: 'Skeleton Bits 1', original: '54ef85bdc1f3bd7c0593d125', portraitURL: '/file/db/thang.type/54ef85bdc1f3bd7c0593d125/portrait.png', kind: 'Doodad'}
    {slug: 'skeleton-bits-2', name: 'Skeleton Bits 2', original: '54ef874370ff9c8005e1eb0d', portraitURL: '/file/db/thang.type/54ef874370ff9c8005e1eb0d/portrait.png', kind: 'Doodad'}
    {slug: 'sky-span-background-1', name: 'Sky Span Background 1', original: '53e3f096ae44ec37059f92d8', portraitURL: '/file/db/thang.type/53e3f096ae44ec37059f92d8/portrait.png', kind: 'Floor'}
    {slug: 'sky-span-background-2', name: 'Sky Span Background 2', original: '53e3f3556c59f5340504359e', portraitURL: '/file/db/thang.type/53e3f3556c59f5340504359e/portrait.png', kind: 'Floor'}
    {slug: 'sky-span-background-3', name: 'Sky Span Background 3', original: '53e3f500ae44ec37059f9415', portraitURL: '/file/db/thang.type/53e3f500ae44ec37059f9415/portrait.png', kind: 'Doodad'}
    {slug: 'sky-span-background-4', name: 'Sky Span Background 4', original: '53e3f5dbae44ec37059f944a', portraitURL: '/file/db/thang.type/53e3f5dbae44ec37059f944a/portrait.png', kind: 'Doodad'}
    {slug: 'sky-span-background-5', name: 'Sky Span Background 5', original: '53e3f646d12e873205b72abd', portraitURL: '/file/db/thang.type/53e3f646d12e873205b72abd/portrait.png', kind: 'Floor'}
    {slug: 'sky-span-background-6', name: 'Sky Span Background 6', original: '53e3f724d12e873205b72af9', portraitURL: '/file/db/thang.type/53e3f724d12e873205b72af9/portrait.png', kind: 'Floor'}
    {slug: 'sky-span-background-7', name: 'Sky Span Background 7', original: '53e3f74dae44ec37059f94b3', portraitURL: '/file/db/thang.type/53e3f74dae44ec37059f94b3/portrait.png', kind: 'Doodad'}
    {slug: 'sleep', name: 'Sleep', original: '5302504b222f73867774d7a1', portraitURL: '/file/db/thang.type/5302504b222f73867774d7a1/portrait.png', kind: 'Mark'}
    {slug: 'slow', name: 'Slow', original: '5302511327471514685d5405', portraitURL: '/file/db/thang.type/5302511327471514685d5405/portrait.png', kind: 'Mark'}
    {slug: 'snake', name: 'Snake', original: '548cf57c0f559d0000be7e5f', portraitURL: '/file/db/thang.type/548cf57c0f559d0000be7e5f/portrait.png', kind: 'Doodad'}
    {slug: 'snake-pillar', name: 'Snake Pillar', original: '54ef8db1223edd8105aff2b9', portraitURL: '/file/db/thang.type/54ef8db1223edd8105aff2b9/portrait.png', kind: 'Doodad'}
    {slug: 'soft-leather-gloves', name: 'Soft Leather Gloves', original: '546948e9a2b1f53ce7944425', portraitURL: '/file/db/thang.type/546948e9a2b1f53ce7944425/portrait.png', kind: 'Item'}
    {slug: 'softened-leather-boots', name: 'Softened Leather Boots', original: '546d4d589df4a17d0d449ac9', portraitURL: '/file/db/thang.type/546d4d589df4a17d0d449ac9/portrait.png', kind: 'Item'}
    {slug: 'sparkbomb', name: 'Sparkbomb', original: '54eb528449fa2d5c905ddf12', portraitURL: '/file/db/thang.type/54eb528449fa2d5c905ddf12/portrait.png', kind: 'Item'}
    {slug: 'sparkbomb-missile', name: 'Sparkbomb Missile', original: '5535b3bd428ddac5686fcf7a', portraitURL: '/file/db/thang.type/5535b3bd428ddac5686fcf7a/portrait.png', kind: 'Missile'}
    {slug: 'spear', name: 'Spear', original: '52ba2affd68e4b7c48000030', portraitURL: '/file/db/thang.type/52ba2affd68e4b7c48000030/portrait.png', kind: 'Missile'}
    {slug: 'spider', name: 'Spider', original: '55c1353bc87e47c60604f997', portraitURL: '/file/db/thang.type/55c1353bc87e47c60604f997/portrait.png', kind: 'Doodad'}
    {slug: 'spiderweb-1', name: 'Spiderweb 1', original: '54ef7c69223edd8105afc1f4', portraitURL: '/file/db/thang.type/54ef7c69223edd8105afc1f4/portrait.png', kind: 'Doodad'}
    {slug: 'spiderweb-2', name: 'Spiderweb 2', original: '54ef7d41ace2147e058655a8', portraitURL: '/file/db/thang.type/54ef7d41ace2147e058655a8/portrait.png', kind: 'Doodad'}
    {slug: 'spiderweb-3', name: 'Spiderweb 3', original: '54ef7ed7b4740779058410c9', portraitURL: '/file/db/thang.type/54ef7ed7b4740779058410c9/portrait.png', kind: 'Doodad'}
    {slug: 'spiderweb-4', name: 'Spiderweb 4', original: '54ef8938ace2147e05867d6d', portraitURL: '/file/db/thang.type/54ef8938ace2147e05867d6d/portrait.png', kind: 'Doodad'}
    {slug: 'spike-walls', name: 'Spike Walls', original: '5422f63718adb78d98d265f7', portraitURL: '/file/db/thang.type/5422f63718adb78d98d265f7/portrait.png', kind: 'Doodad'}
    {slug: 'spiked-ogre-wall', name: 'spiked ogre wall', original: '578682dccca8994b002708eb', portraitURL: '/file/db/thang.type/578682dccca8994b002708eb/portrait.png', kind: 'Doodad'}
    {slug: 'stalactite-1', name: 'Stalactite 1', original: '55760f0a1e82182d9e688912', portraitURL: '/file/db/thang.type/55760f0a1e82182d9e688912/portrait.png', kind: 'Doodad'}
    {slug: 'stalactite-2', name: 'Stalactite 2', original: '55760f4a1e82182d9e688916', portraitURL: '/file/db/thang.type/55760f4a1e82182d9e688916/portrait.png', kind: 'Doodad'}
    {slug: 'stalactite-3', name: 'Stalactite 3', original: '55760f6f1e82182d9e68891a', portraitURL: '/file/db/thang.type/55760f6f1e82182d9e68891a/portrait.png', kind: 'Doodad'}
    {slug: 'stalagmite-1', name: 'Stalagmite 1', original: '55760e6f1e82182d9e688906', portraitURL: '/file/db/thang.type/55760e6f1e82182d9e688906/portrait.png', kind: 'Doodad'}
    {slug: 'stalagmite-2', name: 'Stalagmite 2', original: '55760eb61e82182d9e68890a', portraitURL: '/file/db/thang.type/55760eb61e82182d9e68890a/portrait.png', kind: 'Doodad'}
    {slug: 'stalagmite-3', name: 'Stalagmite 3', original: '55760ee51e82182d9e68890e', portraitURL: '/file/db/thang.type/55760ee51e82182d9e68890e/portrait.png', kind: 'Doodad'}
    {slug: 'statue-stone-hooded', name: 'Statue Stone Hooded', original: '546e23469df4a17d0d449ba9', portraitURL: '/file/db/thang.type/546e23469df4a17d0d449ba9/portrait.png', kind: 'Doodad'}
    {slug: 'steel-breastplate', name: 'Steel Breastplate', original: '546ab0a83777d61863292862', portraitURL: '/file/db/thang.type/546ab0a83777d61863292862/portrait.png', kind: 'Item'}
    {slug: 'steel-helmet', name: 'Steel Helmet', original: '5441c2ed4e9aeb727cc9710b', portraitURL: '/file/db/thang.type/5441c2ed4e9aeb727cc9710b/portrait.png', kind: 'Item'}
    {slug: 'steel-ring', name: 'Steel Ring', original: '54692dbca2b1f53ce794439b', portraitURL: '/file/db/thang.type/54692dbca2b1f53ce794439b/portrait.png', kind: 'Item'}
    {slug: 'steel-shield', name: 'Steel Shield', original: '544d7bec8494308424f56497', portraitURL: '/file/db/thang.type/544d7bec8494308424f56497/portrait.png', kind: 'Item'}
    {slug: 'steel-striker', name: 'Steel Striker', original: '544d7c948494308424f5649f', portraitURL: '/file/db/thang.type/544d7c948494308424f5649f/portrait.png', kind: 'Item'}
    {slug: 'steel-wand', name: 'Steel Wand', original: '544d88e48494308424f56511', portraitURL: '/file/db/thang.type/544d88e48494308424f56511/portrait.png', kind: 'Item'}
    {slug: 'stiff-lambswool-hat', name: 'Stiff Lambswool Hat', original: '546d4b379df4a17d0d449aa7', portraitURL: '/file/db/thang.type/546d4b379df4a17d0d449aa7/portrait.png', kind: 'Item'}
    {slug: 'stone-builders-hammer', name: 'Stone Builder\'s Hammer', original: '54694bcca2b1f53ce7944451', portraitURL: '/file/db/thang.type/54694bcca2b1f53ce7944451/portrait.png', kind: 'Item'}
    {slug: 'stone-fall-1', name: 'Stone Fall 1', original: '53e2e5046f406a3505b3ead6', portraitURL: '/file/db/thang.type/53e2e5046f406a3505b3ead6/portrait.png', kind: 'Doodad'}
    {slug: 'stone-fall-2', name: 'Stone Fall 2', original: '53e2e66d6c59f534050410d0', portraitURL: '/file/db/thang.type/53e2e66d6c59f534050410d0/portrait.png', kind: 'Doodad'}
    {slug: 'stone-fall-3', name: 'Stone Fall 3', original: '53e2e728ae44ec37059f2438', portraitURL: '/file/db/thang.type/53e2e728ae44ec37059f2438/portrait.png', kind: 'Doodad'}
    {slug: 'stone-pillars', name: 'stone pillars', original: '572d5958f5da8e29013e4e8d', portraitURL: '/file/db/thang.type/572d5958f5da8e29013e4e8d/portrait.png', kind: 'Doodad'}
    {slug: 'stone-statue', name: 'Stone Statue', original: '546e25479df4a17d0d449bd5', portraitURL: '/file/db/thang.type/546e25479df4a17d0d449bd5/portrait.png', kind: 'Doodad'}
    {slug: 'stormbringer', name: 'Stormbringer', original: '54ea87342b7506e891ca7175', portraitURL: '/file/db/thang.type/54ea87342b7506e891ca7175/portrait.png', kind: 'Item'}
    {slug: 'stretched-hide', name: 'Stretched Hide', original: '557608901e82182d9e6888ce', portraitURL: '/file/db/thang.type/557608901e82182d9e6888ce/portrait.png', kind: 'Doodad'}
    {slug: 'student-a', name: 'Student A', original: '56d0edd0441ddd2f002ba5aa', portraitURL: '/file/db/thang.type/56d0edd0441ddd2f002ba5aa/portrait.png', kind: 'Unit'}
    {slug: 'student-b', name: 'Student B', original: '56d0efc14292981f009f51de', portraitURL: '/file/db/thang.type/56d0efc14292981f009f51de/portrait.png', kind: 'Unit'}
    {slug: 'stump-1', name: 'Stump 1', original: '54e955f6f54ef5794f354f09', portraitURL: '/file/db/thang.type/54e955f6f54ef5794f354f09/portrait.png', kind: 'Doodad'}
    {slug: 'stump-2', name: 'Stump 2', original: '54e95634f54ef5794f354f0d', portraitURL: '/file/db/thang.type/54e95634f54ef5794f354f0d/portrait.png', kind: 'Doodad'}
    {slug: 'stump-3', name: 'Stump 3', original: '557f91f9b43ce0b15a91b1cd', portraitURL: '/file/db/thang.type/557f91f9b43ce0b15a91b1cd/portrait.png', kind: 'Doodad'}
    {slug: 'stump-4', name: 'Stump 4', original: '557f923eb43ce0b15a91b1d1', portraitURL: '/file/db/thang.type/557f923eb43ce0b15a91b1d1/portrait.png', kind: 'Doodad'}
    {slug: 'stump-5', name: 'Stump 5', original: '557f925ab43ce0b15a91b1d5', portraitURL: '/file/db/thang.type/557f925ab43ce0b15a91b1d5/portrait.png', kind: 'Doodad'}
    {slug: 'sturdy-bronze-shield', name: 'Sturdy Bronze Shield', original: '544d7b028494308424f5648b', portraitURL: '/file/db/thang.type/544d7b028494308424f5648b/portrait.png', kind: 'Item'}
    {slug: 'sulphur-staff', name: 'Sulphur Staff', original: '54eab7132b7506e891ca71fa', portraitURL: '/file/db/thang.type/54eab7132b7506e891ca71fa/portrait.png', kind: 'Item'}
    {slug: 'sundial-wristwatch', name: 'Sundial Wristwatch', original: '53e2396a53457600003e3f0f', portraitURL: '/file/db/thang.type/53e2396a53457600003e3f0f/portrait.png', kind: 'Item'}
    {slug: 'sword', name: 'Sword', original: '52bcda141f766a891c00000a', portraitURL: '/file/db/thang.type/52bcda141f766a891c00000a/portrait.png', kind: 'Misc'}
    {slug: 'sword-belt', name: 'Sword Belt', original: '5441beb74e9aeb727cc970d3', portraitURL: '/file/db/thang.type/5441beb74e9aeb727cc970d3/portrait.png', kind: 'Item'}
    {slug: 'sword-fall-1', name: 'Sword Fall 1', original: '53e2e8a7d12e873205b6c0f1', portraitURL: '/file/db/thang.type/53e2e8a7d12e873205b6c0f1/portrait.png', kind: 'Doodad'}
    {slug: 'sword-fall-2', name: 'Sword Fall 2', original: '53e2e9a9ae44ec37059f2571', portraitURL: '/file/db/thang.type/53e2e9a9ae44ec37059f2571/portrait.png', kind: 'Doodad'}
    {slug: 'sword-of-the-forgotten', name: 'Sword of the Forgotten', original: '54eaaa522b7506e891ca71b9', portraitURL: '/file/db/thang.type/54eaaa522b7506e891ca71b9/portrait.png', kind: 'Item'}
    {slug: 'sword-of-the-temple-guard', name: 'Sword of the Temple Guard', original: '54eaab372b7506e891ca71c1', portraitURL: '/file/db/thang.type/54eaab372b7506e891ca71c1/portrait.png', kind: 'Item'}
    {slug: 'table', name: 'Table', original: '52e9987a427172ae56001ffd', portraitURL: '/file/db/thang.type/52e9987a427172ae56001ffd/portrait.png', kind: 'Doodad'}
    {slug: 'tailored-linen-robe', name: 'Tailored Linen Robe', original: '546d49759df4a17d0d449a87', portraitURL: '/file/db/thang.type/546d49759df4a17d0d449a87/portrait.png', kind: 'Item'}
    {slug: 'talus-1', name: 'Talus 1', original: '54e944a3f54ef5794f354ea9', portraitURL: '/file/db/thang.type/54e944a3f54ef5794f354ea9/portrait.png', kind: 'Floor'}
    {slug: 'talus-2', name: 'Talus 2', original: '54e94880f54ef5794f354ead', portraitURL: '/file/db/thang.type/54e94880f54ef5794f354ead/portrait.png', kind: 'Floor'}
    {slug: 'talus-3', name: 'Talus 3', original: '54e948daf54ef5794f354eb1', portraitURL: '/file/db/thang.type/54e948daf54ef5794f354eb1/portrait.png', kind: 'Floor'}
    {slug: 'talus-4', name: 'Talus 4', original: '54e94908f54ef5794f354eb5', portraitURL: '/file/db/thang.type/54e94908f54ef5794f354eb5/portrait.png', kind: 'Floor'}
    {slug: 'talus-5', name: 'Talus 5', original: '54e9493cf54ef5794f354eb9', portraitURL: '/file/db/thang.type/54e9493cf54ef5794f354eb9/portrait.png', kind: 'Floor'}
    {slug: 'talus-6', name: 'Talus 6', original: '54e94965f54ef5794f354ebd', portraitURL: '/file/db/thang.type/54e94965f54ef5794f354ebd/portrait.png', kind: 'Floor'}
    {slug: 'tarnished-bronze-breastplate', name: 'Tarnished Bronze Breastplate', original: '53e22eac53457600003e3efc', portraitURL: '/file/db/thang.type/53e22eac53457600003e3efc/portrait.png', kind: 'Item'}
    {slug: 'tarnished-bronze-helmet', name: 'Tarnished Bronze Helmet', original: '546d38269df4a17d0d4499ff', portraitURL: '/file/db/thang.type/546d38269df4a17d0d4499ff/portrait.png', kind: 'Item'}
    {slug: 'tarnished-copper-band', name: 'Tarnished Copper Band', original: '54692a75a2b1f53ce7944387', portraitURL: '/file/db/thang.type/54692a75a2b1f53ce7944387/portrait.png', kind: 'Item'}
    {slug: 'tauran-helm', name: 'Tauran Helm', original: '54ea49982b7506e891ca7165', portraitURL: '/file/db/thang.type/54ea49982b7506e891ca7165/portrait.png', kind: 'Item'}
    {slug: 'tauran-plate', name: 'Tauran Plate', original: '54ea4b302b7506e891ca716d', portraitURL: '/file/db/thang.type/54ea4b302b7506e891ca716d/portrait.png', kind: 'Item'}
    {slug: 'teacher-b', name: 'Teacher B', original: '56de0554d048927700b4f741', portraitURL: '/file/db/thang.type/56de0554d048927700b4f741/portrait.png', kind: 'Doodad'}
    {slug: 'tent-1', name: 'Tent 1', original: '548cf2280f559d0000be7e37', portraitURL: '/file/db/thang.type/548cf2280f559d0000be7e37/portrait.png', kind: 'Doodad'}
    {slug: 'tent-2', name: 'Tent 2', original: '548cf2b10f559d0000be7e3b', portraitURL: '/file/db/thang.type/548cf2b10f559d0000be7e3b/portrait.png', kind: 'Doodad'}
    {slug: 'tent-3', name: 'Tent 3', original: '548cf30b0f559d0000be7e3f', portraitURL: '/file/db/thang.type/548cf30b0f559d0000be7e3f/portrait.png', kind: 'Doodad'}
    {slug: 'the-final-kithmaze-background', name: 'the final kithmaze background', original: '577ecc2b67053f25007eb916', portraitURL: '/file/db/thang.type/577ecc2b67053f25007eb916/portrait.png', kind: 'Floor'}
    {slug: 'the-gauntlet-background', name: 'The Gauntlet Background', original: '572d631812f2abce00164c15', portraitURL: '/file/db/thang.type/572d631812f2abce00164c15/portrait.png', kind: 'Floor'}
    {slug: 'the-monolith', name: 'The Monolith', original: '54eabcb72b7506e891ca7226', portraitURL: '/file/db/thang.type/54eabcb72b7506e891ca7226/portrait.png', kind: 'Item'}
    {slug: 'the-precious', name: 'The Precious', original: '54eb56ae49fa2d5c905ddf2a', portraitURL: '/file/db/thang.type/54eb56ae49fa2d5c905ddf2a/portrait.png', kind: 'Item'}
    {slug: 'thick-burlap-robe', name: 'Thick Burlap Robe', original: '546d48989df4a17d0d449a77', portraitURL: '/file/db/thang.type/546d48989df4a17d0d449a77/portrait.png', kind: 'Item'}
    {slug: 'thin-burlap-robe', name: 'Thin Burlap Robe', original: '546d485b9df4a17d0d449a73', portraitURL: '/file/db/thang.type/546d485b9df4a17d0d449a73/portrait.png', kind: 'Item'}
    {slug: 'thoktars-discarded-hammer', name: 'Thoktar\'s Discarded Hammer', original: '54694cd6a2b1f53ce7944466', portraitURL: '/file/db/thang.type/54694cd6a2b1f53ce7944466/portrait.png', kind: 'Item'}
    {slug: 'thornprick', name: 'Thornprick', original: '54692e75a2b1f53ce79443a7', portraitURL: '/file/db/thang.type/54692e75a2b1f53ce79443a7/portrait.png', kind: 'Item'}
    {slug: 'threadbare-burlap-wizards-hat', name: 'Threadbare Burlap Wizards Hat', original: '546d4a909df4a17d0d449a9b', portraitURL: '/file/db/thang.type/546d4a909df4a17d0d449a9b/portrait.png', kind: 'Item'}
    {slug: 'throne', name: 'Throne', original: '54efa174933e1e7b05846fe6', portraitURL: '/file/db/thang.type/54efa174933e1e7b05846fe6/portrait.png', kind: 'Doodad'}
    {slug: 'tomb-ring', name: 'Tomb Ring', original: '54eb55d849fa2d5c905ddf26', portraitURL: '/file/db/thang.type/54eb55d849fa2d5c905ddf26/portrait.png', kind: 'Item'}
    {slug: 'tool-belt', name: 'Tool Belt', original: '5441beff4e9aeb727cc970d9', portraitURL: '/file/db/thang.type/5441beff4e9aeb727cc970d9/portrait.png', kind: 'Item'}
    {slug: 'torch', name: 'Torch', original: '52aa608b20fccb0000000005', portraitURL: '/file/db/thang.type/52aa608b20fccb0000000005/portrait.png', kind: 'Doodad'}
    {slug: 'torn-silk-cloak', name: 'Torn Silk Cloak', original: '546d49a79df4a17d0d449a8b', portraitURL: '/file/db/thang.type/546d49a79df4a17d0d449a8b/portrait.png', kind: 'Item'}
    {slug: 'torture-table', name: 'Torture Table', original: '54ef8fd4b474077905843564', portraitURL: '/file/db/thang.type/54ef8fd4b474077905843564/portrait.png', kind: 'Doodad'}
    {slug: 'tower-ruined', name: 'Tower Ruined', original: '54f117c548724e7d052b540b', portraitURL: '/file/db/thang.type/54f117c548724e7d052b540b/portrait.png', kind: 'Doodad'}
    {slug: 'training-dummy', name: 'Training Dummy', original: '53e65923bc5cc012113e07b1', portraitURL: '/file/db/thang.type/53e65923bc5cc012113e07b1/portrait.png', kind: 'Doodad'}
    {slug: 'trap-belt', name: 'Trap Belt', original: '54694a8fa2b1f53ce7944439', portraitURL: '/file/db/thang.type/54694a8fa2b1f53ce7944439/portrait.png', kind: 'Item'}
    {slug: 'treasure-chest', name: 'Treasure Chest', original: '52aa3be0ccbd588d4d000005', portraitURL: '/file/db/thang.type/52aa3be0ccbd588d4d000005/portrait.png', kind: 'Doodad'}
    {slug: 'tree-1', name: 'Tree 1', original: '52b09ef7ccbc67137200000f', portraitURL: '/file/db/thang.type/52b09ef7ccbc67137200000f/portrait.png', kind: 'Doodad'}
    {slug: 'tree-2', name: 'Tree 2', original: '52b09fdeccbc671372000011', portraitURL: '/file/db/thang.type/52b09fdeccbc671372000011/portrait.png', kind: 'Doodad'}
    {slug: 'tree-3', name: 'Tree 3', original: '52b0a04fccbc671372000013', portraitURL: '/file/db/thang.type/52b0a04fccbc671372000013/portrait.png', kind: 'Doodad'}
    {slug: 'tree-4', name: 'Tree 4', original: '52b0a0a5ccbc671372000015', portraitURL: '/file/db/thang.type/52b0a0a5ccbc671372000015/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-1', name: 'Tree Stand 1', original: '541cc7c48e78524aad94de7d', portraitURL: '/file/db/thang.type/541cc7c48e78524aad94de7d/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-2', name: 'Tree Stand 2', original: '542068f38e78524aad94de83', portraitURL: '/file/db/thang.type/542068f38e78524aad94de83/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-3', name: 'Tree Stand 3', original: '5420693d8e78524aad94de89', portraitURL: '/file/db/thang.type/5420693d8e78524aad94de89/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-4', name: 'Tree Stand 4', original: '542069888e78524aad94de8f', portraitURL: '/file/db/thang.type/542069888e78524aad94de8f/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-5', name: 'Tree Stand 5', original: '542092628e78524aad94deca', portraitURL: '/file/db/thang.type/542092628e78524aad94deca/portrait.png', kind: 'Doodad'}
    {slug: 'tree-stand-6', name: 'Tree Stand 6', original: '542092c38e78524aad94ded0', portraitURL: '/file/db/thang.type/542092c38e78524aad94ded0/portrait.png', kind: 'Doodad'}
    {slug: 'true-names-background', name: 'True Names Background', original: '55e451bd206f7df7df6ba966', portraitURL: '/file/db/thang.type/55e451bd206f7df7df6ba966/portrait.png', kind: 'Floor'}
    {slug: 'twilight-glasses', name: 'Twilight Glasses', original: '546941fda2b1f53ce794441d', portraitURL: '/file/db/thang.type/546941fda2b1f53ce794441d/portrait.png', kind: 'Item'}
    {slug: 'twisted-pine-wand', name: 'Twisted Pine Wand', original: '544d877d8494308424f564f9', portraitURL: '/file/db/thang.type/544d877d8494308424f564f9/portrait.png', kind: 'Item'}
    {slug: 'undead', name: 'Undead', original: '55c284933767fd3435eb4471', portraitURL: '/file/db/thang.type/55c284933767fd3435eb4471/portrait.png', kind: 'Mark'}
    {slug: 'undergrowth-dagger', name: 'Undergrowth Dagger', original: '544d95e68494308424f5652b', portraitURL: '/file/db/thang.type/544d95e68494308424f5652b/portrait.png', kind: 'Item'}
    {slug: 'undergrowth-dagger-missile', name: 'Undergrowth Dagger Missile', original: '544d99618494308424f56541', portraitURL: '/file/db/thang.type/544d99618494308424f56541/portrait.png', kind: 'Missile'}
    {slug: 'undying-ring', name: 'Undying Ring', original: '54eb54d349fa2d5c905ddf1e', portraitURL: '/file/db/thang.type/54eb54d349fa2d5c905ddf1e/portrait.png', kind: 'Item'}
    {slug: 'unholy-tome-i', name: 'Unholy Tome I', original: '546374bc3839c6e02811d308', portraitURL: '/file/db/thang.type/546374bc3839c6e02811d308/portrait.png', kind: 'Item'}
    {slug: 'unholy-tome-ii', name: 'Unholy Tome II', original: '5463756f3839c6e02811d30c', portraitURL: '/file/db/thang.type/5463756f3839c6e02811d30c/portrait.png', kind: 'Item'}
    {slug: 'unholy-tome-iii', name: 'Unholy Tome III', original: '5463758f3839c6e02811d30f', portraitURL: '/file/db/thang.type/5463758f3839c6e02811d30f/portrait.png', kind: 'Item'}
    {slug: 'unholy-tome-iv', name: 'Unholy Tome IV', original: '546376b63839c6e02811d31b', portraitURL: '/file/db/thang.type/546376b63839c6e02811d31b/portrait.png', kind: 'Item'}
    {slug: 'unholy-tome-v', name: 'Unholy Tome V', original: '546376da3839c6e02811d31e', portraitURL: '/file/db/thang.type/546376da3839c6e02811d31e/portrait.png', kind: 'Item'}
    {slug: 'viking-helmet', name: 'Viking Helmet', original: '5441c3144e9aeb727cc97111', portraitURL: '/file/db/thang.type/5441c3144e9aeb727cc97111/portrait.png', kind: 'Item'}
    {slug: 'viking-helmet-doodad', name: 'Viking Helmet Doodad', original: '5518239d1f12482609b44f76', portraitURL: '/file/db/thang.type/5518239d1f12482609b44f76/portrait.png', kind: 'Doodad'}
    {slug: 'vine-staff', name: 'Vine Staff', original: '54eab92b2b7506e891ca720a', portraitURL: '/file/db/thang.type/54eab92b2b7506e891ca720a/portrait.png', kind: 'Item'}
    {slug: 'volcano', name: 'Volcano', original: '55c64512ef141c65665beb7e', portraitURL: '/file/db/thang.type/55c64512ef141c65665beb7e/portrait.png', kind: 'Doodad'}
    {slug: 'vr-artist', name: 'VR Artist', original: '56d0c6bf087ee32400763d49', portraitURL: '/file/db/thang.type/56d0c6bf087ee32400763d49/portrait.png', kind: 'Unit'}
    {slug: 'vr-breaker', name: 'VR Breaker', original: '56d0e6e563103d2a00af5795', portraitURL: '/file/db/thang.type/56d0e6e563103d2a00af5795/portrait.png', kind: 'Unit'}
    {slug: 'vr-door', name: 'VR Door', original: '56aa6bf503ec4e2000878867', portraitURL: '/file/db/thang.type/56aa6bf503ec4e2000878867/portrait.png', kind: 'Doodad'}
    {slug: 'vr-floor', name: 'VR Floor', original: '56a2e305b0b7242000e9986e', portraitURL: '/file/db/thang.type/56a2e305b0b7242000e9986e/portrait.png', kind: 'Floor'}
    {slug: 'vr-oracle', name: 'VR Oracle', original: '56d0d144a7daf22000023a13', portraitURL: '/file/db/thang.type/56d0d144a7daf22000023a13/portrait.png', kind: 'Unit'}
    {slug: 'vr-security', name: 'VR Security', original: '56d758b787781b1f00cf4b20', portraitURL: '/file/db/thang.type/56d758b787781b1f00cf4b20/portrait.png', kind: 'Unit'}
    {slug: 'vr-tinker', name: 'VR Tinker', original: '56d07d682a1e1736005b1b37', portraitURL: '/file/db/thang.type/56d07d682a1e1736005b1b37/portrait.png', kind: 'Unit'}
    {slug: 'vr-wall', name: 'vr-wall', original: '56b0c75302b7db290079b542', portraitURL: '/file/db/thang.type/56b0c75302b7db290079b542/portrait.png', kind: 'Wall'}
    {slug: 'vr-wyrm', name: 'VR Wyrm', original: '56bb944d203af82000b2a406', portraitURL: '/file/db/thang.type/56bb944d203af82000b2a406/portrait.png', kind: 'Unit'}
    {slug: 'wagon-broken', name: 'Wagon Broken', original: '548cf1cd0f559d0000be7e33', portraitURL: '/file/db/thang.type/548cf1cd0f559d0000be7e33/portrait.png', kind: 'Doodad'}
    {slug: 'wakka-maul-background', name: 'Wakka Maul Background', original: '5654eae2f9285e86053f7504', portraitURL: '/file/db/thang.type/5654eae2f9285e86053f7504/portrait.png', kind: 'Floor'}
    {slug: 'warcry', name: 'Warcry', original: '53024777222f73867774d6cd', portraitURL: '/file/db/thang.type/53024777222f73867774d6cd/portrait.png', kind: 'Mark'}
    {slug: 'waterfall', name: 'Waterfall', original: '53e2eaffae44ec37059f262a', portraitURL: '/file/db/thang.type/53e2eaffae44ec37059f262a/portrait.png', kind: 'Doodad'}
    {slug: 'weak-charge', name: 'Weak Charge', original: '544d957d8494308424f5651f', portraitURL: '/file/db/thang.type/544d957d8494308424f5651f/portrait.png', kind: 'Item'}
    {slug: 'weak-charge-missile', name: 'Weak Charge Missile', original: '544d97798494308424f5653b', portraitURL: '/file/db/thang.type/544d97798494308424f5653b/portrait.png', kind: 'Missile'}
    {slug: 'weighted-throwing-knives', name: 'Weighted Throwing Knives', original: '544d96108494308424f5652f', portraitURL: '/file/db/thang.type/544d96108494308424f5652f/portrait.png', kind: 'Item'}
    {slug: 'weighted-throwing-knives-missile', name: 'Weighted Throwing Knives Missile', original: '544d99b98494308424f56545', portraitURL: '/file/db/thang.type/544d99b98494308424f56545/portrait.png', kind: 'Missile'}
    {slug: 'well', name: 'Well', original: '52b094cbccbc671372000004', portraitURL: '/file/db/thang.type/52b094cbccbc671372000004/portrait.png', kind: 'Doodad'}
    {slug: 'white-deerhide-gloves', name: 'White Deerhide Gloves', original: '54694936a2b1f53ce7944429', portraitURL: '/file/db/thang.type/54694936a2b1f53ce7944429/portrait.png', kind: 'Item'}
    {slug: 'windwalker-coif', name: 'Windwalker Coif', original: '54ea48512b7506e891ca7157', portraitURL: '/file/db/thang.type/54ea48512b7506e891ca7157/portrait.png', kind: 'Item'}
    {slug: 'windwalker-mail', name: 'Windwalker Mail', original: '54ea46092b7506e891ca7143', portraitURL: '/file/db/thang.type/54ea46092b7506e891ca7143/portrait.png', kind: 'Item'}
    {slug: 'winged-boots', name: 'Winged Boots', original: '546d4e5c9df4a17d0d449ad9', portraitURL: '/file/db/thang.type/546d4e5c9df4a17d0d449ad9/portrait.png', kind: 'Item'}
    {slug: 'wizard-bird-f', name: 'Wizard Bird F', original: '52fc0c9e7e01835453bd8ef8', portraitURL: '/file/db/thang.type/52fc0c9e7e01835453bd8ef8/portrait.png', kind: 'Unit'}
    {slug: 'wizard-bird-m', name: 'Wizard Bird M', original: '52fd015f3a58c6c50fcf4782', portraitURL: '/file/db/thang.type/52fd015f3a58c6c50fcf4782/portrait.png', kind: 'Unit'}
    {slug: 'wizard-doctor', name: 'Wizard Doctor', original: '52fc04fbab6e45c813bc7ced', portraitURL: '/file/db/thang.type/52fc04fbab6e45c813bc7ced/portrait.png', kind: 'Unit'}
    {slug: 'wizard-dude', name: 'Wizard Dude', original: '53e126a4e06b897606d38bef', portraitURL: '/file/db/thang.type/53e126a4e06b897606d38bef/portrait.png', kind: 'Unit'}
    {slug: 'wizard-hermes', name: 'Wizard Hermes', original: '52fc09daab6e45c813bc7d52', portraitURL: '/file/db/thang.type/52fc09daab6e45c813bc7d52/portrait.png', kind: 'Unit'}
    {slug: 'wizard-knight', name: 'Wizard Knight', original: '52fc00ffab6e45c813bc7cb2', portraitURL: '/file/db/thang.type/52fc00ffab6e45c813bc7cb2/portrait.png', kind: 'Unit'}
    {slug: 'wizard-ninja-m', name: 'Wizard Ninja M', original: '52fd04aff0cd954d619a9a4c', portraitURL: '/file/db/thang.type/52fd04aff0cd954d619a9a4c/portrait.png', kind: 'Unit'}
    {slug: 'wizard-overseer-f', name: 'Wizard Overseer F', original: '52fc11fbb2b91c0d5a7b6a14', portraitURL: '/file/db/thang.type/52fc11fbb2b91c0d5a7b6a14/portrait.png', kind: 'Unit'}
    {slug: 'wizard-overseer-m', name: 'Wizard Overseer M', original: '52fd0728ccb2653821eaf8b0', portraitURL: '/file/db/thang.type/52fd0728ccb2653821eaf8b0/portrait.png', kind: 'Unit'}
    {slug: 'wizard-purple', name: 'Wizard Purple', original: '52fd0e16c7e6cf99160e7b6a', portraitURL: '/file/db/thang.type/52fd0e16c7e6cf99160e7b6a/portrait.png', kind: 'Unit'}
    {slug: 'wizard-spine', name: 'Wizard Spine', original: '52fcfed63a58c6c50fcf4732', portraitURL: '/file/db/thang.type/52fcfed63a58c6c50fcf4732/portrait.png', kind: 'Unit'}
    {slug: 'wizard-spine-m', name: 'Wizard Spine M', original: '52fd0c70f0cd954d619a9b10', portraitURL: '/file/db/thang.type/52fd0c70f0cd954d619a9b10/portrait.png', kind: 'Unit'}
    {slug: 'wizard-thorn-f', name: 'Wizard Thorn F', original: '52fc1460b2b91c0d5a7b6af3', portraitURL: '/file/db/thang.type/52fc1460b2b91c0d5a7b6af3/portrait.png', kind: 'Unit'}
    {slug: 'wizard-thorn-m', name: 'Wizard Thorn M', original: '52fd0a40f0cd954d619a9ad7', portraitURL: '/file/db/thang.type/52fd0a40f0cd954d619a9ad7/portrait.png', kind: 'Unit'}
    {slug: 'wizard-top-hat', name: 'Wizard Top Hat', original: '52fd124accb2653821eaf991', portraitURL: '/file/db/thang.type/52fd124accb2653821eaf991/portrait.png', kind: 'Unit'}
    {slug: 'wooden-builders-hammer', name: 'Wooden Builder\'s Hammer', original: '54694ba3a2b1f53ce794444d', portraitURL: '/file/db/thang.type/54694ba3a2b1f53ce794444d/portrait.png', kind: 'Item'}
    {slug: 'wooden-glasses', name: 'Wooden Glasses', original: '53e2167653457600003e3eb3', portraitURL: '/file/db/thang.type/53e2167653457600003e3eb3/portrait.png', kind: 'Item'}
    {slug: 'wooden-shield', name: 'Wooden Shield', original: '53e22aa153457600003e3ef5', portraitURL: '/file/db/thang.type/53e22aa153457600003e3ef5/portrait.png', kind: 'Item'}
    {slug: 'wooden-strand', name: 'Wooden Strand', original: '54692e3ea2b1f53ce79443a3', portraitURL: '/file/db/thang.type/54692e3ea2b1f53ce79443a3/portrait.png', kind: 'Item'}
    {slug: 'workers-gloves', name: 'Worker\'s Gloves', original: '5469425ca2b1f53ce7944421', portraitURL: '/file/db/thang.type/5469425ca2b1f53ce7944421/portrait.png', kind: 'Item'}
    {slug: 'worn-dragonplate', name: 'Worn Dragonplate', original: '546ab1a13777d61863292872', portraitURL: '/file/db/thang.type/546ab1a13777d61863292872/portrait.png', kind: 'Item'}
    {slug: 'worn-dragonplate-helmet', name: 'Worn Dragonplate Helmet', original: '546d3a199df4a17d0d449a1b', portraitURL: '/file/db/thang.type/546d3a199df4a17d0d449a1b/portrait.png', kind: 'Item'}
    {slug: 'worn-dragonshield', name: 'Worn Dragonshield', original: '54eabd662b7506e891ca722e', portraitURL: '/file/db/thang.type/54eabd662b7506e891ca722e/portrait.png', kind: 'Item'}
    {slug: 'wyrm2', name: 'wyrm2', original: '56c32fd1807b9f36005e5fd0', portraitURL: '/file/db/thang.type/56c32fd1807b9f36005e5fd0/portrait.png', kind: 'Unit'}
    {slug: 'wyvernclaw', name: 'Wyvernclaw', original: '54ea35fd2b7506e891ca70d5', portraitURL: '/file/db/thang.type/54ea35fd2b7506e891ca70d5/portrait.png', kind: 'Item'}
    {slug: 'x-mark-bones', name: 'X Mark Bones', original: '54938352e9850ae3e8fbdd64', portraitURL: '/file/db/thang.type/54938352e9850ae3e8fbdd64/portrait.png', kind: 'Doodad'}
    {slug: 'x-mark-forest', name: 'X Mark Forest', original: '549381a7e9850ae3e8fbdd60', portraitURL: '/file/db/thang.type/549381a7e9850ae3e8fbdd60/portrait.png', kind: 'Doodad'}
    {slug: 'x-mark-red', name: 'X Mark Red', original: '5493844be9850ae3e8fbdd70', portraitURL: '/file/db/thang.type/5493844be9850ae3e8fbdd70/portrait.png', kind: 'Doodad'}
    {slug: 'x-mark-stone', name: 'X Mark Stone', original: '549383aae9850ae3e8fbdd68', portraitURL: '/file/db/thang.type/549383aae9850ae3e8fbdd68/portrait.png', kind: 'Doodad'}
    {slug: 'x-mark-wood', name: 'X Mark Wood', original: '54938408e9850ae3e8fbdd6c', portraitURL: '/file/db/thang.type/54938408e9850ae3e8fbdd6c/portrait.png', kind: 'Doodad'}
    {slug: 'x-marker', name: 'X Marker', original: '5452ec9f06a59e000067e518', portraitURL: '/file/db/thang.type/5452ec9f06a59e000067e518/portrait.png', kind: 'Doodad'}
    {slug: 'x-ray-goggles', name: 'X-Ray Goggles', original: '53e2392453457600003e3f0d', portraitURL: '/file/db/thang.type/53e2392453457600003e3f0d/portrait.png', kind: 'Item'}
    {slug: 'yeti', name: 'Yeti', original: '54e91dc5970f0b0a263c03de', portraitURL: '/file/db/thang.type/54e91dc5970f0b0a263c03de/portrait.png', kind: 'Unit'}
    {slug: 'yeti-cave', name: 'Yeti Cave', original: '557f8f84b43ce0b15a91b1c7', portraitURL: '/file/db/thang.type/557f8f84b43ce0b15a91b1c7/portrait.png', kind: 'Doodad'}
    {slug: 'yeti-skin', name: 'Yeti Skin', original: '557f370ab43ce0b15a91b171', portraitURL: '/file/db/thang.type/557f370ab43ce0b15a91b171/portrait.png', kind: 'Doodad'}
  ]
