{hslToHex} = require 'core/utils'

module.exports.teamDataFromLevel = (level) ->
  alliedSystem = _.find level.get('systems', true), (value) -> value.config?.teams?
  teamNames = (teamName for teamName, teamConfig of alliedSystem.config.teams when teamConfig.playable)
  teamConfigs = alliedSystem.config.teams

  teams = []
  for team in teamNames or []
    otherTeam = if team is 'ogres' then 'humans' else 'ogres'
    color = teamConfigs[team].color
    bgColor = hslToHex([color.hue, color.saturation, color.lightness + (1 - color.lightness) * 0.5])
    primaryColor = hslToHex([color.hue, 0.5, 0.5])
    if level.get('slug') in ['wakka-maul']
      displayName = _.string.titleize(team)
    else
      displayName = $.i18n.t("ladder.#{team}")  # Use Red/Blue instead of Humans/Ogres
    teams.push({
      id: team
      name: _.string.titleize(team)
      displayName: displayName
      otherTeam: otherTeam
      otherTeamDisplayName: $.i18n.t("ladder.#{otherTeam}")
      bgColor: bgColor
      primaryColor: primaryColor
    })

  teams

module.exports.scoreForDisplay = (score) ->
  return score * 100
