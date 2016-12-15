// USAGE:

// 1. npm install csv
// 2. Put the csv file into this folder.
// 3. Update constants below
// 4. (Optional) Export production env to run on production.
// 5. Run script with node.

// Uncomment sections as needed. To test use any combination:
// * run on local db
// * return after the first change is found (commented out)
// * uncomment "return true" lines

// Constants (change these for different languages)
langCode = 'ja';
langProperty = 'Japanese';
fileName = 'ja.csv';

// Set up CoffeeScript
require('coffee-script');
require('coffee-script/register');

// Connect Mongoose
mongoose = require('mongoose')
config = require('../../server_config')
mongoose.connect(config.mongo.mongoose_replica_string || 'mongodb://localhost:27017/coco')

// Set up globals: lodash, jsondiffpatch, tv4
GLOBAL._ = require('lodash')
_.str = require('underscore.string')
_.mixin(_.str.exports())
global.jsondiffpatch = require('jsondiffpatch')
global.tv4 = require('tv4')

// Imports
Level = require('../../server/models/Level');
User = require('../../server/models/User');
Achievement = require('../../server/models/Achievement');
Poll = require('../../server/models/Poll');
Campaign = require('../../server/models/Campaign');
LevelComponent = require('../../server/models/LevelComponent');
ThangType = require('../../server/models/ThangType')
_ = require('lodash');
co = require('co');
fs = require('fs');
versionsLib = require('../../server/middleware/versions')
database = require('../../server/commons/database')
deltasLib = require('../../app/core/deltas')
i18n = require('../../server/commons/i18n')
fs = require('fs')
parse = require('../../node_modules/csv').parse;
Promise = require('bluebird')
parseAsync = Promise.promisify(parse)

Achievement.loadAchievements = () => Promise.resolve() // So they don't attempt to get loaded by the script

// Delta properties
differ = deltasLib.makeJSONDiffer()
omissions = ['original'].concat(deltasLib.DOC_SKIP_PATHS)


update = _.curry(function(translationMap, propertyPrefix, rootDoc, property) {
  englishString = rootDoc[property]
  if(!englishString) return;
  if(_.isUndefined(translationMap[englishString])) { return }
  translation = translationMap[englishString]
  if(!_.isString(translation)) { translation = translation.toString() }
  console.log('found translation!', englishString.slice(0,20), translation.slice(0,20))
  if (!rootDoc.i18n) { rootDoc.i18n = {} }
  if (!rootDoc.i18n[langCode]) { rootDoc.i18n[langCode] = {} }
  rootDoc.i18n[langCode][property] = translation
})

makeTranslationMap = (translations) => {
  map = {}
  _.forEach(translations, (translation) => {
    if(translation[langProperty])
      map[translation.English] = translation[langProperty]
  })
  return map;
}


co(function* () {
  myself = yield User.findOne({nameLower: 'scott'})
  req = { user: myself }

  rawTranslations = fs.readFileSync(__dirname+'/'+fileName, {encoding:'utf8'});
  results = yield parseAsync(rawTranslations, {})
  headerline = _.first(results)
  allTranslations = _.map(_.rest(results), (line) => _.zipObject(headerline, line))
  console.log(`Parsed ${allTranslations.length} translations (ex: ${JSON.stringify(allTranslations[0])}`)

  // Levels

  //levelTranslations = _.filter(allTranslations, (t) => t.Type === 'levels')
  //levelOriginals = _.filter(_.unique(_.pluck(levelTranslations, 'Original')))
  //for (var i in levelOriginals) {
  //  levelOriginalString = levelOriginals[i]
  //  level = yield Level.findCurrentVersion(levelOriginalString)
  //  if(!level) { continue; }
  //
  //  updatedLevel = database.initDoc(req, Level)
  //  versionsLib.initNewVersion(updatedLevel, level)
  //
  //  translations = _.filter(allTranslations, (t) => t.Original === levelOriginalString)
  //  translationMap = makeTranslationMap(translations)
  //
  //  levelObj = updatedLevel.toObject()
  //  updateLevel = update(translationMap);
  //  updateLevel('', levelObj, 'name');
  //  updateLevel('', levelObj, 'description');
  //  updateLevel('', levelObj, 'loadingTip');
  //  updateLevel('', levelObj, 'studentPlayInstructions');
  //
  //  _.forEach(levelObj.goals, function(goal, i) {
  //    updateLevel('goals['+i+']', goal, 'name')
  //  });
  //  if (levelObj.documentation) {
  //    _.forEach(levelObj.documentation.specificArticles, function(article, i) {
  //      updateLevel('documentation.specificArticles['+i+']', article, 'name')
  //      updateLevel('documentation.specificArticles['+i+']', article, 'body')
  //    })
  //    _.forEach(levelObj.documentation.hints, function(hint, i) {
  //      updateLevel('documentation.hints['+i+']', hint, 'body')
  //    });
  //    _.forEach(levelObj.documentation.hintsB, function(hint, i) {
  //      updateLevel('documentation.hintsB['+i+']', hint, 'body')
  //    });
  //  }
  //
  //  _.forEach(levelObj.scripts, function(script, i) {
  //    _.forEach(script.noteChain, function(noteGroup, j) {
  //      if (!noteGroup) return;
  //      _.forEach(noteGroup.sprites, function(spriteCommand, k) {
  //        if(spriteCommand.say) {
  //          scriptPrefix = ['scripts[',i,'].noteChain[',j,'].sprites[',k,'].say'].join('')
  //          updateLevel(scriptPrefix, spriteCommand.say, 'text')
  //          updateLevel(scriptPrefix, spriteCommand.say, 'blurb')
  //          if(spriteCommand.say.responses) {
  //            _.forEach(spriteCommand.say.responses, function(response, l) {
  //              scriptResponsePrefix = scriptPrefix + '.responses[' + l + ']';
  //              updateLevel(scriptResponsePrefix, response, 'text')
  //            })
  //          }
  //        }
  //      })
  //    })
  //  })
  //  if(levelObj.victory) {
  //    updateLevel('victory', levelObj.victory, 'body')
  //  }
  //  
  //  _.forEach(levelObj.thangs, function(thang, i) {
  //    _.forEach(thang.components, function(component, j) {
  //      if (component.config && component.config.programmableMethods) {
  //        _.forEach(component.config.programmableMethods, function(method, k) {
  //          _.forEach(method.context, function(value, property) {
  //            englishString = value
  //            if(!translationMap[englishString]) { return }
  //            if (!method.i18n) { method.i18n = {} }
  //            if (!method.i18n[langCode]) { method.i18n[langCode] = {} }
  //            if (!method.i18n[langCode].context) { method.i18n[langCode].context = {} }
  //            method.i18n[langCode].context[property] = translationMap[englishString]
  //          })
  //        })
  //      }
  //    })
  //  })
  //  updatedLevel.set(levelObj)
  //  updatedLevel.set('commitMessage', `Import ${langProperty} translations`)
  //
  //  delta = differ.diff(_.omit(level.toObject(), omissions), _.omit(updatedLevel.toObject(), omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //  if(flattened.length > 0 && updatedLevel.get('i18nCoverage'))
  //    i18n.updateI18NCoverage(updatedLevel)
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', updatedLevel.get('name'), JSON.stringify(flattened, null, '\t'))
  //    database.validateDoc(updatedLevel)
  //    yield versionsLib.saveNewVersion(updatedLevel, level.get('version.major'))
  //    //return true
  //  }
  //}
  
  
  // Achievements
  
  //achievementTranslations = _.filter(allTranslations, (t) => t.Type === 'achievements')
  //achievementIds = _.filter(_.unique(_.pluck(achievementTranslations, 'ID')))
  //for (var i in achievementIds) {
  //  achievementIdString = achievementIds[i]
  //  achievement = yield Achievement.findById(achievementIdString)
  //  if (!achievement) { continue; }
  //  
  //  originalAchievement = _.cloneDeep(achievement.toObject())
  //  
  //  achievementObject = achievement.toObject()
  //  translations = _.filter(allTranslations, (t) => t.ID === achievementIdString)
  //  translationMap = makeTranslationMap(translations)
  //  updateAchievement = update(translationMap);
  //  updateAchievement('', achievementObject, 'name')
  //  updateAchievement('', achievementObject, 'description')
  //  achievement.set(achievementObject)
  //  i18n.updateI18NCoverage(achievement)
  //
  //  delta = differ.diff(_.omit(originalAchievement, omissions), _.omit(achievementObject, omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //  
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', achievement.get('name'), JSON.stringify(flattened, null, '\t'))
  //    database.validateDoc(achievement)
  //    yield achievement.save()
  //    //return true
  //  }
  //}
  

  // Campaigns
  
  //campaignTranslations = _.filter(allTranslations, (t) => t.Type === 'campaigns')
  //campaignIds = _.filter(_.unique(_.pluck(campaignTranslations, 'ID')))
  //for (var i in campaignIds) {
  //  campaignIdString = campaignIds[i]
  //  campaign = yield Campaign.findById(campaignIdString)
  //  if (!campaign) { continue; }
  //
  //  originalCampaign = _.cloneDeep(campaign.toObject())
  //
  //  campaignObject = campaign.toObject()
  //  translations = _.filter(allTranslations, (t) => t.ID === campaignIdString)
  //  translationMap = makeTranslationMap(translations)
  //  updateCampaign = update(translationMap);
  //  updateCampaign('', campaignObject, 'name')
  //  updateCampaign('', campaignObject, 'fullName')
  //  updateCampaign('', campaignObject, 'description')
  //  campaign.set(campaignObject)
  //  if (campaign.get('i18nCoverage')) {
  //    i18n.updateI18NCoverage(campaign)
  //  }
  //
  //  delta = differ.diff(_.omit(originalCampaign, omissions), _.omit(campaignObject, omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', campaign.get('name'), campaign.get('i18nCoverage'))
  //    database.validateDoc(campaign)
  //    yield campaign.save()
  //    //return true
  //  }
  //}
  
  
  // Components

  //componentTranslations = _.filter(allTranslations, (t) => t.Type === 'level.components')
  //componentOriginals = _.filter(_.unique(_.pluck(componentTranslations, 'Original')))
  //for (var i in componentOriginals) {
  //  componentOriginalString = componentOriginals[i]
  //  originalComponent = yield LevelComponent.findCurrentVersion(componentOriginalString)
  //  if (!originalComponent) { continue; }
  //
  //  updatedComponent = database.initDoc(req, LevelComponent)
  //  versionsLib.initNewVersion(updatedComponent, originalComponent)
  //  
  //  componentObject = updatedComponent.toObject()
  //  translations = _.filter(allTranslations, (t) => t.Original === componentOriginalString)
  //  translationMap = makeTranslationMap(translations)
  //  updateComponent = update(translationMap);
  //
  //  _.forEach(componentObject.propertyDocumentation, function(propDoc, i) {
  //    propDocPrefix = 'propertyDocumentation['+i+']';
  //    updateComponent(propDocPrefix, componentObject.propertyDocumentation[i], 'name')
  //    if(typeof propDoc.description === 'string')
  //      updateComponent(propDocPrefix, propDoc, 'description')
  //    else {
  //      _.forEach(propDoc.description, function (description, j) {
  //        englishString = description
  //        if(!translationMap[englishString]) { return }
  //        if (!propDoc.i18n) { return }
  //        if (!propDoc.i18n[langCode]) { propDoc.i18n[langCode] = {} }
  //        if (!propDoc.i18n[langCode].description) { propDoc.i18n[langCode].description = {} }
  //        propDoc.i18n[langCode].description[j] = translationMap[englishString]
  //      })
  //    }
  //    _.forEach(propDoc.context, function(value, j) {
  //      englishString = value
  //      if(!translationMap[englishString]) { return }
  //      if (!propDoc.i18n) { return }
  //      if (!propDoc.i18n[langCode]) { propDoc.i18n[langCode] = {} }
  //      if (!propDoc.i18n[langCode].context) { propDoc.i18n[langCode].context = {} }
  //      propDoc.i18n[langCode].context[j] = translationMap[englishString]
  //    })
  //  })
  //
  //  updatedComponent.set(componentObject)
  //  updatedComponent.set('commitMessage', `Import ${langProperty} translations`)
  //  //if (updatedComponent.get('i18nCoverage')) {
  //  //  i18n.updateI18NCoverage(updatedComponent)
  //  //}
  //
  //  delta = differ.diff(_.omit(originalComponent.toObject(), omissions), _.omit(componentObject, omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', updatedComponent.get('name'), JSON.stringify(flattened, null, '\t'))
  //    database.validateDoc(updatedComponent)
  //    yield versionsLib.saveNewVersion(updatedComponent, updatedComponent.get('version.major'))
  //    //return true
  //  }
  //}
  
  
  // Polls

  //pollTranslations = _.filter(allTranslations, (t) => t.Type === 'polls')
  //pollIds = _.filter(_.unique(_.pluck(pollTranslations, 'ID')))
  //for (var i in pollIds) {
  //  pollIdString = pollIds[i]
  //  poll = yield Poll.findById(pollIdString)
  //  if (!poll) { continue; }
  //  
  //  originalPoll = _.cloneDeep(poll.toObject())
  //  
  //  pollObject = poll.toObject()
  //  translations = _.filter(allTranslations, (t) => t.ID === pollIdString)
  //  translationMap = makeTranslationMap(translations)
  //  updatePoll = update(translationMap);
  //  updatePoll('', pollObject, 'name')
  //  updatePoll('', pollObject, 'description')
  //  _.forEach(pollObject.answers, function(answer, i) {
  //    updatePoll('answers['+i+']', answer, 'text')
  //  })
  //  poll.set(pollObject)
  //  if(poll.get('i18nCoverage'))
  //    i18n.updateI18NCoverage(poll)
  //
  //  delta = differ.diff(_.omit(originalPoll, omissions), _.omit(pollObject, omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //  
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', poll.get('name'), JSON.stringify(flattened, null, '\t'))
  //    database.validateDoc(poll)
  //    yield poll.save()
  //    //return true
  //  }
  //}


  // Thang Types

  //thangTranslations = _.filter(allTranslations, (t) => t.Type === 'thang.types')
  //thangOriginals = _.filter(_.unique(_.pluck(thangTranslations, 'Original')))
  //for (var i in thangOriginals) {
  //  thangOriginalString = thangOriginals[i]
  //  thang = yield ThangType.findCurrentVersion(thangOriginalString)
  //  if(!thang) { continue; }
  //
  //  updatedThang = database.initDoc(req, ThangType)
  //  versionsLib.initNewVersion(updatedThang, thang)
  //
  //  translations = _.filter(allTranslations, (t) => t.Original === thangOriginalString)
  //  translationMap = makeTranslationMap(translations)
  //
  //  thangObj = updatedThang.toObject()
  //  updateThang = update(translationMap);
  //  updateThang('', thangObj, 'name');
  //  updateThang('', thangObj, 'description');
  //  updateThang('', thangObj, 'extendedName');
  //  updateThang('', thangObj, 'unlockThangName');
  //  
  //  updatedThang.set(thangObj)
  //  updatedThang.set('commitMessage', `Import ${langProperty} translations`)
  //
  //  delta = differ.diff(_.omit(thang.toObject(), omissions), _.omit(updatedThang.toObject(), omissions))
  //  flattened = deltasLib.flattenDelta(delta)
  //  if(flattened.length > 0 && updatedThang.get('i18nCoverage'))
  //    i18n.updateI18NCoverage(updatedThang)
  //  if(flattened.length > 0) {
  //    console.log('flattened changes', updatedThang.get('name'), JSON.stringify(flattened, null, '\t'))
  //    database.validateDoc(updatedThang)
  //    yield versionsLib.saveNewVersion(updatedThang, thang.get('version.major'))
  //    //return true
  //  }
  //}

  
}).then(function() {
  process.exit(0)
}).catch(function(e) {
  console.log('err', e.stack);
  process.exit(0)
});

