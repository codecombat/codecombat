ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/archmage'

module.exports = class ArchmageView extends ContributeClassView
  id: "archmage-view"
  template: template
  contributorClassName: 'archmage'

  contributors: [
    {id: "52bfc3ecb7ec628868001297", name: "Tom Steinbrecher", github: "TomSteinbrecher"}
    {id: "5272806093680c5817033f73", name: "Sébastien Moratinos", github: "smoratinos"}
    {name: "deepak1556", avatar: "deepak", github: "deepak1556"}
    {name: "Ronnie Cheng", avatar: "ronald", github: "rhc2104"}
    {name: "Chloe Fan", avatar: "chloe", github: "chloester"}
    {name: "Rachel Xiang", avatar: "rachel", github: "rdxiang"}
    {name: "Dan Ristic", avatar: "dan", github: "dristic"}
    {name: "Brad Dickason", avatar: "brad", github: "bdickason"}
    {name: "Rebecca Saines", avatar: "becca"}
    {name: "Laura Watiker", avatar: "laura", github: "lwatiker"}
    {name: "Shiying Zheng", avatar: "shiying", github: "shiyingzheng"}
    {name: "Mischa Lewis-Norelle", avatar: "mischa", github: "mlewisno"}
    {name: "Paul Buser", avatar: "paul"}
    {name: "Benjamin Stern", avatar: "ben"}
    {name: "Alex Cotsarelis", avatar: "alex"}
    {name: "Ken Stanley", avatar: "ken"}
    {name: "devast8a", avatar: "", github: "devast8a"}
    {name: "phansch", avatar: "", github: "phansch"}
    {name: "Zach Martin", avatar: "", github: "zachster01"}
    {name: "David Golds", avatar: ""}
    {name: "gabceb", avatar: "", github: "gabceb"}
    {name: "MDP66", avatar: "", github: "MDP66"}
    {name: "Alexandru Caciulescu", avatar: "", github: "Darredevil"}
  ]
