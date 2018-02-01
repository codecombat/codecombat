// USAGE:

// 1. npm install csv
// 2. Put the csv file into this folder.
// 3. Update constants below
// 4. (Optional) Export production env to run on production.
// 5. Run script with node. (You may need to use node 6.)

// To test use any combination:
// * run on local db
// * return after the first change is found (commented out)
// * uncomment "return true" lines

// Constants (change these for different languages)
langCode = 'he';
langProperty = 'Hebrew';  // Match column name in CSV
fileName = 'en-to-he-2017-12-22.csv';
doSave = false;  // Change to true to actually save

if (!doSave)
  console.log("-----------------Dry Run---------------\nChange doSave to true to do it for real\n---------------------------------------\n")

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
Article = require('../../server/models/Article')
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

updatedCount = 0
unchangedCount = 0
update = _.curry(function(translationMap, propertyPrefix, rootDoc, property) {
  englishString = rootDoc[property]
  if(!englishString) return;
  var normalizedEnglish = normalizeEscapesAndPunctuationKeys(englishString);
  //if(_.isUndefined(translationMap[normalizedEnglish])) { console.log("Couldn't find", englishString, normalizedEnglish, "for", propertyPrefix); }
  if(_.isUndefined(translationMap[normalizedEnglish])) { return }
  translation = translationMap[normalizedEnglish]
  if(!_.isString(translation)) { translation = translation.toString() }
  translation = _.str.trim(translation)
  //console.log('found translation!', englishString.slice(0,20), translation.slice(0,20))
  if (langCode == 'he' && !isHebrew(translation)) {
    // Skip non-Hebrew because of the translator's workflow not including old translations
    //console.log("Skipping non-Hebrew", englishString,"\t",translation);
    return;
  }
  if (!rootDoc.i18n) { rootDoc.i18n = {} }
  if (!rootDoc.i18n[langCode]) { rootDoc.i18n[langCode] = {} }
  var oldTranslation = rootDoc.i18n[langCode][property];
  if(logUpdate(englishString, translation, oldTranslation))
    rootDoc.i18n[langCode][property] = translation
})

function logUpdate(englishString, translation, oldTranslation) {
  if (langCode == 'he' && oldTranslation && isHebrew(oldTranslation) && translation != oldTranslation) {
    console.log("Skipping overwriting on", englishString);
    ++unchangedCount;
    return false;  // Don't overwrite any Hebrew, it might be a more recent correction from proofreader
  }
  if (translation != oldTranslation) {
    ++updatedCount;
    console.log('Changed:',updatedCount,'\tUpdating translation\nFor:', englishString.slice(0,100).replace(/\n/g, '\\n'), '\nOld:', (oldTranslation || '').slice(0,100).replace(/\n/g, '\\n'), '\nNew:', translation.slice(0,100).replace(/\n/g, '\\n'),'\n');
    return true;
  }
  else {
    ++unchangedCount;
    return true;
  }
}

function isHebrew(s) {
  for(var i = 0; i < s.length; ++i) {
    if(s.charCodeAt(i) >= 0x0590 && s.charCodeAt(i) <= 0x05FF)
      return true;
  }
  return false;
}

function normalizeEscapesAndPunctuationKeys(s) {
  s = s.replace(/\\r/g, '');
  s = s.replace(/\\n/g, '');
  s = s.replace(/\n/g, '');
  s = s.replace(/n/g, '');  // Just kill me now
  s = s.replace(/"/g, '');
  s = s.replace(/\\/g, '');
  return s;
}

function normalizeEscapesAndPunctuationValues(s) {
  // Possible we could use this for keys as well
  s = s.replace(/\\r/g, '');
  s = s.replace(/\\n/g, '\n');
  s = s.replace(/\\"/g, '"');
  if (langCode == 'zh-HANS' || langCode == 'he') {
    var s1 = s;
    s = s.replace(/\\/, '"');  // Saw this in Chinese spreadsheet import once, probably don't want to use generally unless problem resurfaces
    if (s != s1) {
      var quotes = s.match(/(")/g);
      if (quotes && quotes.length % 2)
        s = s.replace(/"$/, '');  // Kill the trailing quote we didn't want
    }
  }
  //s = s.replace(/"$/, '');  // Saw this in Hebrew spreadsheet import once, probably don't want to use generally unless problem resurfaces
  return s;
}

makeTranslationMap = (translations) => {
  map = {}
  _.forEach(translations, (translation) => {
    if(translation[langProperty]) {
      var normalizedEnglish = normalizeEscapesAndPunctuationKeys(translation.English);
      map[normalizedEnglish] = normalizeEscapesAndPunctuationValues(translation[langProperty]);
    }
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

  levelTranslations = _.filter(allTranslations, (t) => t.Type === 'levels')
  levelOriginals = _.filter(_.unique(_.pluck(levelTranslations, 'Original')))
  for (var i in levelOriginals) {
    levelOriginalString = levelOriginals[i]
    level = yield Level.findCurrentVersion(levelOriginalString)
    if(!level) { continue; }
  
    updatedLevel = database.initDoc(req, Level)
    versionsLib.initNewVersion(updatedLevel, level)
  
    translations = _.filter(allTranslations, (t) => t.Original === levelOriginalString)
    translationMap = makeTranslationMap(translations)
  
    levelObj = updatedLevel.toObject()
    updateLevel = update(translationMap);
    updateLevel('', levelObj, 'name');
    updateLevel('', levelObj, 'description');
    updateLevel('', levelObj, 'loadingTip');
    updateLevel('', levelObj, 'studentPlayInstructions');
  
    _.forEach(levelObj.goals, function(goal, i) {
      updateLevel('goals['+i+']', goal, 'name')
    });
    if (levelObj.documentation) {
      _.forEach(levelObj.documentation.specificArticles, function(article, i) {
        updateLevel('documentation.specificArticles['+i+']', article, 'name')
        updateLevel('documentation.specificArticles['+i+']', article, 'body')
      })
      _.forEach(levelObj.documentation.hints, function(hint, i) {
        updateLevel('documentation.hints['+i+']', hint, 'body')
      });
      _.forEach(levelObj.documentation.hintsB, function(hint, i) {
        updateLevel('documentation.hintsB['+i+']', hint, 'body')
      });
    }
  
    _.forEach(levelObj.scripts, function(script, i) {
      _.forEach(script.noteChain, function(noteGroup, j) {
        if (!noteGroup) return;
        _.forEach(noteGroup.sprites, function(spriteCommand, k) {
          if(spriteCommand.say) {
            scriptPrefix = ['scripts[',i,'].noteChain[',j,'].sprites[',k,'].say'].join('')
            updateLevel(scriptPrefix, spriteCommand.say, 'text')
            updateLevel(scriptPrefix, spriteCommand.say, 'blurb')
            if(spriteCommand.say.responses) {
              _.forEach(spriteCommand.say.responses, function(response, l) {
                scriptResponsePrefix = scriptPrefix + '.responses[' + l + ']';
                updateLevel(scriptResponsePrefix, response, 'text')
              })
            }
          }
        })
      })
    })
    if(levelObj.victory) {
      updateLevel('victory', levelObj.victory, 'body')
    }
    
    _.forEach(levelObj.thangs, function(thang, i) {
      _.forEach(thang.components, function(component, j) {
        if (component.config && component.config.programmableMethods) {
          _.forEach(component.config.programmableMethods, function(method, k) {
            _.forEach(method.context, function(value, property) {
              englishString = value
              var normalizedEnglish = normalizeEscapesAndPunctuationKeys(englishString);
              if(!translationMap[normalizedEnglish]) { return }
              if (!method.i18n) { method.i18n = {} }
              if (!method.i18n[langCode]) { method.i18n[langCode] = {} }
              if (!method.i18n[langCode].context) { method.i18n[langCode].context = {} }
              if(logUpdate(englishString, translationMap[normalizedEnglish], method.i18n[langCode].context[property]))
                method.i18n[langCode].context[property] = translationMap[normalizedEnglish]
            })
          })
        }
      })
    })

    _.forEach(levelObj.thangs, function(thang, i) {
      _.forEach(thang.components, function(component, j) {
        if (component.config && component.config.context && component.config.i18n) {
          _.forEach(component.config.context, function(value, property) {
            englishString = value
            var normalizedEnglish = normalizeEscapesAndPunctuationKeys(englishString);
            if(!translationMap[normalizedEnglish]) { return }
            if (!component.config.i18n[langCode]) { component.config.i18n[langCode] = {} }
            if (!component.config.i18n[langCode].context) { component.config.i18n[langCode].context = {} }
            if(logUpdate(englishString, translationMap[normalizedEnglish], component.config.i18n[langCode].context[property]))
              component.config.i18n[langCode].context[property] = translationMap[normalizedEnglish]
          })
        }
      })
    })

    updatedLevel.set(levelObj)
    updatedLevel.set('commitMessage', `Import ${langProperty} translations`)
  
    i18n.updateI18NCoverage(updatedLevel)
  
    delta = differ.diff(_.omit(level.toObject(), omissions), _.omit(updatedLevel.toObject(), omissions))
    flattened = deltasLib.flattenDelta(delta)
  
    if(flattened.length > 0) {
      //console.log('flattened changes', updatedLevel.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(updatedLevel)
      if (doSave)
        yield versionsLib.saveNewVersion(updatedLevel, level.get('version.major'))
      //return true
    }
  }
  
  
  // Achievements
  
  achievementTranslations = _.filter(allTranslations, (t) => t.Type === 'achievements')
  achievementIds = _.filter(_.unique(_.pluck(achievementTranslations, 'ID')))
  for (var i in achievementIds) {
    achievementIdString = achievementIds[i]
    achievement = yield Achievement.findById(achievementIdString)
    if (!achievement) { continue; }
    
    originalAchievement = _.cloneDeep(achievement.toObject())
    
    achievementObject = achievement.toObject()
    translations = _.filter(allTranslations, (t) => t.ID === achievementIdString)
    translationMap = makeTranslationMap(translations)
    updateAchievement = update(translationMap);
    updateAchievement('', achievementObject, 'name')
    updateAchievement('', achievementObject, 'description')
    achievement.set(achievementObject)
    i18n.updateI18NCoverage(achievement)
  
    delta = differ.diff(_.omit(originalAchievement, omissions), _.omit(achievementObject, omissions))
    flattened = deltasLib.flattenDelta(delta)
    
    if(flattened.length > 0) {
      //console.log('flattened changes', achievement.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(achievement)
      if (doSave)
        yield achievement.save()
      //return true
    }
  }
  

  // Campaigns
  
  campaignTranslations = _.filter(allTranslations, (t) => t.Type === 'campaigns')
  campaignIds = _.filter(_.unique(_.pluck(campaignTranslations, 'ID')))
  for (var i in campaignIds) {
    campaignIdString = campaignIds[i]
    campaign = yield Campaign.findById(campaignIdString)
    if (!campaign) { continue; }
    if (_.contains(['JS Primer', 'JS Primer Playtest', 'Game Dev HoC'], campaign.get('name'))) { continue; } // invalid data
  
    originalCampaign = _.cloneDeep(campaign.toObject())
  
    campaignObject = campaign.toObject()
    translations = _.filter(allTranslations, (t) => t.ID === campaignIdString)
    translationMap = makeTranslationMap(translations)
    updateCampaign = update(translationMap);
    updateCampaign('', campaignObject, 'name')
    updateCampaign('', campaignObject, 'fullName')
    updateCampaign('', campaignObject, 'description')
    campaign.set(campaignObject)
    if (campaign.get('i18nCoverage')) {
      i18n.updateI18NCoverage(campaign)
    }
  
    delta = differ.diff(_.omit(originalCampaign, omissions), _.omit(campaignObject, omissions))
    flattened = deltasLib.flattenDelta(delta)
  
    if(flattened.length > 0) {
      //console.log('flattened changes', campaign.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(campaign)
      if (doSave)
        yield campaign.save()
      //return true
    }
  }
  
  
  // Components

  componentTranslations = _.filter(allTranslations, (t) => t.Type === 'level.components')
  componentOriginals = _.filter(_.unique(_.pluck(componentTranslations, 'Original')))
  for (var i in componentOriginals) {
    componentOriginalString = componentOriginals[i]
    originalComponent = yield LevelComponent.findCurrentVersion(componentOriginalString)
    if (!originalComponent) { continue; }
  
    updatedComponent = database.initDoc(req, LevelComponent)
    versionsLib.initNewVersion(updatedComponent, originalComponent)
    
    componentObject = updatedComponent.toObject()
    translations = _.filter(allTranslations, (t) => t.Original === componentOriginalString)
    translationMap = makeTranslationMap(translations)
    updateComponent = update(translationMap);
  
    _.forEach(componentObject.propertyDocumentation, function(propDoc, i) {
      propDocPrefix = 'propertyDocumentation['+i+']';
      updateComponent(propDocPrefix, componentObject.propertyDocumentation[i], 'name')
      if(typeof propDoc.description === 'string')
        updateComponent(propDocPrefix, propDoc, 'description')
      else {
        _.forEach(propDoc.description, function (description, j) {
          englishString = description
          var normalizedEnglish = normalizeEscapesAndPunctuationKeys(englishString);
          if(!translationMap[normalizedEnglish]) { return }
          if (!propDoc.i18n) { return }
          if (!propDoc.i18n[langCode]) { propDoc.i18n[langCode] = {} }
          if (!propDoc.i18n[langCode].description) { propDoc.i18n[langCode].description = {} }
          if (langCode == 'he' && translationMap[normalizedEnglish] && isHebrew(translationMap[normalizedEnglish])) {
            console.log("Skipping overwriting on", englishString);
            return;  // Don't overwrite any Hebrew, it might be a more recent correction from proofreader
          }
          if(logUpdate(englishString, translationMap[normalizedEnglish], propDoc.i18n[langCode].description[j]))
            propDoc.i18n[langCode].description[j] = translationMap[normalizedEnglish]
        })
      }
      _.forEach(propDoc.context, function(value, j) {
        englishString = value
        var normalizedEnglish = normalizeEscapesAndPunctuationKeys(englishString);
        if(!translationMap[normalizedEnglish]) { return }
        if (!propDoc.i18n) { return }
        if (!propDoc.i18n[langCode]) { propDoc.i18n[langCode] = {} }
        if (!propDoc.i18n[langCode].context) { propDoc.i18n[langCode].context = {} }
        if (langCode == 'he' && translationMap[normalizedEnglish] && isHebrew(translationMap[normalizedEnglish])) {
          console.log("Skipping overwriting on", englishString);
          return;  // Don't overwrite any Hebrew, it might be a more recent correction from proofreader
        }
        if(logUpdate(englishString, translationMap[normalizedEnglish], propDoc.i18n[langCode].context[j]))
          propDoc.i18n[langCode].context[j] = translationMap[normalizedEnglish]
      })
    })
  
    updatedComponent.set(componentObject)
    updatedComponent.set('commitMessage', `Import ${langProperty} translations`)
    //if (updatedComponent.get('i18nCoverage')) {
    //  i18n.updateI18NCoverage(updatedComponent)
    //}
  
    delta = differ.diff(_.omit(originalComponent.toObject(), omissions), _.omit(componentObject, omissions))
    flattened = deltasLib.flattenDelta(delta)
  
    if(flattened.length > 0) {
      //console.log('flattened changes', updatedComponent.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(updatedComponent)
      if (doSave)
        yield versionsLib.saveNewVersion(updatedComponent, updatedComponent.get('version.major'))
      //return true
    }
  }
  
  
  // Polls

  pollTranslations = _.filter(allTranslations, (t) => t.Type === 'polls')
  pollIds = _.filter(_.unique(_.pluck(pollTranslations, 'ID')))
  for (var i in pollIds) {
    pollIdString = pollIds[i]
    poll = yield Poll.findById(pollIdString)
    if (!poll) { continue; }
    
    originalPoll = _.cloneDeep(poll.toObject())
    
    pollObject = poll.toObject()
    translations = _.filter(allTranslations, (t) => t.ID === pollIdString)
    translationMap = makeTranslationMap(translations)
    updatePoll = update(translationMap);
    updatePoll('', pollObject, 'name')
    updatePoll('', pollObject, 'description')
    _.forEach(pollObject.answers, function(answer, i) {
      updatePoll('answers['+i+']', answer, 'text')
    })
    poll.set(pollObject)
    if(poll.get('i18nCoverage'))
      i18n.updateI18NCoverage(poll)
  
    delta = differ.diff(_.omit(originalPoll, omissions), _.omit(pollObject, omissions))
    flattened = deltasLib.flattenDelta(delta)
    
    if(flattened.length > 0) {
      //console.log('flattened changes', poll.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(poll)
      if (doSave)
        yield poll.save()
      //return true
    }
  }


  // Thang Types

  thangTranslations = _.filter(allTranslations, (t) => t.Type === 'thang.types')
  thangOriginals = _.filter(_.unique(_.pluck(thangTranslations, 'Original')))
  for (var i in thangOriginals) {
    thangOriginalString = thangOriginals[i]
    thang = yield ThangType.findCurrentVersion(thangOriginalString)
    if(!thang) { continue; }
  
    updatedThang = database.initDoc(req, ThangType)
    versionsLib.initNewVersion(updatedThang, thang)
  
    translations = _.filter(allTranslations, (t) => t.Original === thangOriginalString)
    translationMap = makeTranslationMap(translations)
  
    thangObj = updatedThang.toObject()
    updateThang = update(translationMap);
    updateThang('', thangObj, 'name');
    updateThang('', thangObj, 'description');
    updateThang('', thangObj, 'extendedName');
    updateThang('', thangObj, 'shortName');
    updateThang('', thangObj, 'unlockThangName');
    
    updatedThang.set(thangObj)
    updatedThang.set('commitMessage', `Import ${langProperty} translations`)
    i18n.updateI18NCoverage(updatedThang)
    delta = differ.diff(_.omit(thang.toObject(), omissions), _.omit(updatedThang.toObject(), omissions))
    flattened = deltasLib.flattenDelta(delta)
    if(flattened.length > 0) {
      //console.log('flattened changes', updatedThang.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(updatedThang)
      if (doSave)
        yield versionsLib.saveNewVersion(updatedThang, thang.get('version.major'))
      //return true
    }
  }

  // Articles

  articleTranslations = _.filter(allTranslations, (t) => t.Type === 'articles')
  articleOriginals = _.filter(_.unique(_.pluck(articleTranslations, 'Original')))
  for (var i in articleOriginals) {
    articleOriginalString = articleOriginals[i]
    article = yield Article.findCurrentVersion(articleOriginalString)
    if(!article) { continue; }
  
    updatedArticle = database.initDoc(req, Article)
    versionsLib.initNewVersion(updatedArticle, article)
  
    translations = _.filter(allTranslations, (t) => t.Original === articleOriginalString)
    translationMap = makeTranslationMap(translations)
  
    articleObj = updatedArticle.toObject()
    updateArticle = update(translationMap);
    updateArticle('', articleObj, 'name');
    updateArticle('', articleObj, 'body');
    
    updatedArticle.set(articleObj)
    updatedArticle.set('commitMessage', `Import ${langProperty} translations`)
    i18n.updateI18NCoverage(updatedArticle)
    delta = differ.diff(_.omit(article.toObject(), omissions), _.omit(updatedArticle.toObject(), omissions))
    flattened = deltasLib.flattenDelta(delta)
    if(flattened.length > 0) {
      //console.log('flattened changes', updatedArticle.get('name'), JSON.stringify(flattened, null, '\t'))
      database.validateDoc(updatedArticle)
      if (doSave)
        yield versionsLib.saveNewVersion(updatedArticle, article.get('version.major'))
      //return true
    }
  }

  
}).then(function() {
  console.log("Final updated count:", updatedCount);
  console.log("    Unchanged count:", unchangedCount);
  process.exit(0)
}).catch(function(e) {
  console.log('err', e.stack);
  process.exit(0)
});

