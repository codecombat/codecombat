loadAetherLanguage = (language) -> new Promise (accept, reject) ->
  switch language
    when 'javascript' then require.ensure(['bower_components/aether/build/javascript'], => accept(require('bower_components/aether/build/javascript')))
    when 'python' then require.ensure(['bower_components/aether/build/python'], => accept(require('bower_components/aether/build/python')))
    when 'coffeescript' then require.ensure(['bower_components/aether/build/coffeescript'], => accept(require('bower_components/aether/build/coffeescript')))
    when 'lua' then require.ensure(['bower_components/aether/build/lua'], => accept(require('bower_components/aether/build/lua')))
    when 'java' then require.ensure(['bower_components/aether/build/java'], => accept(require('bower_components/aether/build/java')))

module.exports = loadAetherLanguage
