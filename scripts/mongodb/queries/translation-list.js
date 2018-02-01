langCode = 'zh-HANS';
load('node_modules/lodash/dist/lodash.js');

translations = [];
reusableTranslationMap = {};
untranslatedWords = 0;
totalWords = 0;

add = _.curry(function(docType, doc, propertyPrefix, rootDoc, property) {
  englishString = rootDoc[property]
  if (typeof englishString !== 'string')
    return;

  translationString = '';

  if (rootDoc.i18n) {
    langTranslationObject = rootDoc.i18n[langCode]
    if (langTranslationObject) {
      translationString = langTranslationObject[property] || '';
    }
  }

  if (!translationString) {
    translationString = reusableTranslationMap[englishString];
  }
  else if (!reusableTranslationMap[englishString]) {
    reusableTranslationMap[englishString] = translationString;
  }

  path = propertyPrefix ? propertyPrefix + '.' + property : property;
  printTranslation(docType, doc, path, englishString, translationString)
});

printTranslation = function(docType, doc, path, englishString, translationString) {
  // Check path is valid
  try { eval('doc.'+path) }
  catch (e) { print('FAILURE', path); throw e; }

  if (!englishString) {
    return;
  }

  if(!translationString) {
    untranslatedWords += englishString.split(/\s+/).length;
  }
  totalWords += englishString.split(/\s+/).length;

  //// skip translated strings?
  //if(translationString) {
  //  return
  //}

  // Google Docs: =SUBSTITUTE(SUBSTITUTE(F2, "\n", char(10)), "XX", CHAR(34))
  // Excel: =SUBSTITUTE(E1, "\n", CHAR(10) & CHAR(13))
  var translation = [[docType, doc._id+'', doc.original ? doc.original+'' : '', path, JSON.stringify(englishString), JSON.stringify(translationString)].join('\t')]
  translations.push(translation);
}

// Find unique level original ids for classroom and home campaigns
var courses = db.courses.find({releasePhase: 'released'}, {campaignID: 1}).toArray();
var campaignIds = courses.reduce(function (ids, val) {
  // if (val._id.valueOf() === '56462f935afde0c6fd30fc8c') ids.push(val.campaignID);
  return ids;
}, []);
var campaignSlugs = ['intro', 'game-dev-1', 'web-dev-1', 'course-2', 'game-dev-2', 'web-dev-2', 'dungeon', 'course-3', 'game-dev-3', 'campaign-game-dev-1', 'campaign-game-web-1', 'forest', 'campaign-game-dev-2', 'campaign-game-web-2', 'desert', 'mountain', 'glacier'];
// campaignSlugs = [];
var campaigns = db.campaigns.find({$or: [{slug: {$in: campaignSlugs}}, {_id: {$in: campaignIds}}]}, {levels: 1, slug: 1}).toArray();
campaigns = _.sortBy(campaigns, function(campaign) {
  var index = campaignSlugs.indexOf(campaign.slug);
  return index == -1 ? 9001 : index;
});
var levelOriginalsToDo = [];
campaigns.forEach(function(campaign) {
  for (var levelOriginalId in campaign.levels) {
    levelOriginalsToDo.push(levelOriginalId);
  }
});
levelOriginalsToDo = _.unique(levelOriginalsToDo);
var allLevels = db.levels.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).toArray();
allLevels = _.sortBy(allLevels, function(level) { return levelOriginalsToDo.indexOf(level.original + ''); });
allLevels.forEach(function(level, levelIndex) {
//db.levels.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (level) {
  if(!_.contains(levelOriginalsToDo, level.original+'')) {
    return
  }
  //if(levelIndex > 260) return;
  addLevel = add('levels', level);
  addLevel('', level, 'name');
  addLevel('', level, 'description');
  addLevel('', level, 'loadingTip');
  addLevel('', level, 'studentPlayInstructions');

  _.forEach(level.goals, function(goal, i) {
    addLevel('goals['+i+']', goal, 'name')
  });
  if (level.documentation) {
    _.forEach(level.documentation.specificArticles, function(article, i) {
      addLevel('documentation.specificArticles['+i+']', article, 'name')
      addLevel('documentation.specificArticles['+i+']', article, 'body')
    })
    _.forEach(level.documentation.hints, function(hint, i) {
      addLevel('documentation.hints['+i+']', hint, 'body')
    });
    _.forEach(level.documentation.hintsB, function(hint, i) {
      addLevel('documentation.hintsB['+i+']', hint, 'body')
    });
  }

  _.forEach(level.scripts, function(script, i) {
    _.forEach(script.noteChain, function(noteGroup, j) {
      if (!noteGroup) return;
      _.forEach(noteGroup.sprites, function(spriteCommand, k) {
        if(spriteCommand.say) {
          scriptPrefix = ['scripts[',i,'].noteChain[',j,'].sprites[',k,'].say'].join('')
          addLevel(scriptPrefix, spriteCommand.say, 'text')
          addLevel(scriptPrefix, spriteCommand.say, 'blurb')
          if(spriteCommand.say.responses) {
            _.forEach(spriteCommand.say.responses, function(response, l) {
              scriptResponsePrefix = scriptPrefix + '.responses[' + l + ']';
              addLevel(scriptResponsePrefix, response, 'text')
            })
          }
        }
      })
    })
  })
  if(level.victory) {
    add('victory', level.victory, 'body')
  }
  _.forEach(level.thangs, function(thang, i) {
    _.forEach(thang.components, function(component, j) {
      if (component.config && component.config.programmableMethods) {
        _.forEach(component.config.programmableMethods, function(method, k) {
          _.forEach(method.context, function(value, property) {
            methodPath = ['thangs[',i,'].components[',j,'].config.programmableMethods[',JSON.stringify(k),'].context['+JSON.stringify(property)+']'].join('')
            translationString = '';
            if(method.i18n && method.i18n[langCode] && method.i18n[langCode].context) {
              translationString = method.i18n[langCode].context[property] || '';
            }
            printTranslation('levels', level, methodPath, value, translationString)
          })
        })
      }
    })
  })
  _.forEach(level.thangs, function(thang, i) {
    _.forEach(thang.components, function(component, j) {
      if (component.config && component.config.context && component.config.i18n) {
        _.forEach(component.config.context, function(value, property) {
          contextPath = ['thangs[',i,'].components[',j,'].config.context['+JSON.stringify(property)+']'].join('')
          translationString = '';
          if(component.config.i18n && component.config.i18n[langCode] && component.config.i18n[langCode].context) {
            translationString = component.config.i18n[langCode].context[property] || '';
          }
          printTranslation('levels', level, contextPath, value, translationString)
        })
      }
    })
  })
});

db.achievements.find().forEach(function (achievement) {
  if(!_.contains(levelOriginalsToDo, achievement.related+'')) {
    return
  }
  addAchievement = add('achievements', achievement)
  addAchievement('', achievement, 'name')
  addAchievement('', achievement, 'description')
});

db.campaigns.find().forEach(function (campaign) {
  addCampaign = add('campaigns', campaign);
  addCampaign('', campaign, 'name')
  addCampaign('', campaign, 'fullName')
  addCampaign('', campaign, 'description')
})

db.level.components.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (levelComponent) {
  addComponent = add('level.components', levelComponent)

  _.forEach(levelComponent.propertyDocumentation, function(propDoc, i) {
    propDocPrefix = 'propertyDocumentation['+i+']';
    addComponent(propDocPrefix, propDoc, 'name')
    if(typeof propDoc.description === 'string')
      addComponent(propDocPrefix, propDoc, 'description')
    else {
      _.forEach(propDoc.description, function (description, j) {
        valuePath = propDocPrefix + '.description['+JSON.stringify(j)+']'
        translationString = ''
        if(propDoc.i18n && propDoc.i18n[langCode] && propDoc.i18n[langCode].description) {
          translationString = propDoc.i18n[langCode].description[j]
        }
        printTranslation('level.components', levelComponent, valuePath, description, translationString)
      })
    }
    _.forEach(propDoc.context, function(value, j) {
      valuePath = propDocPrefix + '.context['+JSON.stringify(j)+']'
      translationString = ''
      if(propDoc.i18n && propDoc.i18n[langCode] && propDoc.i18n[langCode].context) {
        translationString = propDoc.i18n[langCode].context[j]
      }
      printTranslation('level.components', levelComponent, valuePath, value, translationString)
    })

    if(propDoc.returns) {
      if(typeof propDoc.returns.description === 'string')
        addComponent(propDocPrefix + '.returns', propDoc.returns, 'description')
      else
        _.forEach(propDoc.returns.description, function(value) {
          throw new Error('No complicated returns translations?')
        })
    }
    _.forEach(propDoc.args, function(argDoc, j) {
      argsPath = propDocPrefix + '.args['+JSON.stringify(j)+']'
      if(typeof argDoc.description === 'string')
        addComponent(argsPath, argDoc, 'description')
      else
        _.forEach(argDoc.description, function(value) {
          throw new Error('No complicated args translations?')
        })
    })
  })
});

db.polls.find().forEach(function (poll) {
  addPoll = add('polls', poll)

  addPoll('', poll, 'name')
  addPoll('', poll, 'description')
  _.forEach(poll.answers, function(answer, i) {
    addPoll('answers['+i+']', answer, 'text')
    add(answer.text)
  })
})

db.thang.types.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (thangType) {
  addThang = add('thang.types', thangType, '')
  addThang(thangType, 'name')
  addThang(thangType, 'description')
  addThang(thangType, 'extendedName')
  addThang(thangType, 'shortName')
  addThang(thangType, 'unlockLevelName')
})

db.articles.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (article) {
  addArticle = add('articles', article, '');
  addArticle(article, 'name');
  addArticle(article, 'body');
})

translations.forEach(function(tr) {
  print(tr.join('\n'));
});

print('\n\nUntranslated words: ' + untranslatedWords, '\nTotal: ' + totalWords)
