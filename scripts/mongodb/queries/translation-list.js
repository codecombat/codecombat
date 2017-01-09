langCode = 'zh-HANS';
load('bower_components/lodash/dist/lodash.js');

translations = [];
reusableTranslationMap = {};
untranslatedWords = 0;

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
    untranslatedWords += englishString.split(/\s/).length;
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

  //// skip translated strings?
  //if(translationString) {
  //  return
  //}

  // =SUBSTITUTE(SUBSTITUTE(F2, "\n", char(10)), "XX", CHAR(34))
  var translation = [
    [docType, doc._id+'', doc.original ? doc.original+'' : '', path, 'English:', JSON.stringify(englishString)].join('\t').replace(/\\"/gi, 'XX'),
    ['', '', '', '', 'Chinese:', JSON.stringify(translationString)].join('\t').replace(/\\"/gi, 'XX'),
    ''
  ];
  translation.sortKey = englishString.length;
  translations.push(translation);
}

levelOriginalsToDo = ["5411cb3769152f1707be029c","54173c90844506ae0195a0b4","54174347844506ae0195a0b8","54cfc6e2d06e8152051eb8a4","541875da4c16460000ab990f","580aaafe990e3e1f00bde535","5418aec24c16460000ab9aa6","57aa1bd5e5636725008854c0","5604169b60537b8705386a59","55ca293b9bc1892c835b0136","565ce2291b940587057366dd","545a5914d820eb0000f6dc0a","5418cf256bae62f707c7e1c3","5418d40f4c16460000ab9ac2","5452adea57e83800009730ee","5452c3ce57e83800009730f7","541b288e1ccc8eaae19f3c25","55ca29439bc1892c835b0137","541b434e1ccc8eaae19f3c33","541c9a30c6362edfb0f34479","54b83c4829843994803c8390","544437e0645c0c0000c3291d","55525bcaaf92058705a94c02","541b67f71ccc8eaae19f3c62","5446cb40ce01c23e05ecf027","5487330d84f7b4dac246d440","54b3591c7961bdef1c751977","54b361697961bdef1c751985","546e91b8a4b7840000ee92dc","5448330517d7283e051f9b9e","5456b3c8d5ada30000525605","5456bb8dd5ada30000525613","568c2687f9563045007bb6d8","5705b1a6a904662500f23e69","571169879b0fdf2400175423","57116b4ff81a322500e71480","545ec477e7f60fd6c55760e9","545edba9e7f60fd6c5576133","545bb1181e649a4495f887df","5462491c688f333d05d8af38","54626472f3c64b7b0598590c","561d64faccb78c84055763d7","562101bf175b7286057ee23b","546283ddfdd66af405fa8209","54712072eb739dbc9d24034b","5469643c37600b40e0e09c5b","5442ba0e1e835500007eb1c7","54ac1d4865a9d9b862643853","54af3864956a2e58059c2215","5654b35c8b2ec1870555ee9c","556772755c27898a051398db","54c7b653d517a56707ac4342","56f0482f8b4a192400473747","56f09a6a1dbb2f4700e87573","54b591e553b18557057a38b1","54b71118a969b8ec07109b57","54dbb78c7a193d5705f26ae5","55144b509f0c4854051769c1","55538e646dcc398505796ceb","56fc56ac7cd2381f00d758b4","56ccc820d9fb1c250039a124","56e8626aecba2725002547fb","57152437af04592000698f28","5787f695d495562500f22329","5789166332a13a1f005e8ac0","5703d8007cd2381f00d95984","56e85c040c6e9f1f009861f3","57c49d577145332900f52045","57c4bb231ceb8c20000449a1","571800916d3e2720000ea0ad","571d7353c3bb5863006909b2","5727f5cd113c2d2500df87da","571a972ba88b162400c668a3","571e9d11a88b162400c757c6","571fb930860f4d20004de89a","57905f5c223c2e250084c930","578f1e1f637778350062fb23","573622cfaad7ed21002aff85","576965635d4a5f590042d842","575f467217440824004fde04","576822550228801f0024c7eb","576dbc10e1ea5d1f00887fa6","576d9ed701d8dd2e00963936","576daea7f2f0df36001c9f1c","5776e1f55cefe85c008b896c","57a182c58a46aa2000823210","57a8103979a0664400120db1","57b40d4a1fb6db20004d39e2","57b6b13a42fbc844002b11ff","57ba85deb11ac324001243e7","57bd45b84c52502400faee47","57bbe5f58a4d3d4500962f4a","57bec521a796322500e290ec","57c3d3aad924125b00d65bdd","57fdcfdda9ff402500b73b1c","581a66ad6ff06a2000d697e8","582b8d390ac0a11f0009af13","5829e67bb9bce324006069e9","5480b9d01bf0b10000711c5f","5480ba761bf0b10000711c64","56996044857edb1f00d970e9","548c82360ffdc235e80ef04b","569d3752d32e4c1f00763276","57321240d5d46b1f00595727","548c90020ffdc235e80ef0ad","571fddf784311b250055837c","56fbecff7aa4192500fae78c","548ce3300ffdc235e80ef0b2","548cef7f0ffdc235e80ef0cc","548cf1a90ffdc235e80ef0d1","549875268e52573b10d3bcd7","56a6c1918244c52500813bfe","548cf2850ffdc235e80ef0d6","549875428e52573b10d3bcd9","562fec61c0fcbd86057bf07d","57c67dbb44550e210083d5b2","54a0e0ed6fb0d331155bc72b","54a0e1276fb0d331155bc72e","56fd7783f448484b00d94ea2","54a0e19a6fb0d331155bc734","54a0e3896fb0d331155bc73a","54a0e3f46fb0d331155bc740","54a0e4256fb0d331155bc743","556c90aa5c27898a0516235d","54a968fcb2a4303d05d4cb4d","54a0e4576fb0d331155bc746","54b83c4f29843994803c8392","54b83c2629843994803c838e","54b83c5629843994803c8394","5584b03c2b0cc4bc05c3fc7a","54b83c1e29843994803c838c","57154aaef8de1e3500fd4c06","570fd3ab16594b2800f188c6","570542b72d457f2f00ca5195","5707cf3bd32e512400a9e1b5","5734bcfcc0ed732000d4559f","573e0842096b962600fe7610","57431ef203cbef2a00939517","57d135f64eaf3d9400802f81","57db91572d403f2400e51a5f","57df8437eeab762400e74357","57e0c1a529889d1f00eb99ed","57eeab99ea13c01f00c23c28"];

sum = 0;
db.levels.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (level) {
  if(!_.contains(levelOriginalsToDo, level.original+'')) {
    return
  }
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
  addThang(thangType, 'unlockLevelName')
})

translations = _.sortBy(translations, 'sortKey');
translations.forEach(function(tr) {
  print(tr.join('\n'));
});

print('\n\nUntranslated words: ' + untranslatedWords)
