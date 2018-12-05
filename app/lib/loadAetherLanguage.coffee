loadAetherLanguage = (language) -> new Promise (accept, reject) ->
  switch language
    when 'javascript' then require.ensure(['public/javascripts/app/vendor/aether-javascript'], => accept(require('public/javascripts/app/vendor/aether-javascript')))
    when 'python' then require.ensure(['public/javascripts/app/vendor/aether-python'], => accept(require('public/javascripts/app/vendor/aether-python')))
    when 'coffeescript' then require.ensure(['public/javascripts/app/vendor/aether-coffeescript'], => accept(require('public/javascripts/app/vendor/aether-coffeescript')))
    when 'lua' then require.ensure(['public/javascripts/app/vendor/aether-lua'], => accept(require('public/javascripts/app/vendor/aether-lua')))
    when 'java' then require.ensure(['public/javascripts/app/vendor/aether-java'], => accept(require('public/javascripts/app/vendor/aether-java')))

module.exports = loadAetherLanguage
