{hslToHex} = require 'lib/utils'

module.exports.teamDataFromLevel = (level) ->
  alliedSystem = _.find level.get('systems'), (value) -> value.config?.teams?
  teamNames = (teamName for teamName, teamConfig of alliedSystem.config.teams when teamConfig.playable)
  teamConfigs = alliedSystem.config.teams

  teams = []
  for team in teamNames or []
    otherTeam = if team is 'ogres' then 'humans' else 'ogres'
    color = teamConfigs[team].color
    bgColor = hslToHex([color.hue, color.saturation, color.lightness + (1 - color.lightness) * 0.5])
    primaryColor = hslToHex([color.hue, 0.5, 0.5])
    teams.push({
      id: team
      name: _.string.titleize(team)
      otherTeam: otherTeam
      bgColor: bgColor
      primaryColor: primaryColor
    })

  teams
