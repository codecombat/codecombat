ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/archmage'
ContactModal = require 'views/core/ContactModal'

module.exports = class ArchmageView extends ContributeClassView
  id: 'archmage-view'
  template: template

  events:
    'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal'

  initialize: ->
    @contributorClassName = 'archmage'

  openContactModal: (e) ->
    e.stopPropagation()
    @openModalView new ContactModal()

  contributors: [
    {id: '547acbb2af18b03c0563fdb3', name: 'David Liu', github: 'trotod'}
    {id: '52ccfc9bd3eb6b5a4100b60d', name: 'Glen De Cauwsemaecker', github: 'GlenDC'}
    {id: '52bfc3ecb7ec628868001297', name: 'Tom Steinbrecher', github: 'TomSteinbrecher'}
    {id: '5272806093680c5817033f73', name: 'Sébastien Moratinos', github: 'smoratinos'}
    {id: '52d133893dc46cbe15001179', name: 'Deepak Raj', github: 'deepak1556'}
    {id: '52699df70e404d591b000af7', name: 'Ronnie Cheng', github: 'rhc2104'}
    {id: '5260b4c3ae8ec6795e000019', name: 'Chloe Fan', github: 'chloester'}
    {id: '52d726ab3c70cec90c008f2d', name: 'Rachel Xiang', github: 'rdxiang'}
    {id: '5286706d93df39a952001574', name: 'Dan Ristic', github: 'dristic'}
    {id: '52cec8620b0d5c1b4c0039e6', name: 'Brad Dickason', github: 'bdickason'}
    {id: '540397e2bc5b69a40e9c2fb1', name: 'Rebecca Saines'}
    {id: '525ae40248839d81090013f2', name: 'Laura Watiker', github: 'lwatiker'}
    {id: '540395e9fe56769115d7da86', name: 'Shiying Zheng', github: 'shiyingzheng'}
    {id: '5403964dfe56769115d7da96', name: 'Mischa Lewis-Norelle', github: 'mlewisno'}
    {id: '52b8be459e47006b4100094b', name: 'Paul Buser'}
    {id: '540396effe56769115d7daa8', name: 'Benjamin Stern'}
    {id: '5403974b11058b4213074779', name: 'Alex Cotsarelis'}
    {id: '54039780fe56769115d7dab5', name: 'Ken Stanley'}
    {id: '531258b5e0789d4609614110', name: 'Ruben Vereecken', github: 'rubenvereecken'}
    {id: '5276ad5dcf83207a2801d3b4', name: 'Zach Martin', github: 'zachster01'}
    {id: '530df0cbc06854403ba67c15', name: 'Alexandru Caciulescu', github: 'Darredevil'}
    {id: '5268d9baa39d7db617000b18', name: 'Thanish Muhammed', github: 'mnmtanish'}
    {id: '53232f458e54704b074b271d', name: 'Bang Honam', github: 'walkingtospace'}
    {id: '52d16c1dc931e2544d001daa', name: 'David Pendray', github: 'dpen2000'}
    {id: '53132ea1828a1706108ebb38', name: 'Dominik Kundel'}
    {id: '530eb29347a891b3518b3990', name: 'Ian Li'}
    {id: '531cd81dd00d2dc30991f924', name: 'Russ Fan'}
    {id: '53064b1905a6ad967346e654', name: 'Yang Shun'}
    {name: 'devast8a', avatar: '', github: 'devast8a'}
  ]
