ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/artisan'
{me} = require 'core/auth'

module.exports = class ArtisanView extends ContributeClassView
  id: 'artisan-view'
  template: template

  initialize: ->
    @contributorClassName = 'artisan'

  contributors: [
    {id: '5276ad5dcf83207a2801d3b4', name: 'Zach Martin', github: 'zachster01'}
    {id: '530df0cbc06854403ba67c15', name: 'Alexandru Caciulescu', github: 'Darredevil'}
    {id: '54038e91d3dbccd212505dee', name: 'Robert Moreton'}
    {id: '54038f0bbc5b69a40e9c2a01', name: 'Andrew Witcher'}
    {id: '54038f6b11058b4213074320', name: 'Axandre Oge'}
    {id: '5403905c0557f27b0c3384be', name: 'Katharine Chan'}
    {id: '5403908e0557f27b0c3384d9', name: 'Derek Wong'}
    {id: '5261b6af158e0a011c000585', name: 'Andreas Linn'}
    {id: '530bbceb934bb3df16c592b7', name: 'Prabh Simran Singh Baweja'}
    {id: '5310e4e562b398ee3ca23325', name: "Nathan Gossett"}
    {name: 'Aftermath', avatar: ''}
    {name: 'mcdavid1991', avatar: ''}
    {name: 'dwhittaker', avatar: ''}
    {name: 'Zacharias Fisches', avatar: ''}
    {name: 'Tom Setliff', avatar: ''}

  ]
