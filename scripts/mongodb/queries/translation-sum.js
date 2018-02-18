sum = 0;
add = function(s) {
  if (typeof s !== 'string')
    return;
  sum += s.split(' ').length;
};
load('node_modules/lodash/dist/lodash.js');

sum = 0;
db.levels.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (level) {
  print(level.name, sum);
  add(level.name);
  add(level.description);
  add(level.loadingTip);
  add(level.studentPlayInstructions);
  _.forEach(level.goals, function(goal) {
    add(goal.name)
  });
  if (level.documentation) {
    _.forEach(level.documentation.specificArticles, function(article) {
      add(article.name)
      add(article.body)
    })
    _.forEach(level.documentation.hints, function(hint) {
      add(hint.body)
    });
    _.forEach(level.documentation.hintsB, function(hint) {
      add(hint.body)
    });
  }
  _.forEach(level.scripts, function(script) {
    _.forEach(script.noteChain, function(noteGroup) {
      if (!noteGroup) return;
      _.forEach(noteGroup.sprites, function(spriteCommand) {
        if(spriteCommand.say) {
          add(spriteCommand.say.text)
          add(spriteCommand.say.blurb)
          if(spriteCommand.say.responses) {
            _.forEach(spriteCommand.say.responses, function(response) {
              add(response.text)
            })
          }
        }
      })
    })
  })
  if(level.victory) {
    add(level.victory.body)
  }
  _.forEach(level.thangs, function(thang) {
    _.forEach(thang.components, function(component) {
      if (component.config && component.config.programmableMethods) {
        _.forEach(component.config.programmableMethods, function(method) {
          _.forEach(method.context, function(value) {
            add(value);
          })
        })
      }
    })
  })
  _.forEach(level.thangs, function(thang) {
    _.forEach(thang.components, function(component) {
      if (component.config && component.config.context && component.config.i18n) {
        _.forEach(component.config.context, function(value) {
          add(value);
        })
      }
    })
  })
});
print('Level sum', sum);

sum = 0;
db.achievements.find().forEach(function (achievement) {
  add(achievement.name)
  add(achievement.description);
});
print('Achievement sum', sum);

sum = 0;
db.campaigns.find().forEach(function (campaign) {
  add(campaign.name);
  add(campaign.fullName);
  add(campaign.description);
})
print('Campaign sum', sum);

sum = 0;
db.level.components.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (levelComponent) {
  _.forEach(levelComponent.propertyDocumentation, function(propDoc) {
    add(propDoc.name)
    if(typeof propDoc.description === 'string')
      add(propDoc.description)
    else
      _.forEach(propDoc.description, function(description) {
        add(description);
      })
    _.forEach(propDoc.context, function(value) {
      add(value)
    })
    if(propDoc.returns) {
      if(typeof propDoc.returns.description === 'string')
        add(propDoc.returns.description)
      else
        _.forEach(propDoc.returns.description, function(value) {
          add(value);
        })
    }
    _.forEach(propDoc.args, function(argDoc) {
      if(typeof argDoc.description === 'string')
        add(argDoc.description)
      else
        _.forEach(argDoc.description, function(value) {
          add(value);
        })
    })
  })
});
print('Component sum', sum)

sum = 0;
db.courses.find().forEach(function (course) {
  add(course.name)
  add(course.description)
})
print('Course sum', sum);

sum = 0;
db.polls.find().forEach(function (poll) {
  add(poll.name)
  add(poll.description)
  _.forEach(poll.answers, function(answer) {
    add(answer.text)
  })
})
print('Poll sum', sum)

sum = 0;
db.thang.types.find({slug: {$exists: true}, i18nCoverage: {$exists:true }}).forEach(function (thangType) {
  add(thangType.name)
  add(thangType.description)
  add(thangType.extendedName)
  add(thangType.unlockLevelName)
})
print('Thang Type sum', sum);
