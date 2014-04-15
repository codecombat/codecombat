ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/artisan'
{me} = require('lib/auth')

module.exports = class ArtisanView extends ContributeClassView
  id: "artisan-view"
  template: template
  contributorClassName: 'artisan'

  contributors: [
    {name: "Sootn", avatar: ""}
    {name: "Zach Martin", avatar: "", github: "zachster01"}
    {name: "Aftermath", avatar: ""}
    {name: "mcdavid1991", avatar: ""}
    {name: "dwhittaker", avatar: ""}
    {name: "Zacharias Fisches", avatar: ""}
    {name: "Tom Setliff", avatar: ""}
    {name: "Robert Moreton", avatar: "rob"}
    {name: "Andrew Witcher", avatar: "andrew"}
    {name: "Axandre Oge", avatar: "axandre"}
    {name: "Katharine Chan", avatar: "katharine"}
    {name: "Derek Wong", avatar: "derek"}
    {name: "Alexandru Caciulescu", avatar: "", github: "Darredevil"}
    {name: "Prabh Simran Singh Baweja", avatar: "", github: "prabh27"}
  ]
