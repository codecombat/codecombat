langCode = 'he';
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

  // Google Docs: =SUBSTITUTE(SUBSTITUTE(F2, "\n", char(10)), "XX", CHAR(34))
  // Excel: =SUBSTITUTE(E1, "\n", CHAR(10) & CHAR(13))
  var translation = [[docType, doc._id+'', doc.original ? doc.original+'' : '', path, JSON.stringify(englishString), JSON.stringify(translationString)].join('\t')]
  translation.sortKey = englishString.length;
  translations.push(translation);
}

// var C = db.campaigns.find().toArray();
// C.forEach(function(c, i) { print(i, c.name); });
// var todo = [C[4], C[6], C[18], C[16], C[7], C[3], C[25], C[17], C[8], C[9], C[0], C[11], C[12]];
// var originalsOrdered = [];
// todo.forEach(function(c) { for(var orig in c.levels) { if(originalsOrdered.indexOf(orig) == -1) originalsOrdered.push(orig); } });
// JSON.stringify(originalsOrdered)

levelOriginalsToDo = ["5411cb3769152f1707be029c","54173c90844506ae0195a0b4","54ca592de4983255055a5478","544a98f62d002f0000fe331a","54174347844506ae0195a0b8","54cfc6e2d06e8152051eb8a4","54527a6257e83800009730c7","545287ef57e83800009730d5","54caa542e1bd9a4f054648b0","541875da4c16460000ab990f","580aaafe990e3e1f00bde535","5452972f57e83800009730de","54d4fbb571f9c75605f48cab","54dbd516c81bd84f0580eb72","5418aec24c16460000ab9aa6","57aa1bd5e5636725008854c0","5604169b60537b8705386a59","55ca293b9bc1892c835b0136","565ce2291b940587057366dd","577bd1aad2429735002ec11e","545a5914d820eb0000f6dc0a","5452a84d57e83800009730e4","5418b9d64c16460000ab9ab4","5418cf256bae62f707c7e1c3","5418d40f4c16460000ab9ac2","54e0cdefe308cb510555a7f5","579ff2dc9872641f0080fdbb","57a0ca57f380c44400809a08","54e8e4047578d754057f852b","5452adea57e83800009730ee","577a8ad935ea2e240036f78a","5452c3ce57e83800009730f7","541b24511ccc8eaae19f3c1f","574b6ef42f39f92500d7c602","541b288e1ccc8eaae19f3c25","5452cfa706a59e000067e4f5","558c3967fa305a734ad31df3","55ca29439bc1892c835b0137","541b434e1ccc8eaae19f3c33","5452d8b906a59e000067e4fa","57ba850b054cbb2a005d8196","57ba8b472048774c002a12ac","54d24c49bf87255405a8f834","541c9a30c6362edfb0f34479","54c6eb5bdaee655705c4903f","54b83c4829843994803c8390","544437e0645c0c0000c3291d","54f0e074a375e47f055d619c","54eeed2f8f031352052adbe0","55525bcaaf92058705a94c02","555cdf77660fce85052f8451","55d4b3b4777137aeec7ccd23","57ee6f5786cf4e1f00afca2c","5630eab0c0fcbd86057cc2f8","57631f015c84de2900c16e96","579b5c4e0c1b3e2e003b91b9","578e46aee3da902e000febad","5798fa8a5fb5352000c37259","5799384253c50029006894bc","579f764a2c39c529005f9a0c","579fa0caea84d72400f340f1","57aa3176e56367250088c622","57e95b8c99d82f5a00b9f298","579926ba2a74512000eb28f3","578e667ea1d67529004601b5","578e6cb14bef0f240078f38a","578e76bf4bef0f2400790fc0","57910175111d2f2100666f5a","57912f346829762f001996f9","5776a8cc4efd897b00abf3a8","5797db9b1ac4c925005a64ab","579a9d20563faa25008dc1f5","579f95a353b4b61f00f00405","579a47b957c475240034ad30","579fae53d4d20d2e0078a943","57a3816be55d881f00445b92","579a823057c475240034ebca","541b67f71ccc8eaae19f3c62","563395519f27008605102abf","576daea7f2f0df36001c9f1c","576d9ed701d8dd2e00963936","582f37b994ac921f002a030c","54b363307961bdef1c751988","5487330d84f7b4dac246d440","57698793c10c132f00a0eb68","576822550228801f0024c7eb","575f467217440824004fde04","582b8d390ac0a11f0009af13","546e91b8a4b7840000ee92dc","5447030525cce60000745e2a","5448330517d7283e051f9b9e","5456b3c8d5ada30000525605","5456bb8dd5ada30000525613","581a66ad6ff06a2000d697e8","568c2687f9563045007bb6d8","57a37339161e7d20002d82e0","57a3d12b89fd5a24006453d4","54c6ae6475679bbd0f383e77","545ec477e7f60fd6c55760e9","545edba9e7f60fd6c5576133","5776e1f55cefe85c008b896c","5654b35c8b2ec1870555ee9c","556772755c27898a051398db","54c7b653d517a56707ac4342","57b0b3a68a0d832000e0859f","57b0bf2b56814d2500b84acb","56e8626aecba2725002547fb","578d5ec05c86b21f00820e94","5795070ce0ab2d26009eb815","57152437af04592000698f28","5787f695d495562500f22329","5789166332a13a1f005e8ac0","57ad9cbe1d791b200005478f","57b0501b9c524e24004bb0db","57b14f822e1d7f2000aaddf8","5703d8007cd2381f00d95984","56e85c040c6e9f1f009861f3","57c49d577145332900f52045","57c4bb231ceb8c20000449a1","56f0482f8b4a192400473747","57862f8ea6c64135009089e3","57879f1c24a2401f0049267c","573622cfaad7ed21002aff85","57f4dea3849cb124001e69a9","57f5de857ae3772e00ba23a9","57b40d4a1fb6db20004d39e2","57b6b13a42fbc844002b11ff","57ba85deb11ac324001243e7","576965635d4a5f590042d842","57bd45b84c52502400faee47","57bec521a796322500e290ec","57bbe5f58a4d3d4500962f4a","57c3d3aad924125b00d65bdd","57a8b3f0628da84500105220","5578843e5cda3d8905654190","5446cb40ce01c23e05ecf027","58deb6f1b9f39b2e00b4257c","546e97033f1c1c1be898402b","54b3591c7961bdef1c751977","54b361697961bdef1c751985","562fb9f5c0fcbd86057b8cd9","590fa5d6b31824370027ce18","54bbeb9f2542125305f07044","5470001860f6cc376131525d","54701f7860f6cc37613152a1","5470291c60f6cc37613152d1","5470b98ceb739dbc9d2402c7","5470ca33eb739dbc9d2402ee","5470d013eb739dbc9d240323","566765a549fc122e001df32a","5459570bb4461871053292f5","55144b509f0c4854051769c1","58ee003a3683d82e000d43f1","57b2a65d7583a91f00ac98fa","56f1b44cb4799ca2005dea75","56f09a6a1dbb2f4700e87573","56fc56ac7cd2381f00d758b4","56fd7e2c9026fb240057103c","56ccc820d9fb1c250039a124","56955f09efb7a92400fcc2da","5705b1a6a904662500f23e69","571169879b0fdf2400175423","57116b4ff81a322500e71480","57fdcfdda9ff402500b73b1c","57ff20f8b75fca21000251d0","58008e538b0a3c2900addaae","57905f5c223c2e250084c930","5922c3d8c68f90002f8c04c3","546283ddfdd66af405fa8209","578f1e1f637778350062fb23","571fb930860f4d20004de89a","5791c20bcbf7c6200034ad4c","5795e151aff3762500d05906","571a972ba88b162400c668a3","579af675563faa25008e45d6","579ee4daf380c444007c8022","57a182c58a46aa2000823210","57a8103979a0664400120db1","57a33544161e7d20002ccfdf","57a44f756254c62500592700","5829e67bb9bce324006069e9","571e9d11a88b162400c757c6","57984cbbff77551f009ffb46","5799b731b468cc25007f91ea","571800916d3e2720000ea0ad","571d7353c3bb5863006909b2","5727f5cd113c2d2500df87da","545bb1181e649a4495f887df","5462491c688f333d05d8af38","54626472f3c64b7b0598590c","54626f270cacde3f055434ac","561d64faccb78c84055763d7","54b591e553b18557057a38b1","562101bf175b7286057ee23b","54b71118a969b8ec07109b57","54b4f8f3d607f0663a9ae9ea","54b66deb26f3d652051a957b","54b866420798d452054d5993","54b174f85571fb53059f0207","54b611288f3ce555059d986d","54712072eb739dbc9d24034b","54dbb78c7a193d5705f26ae5","54e69740ceab105605eebfb6","5508cd4c754023ec15cd9929","55538e646dcc398505796ceb","551651d24e83223605e79464","5442ba0e1e835500007eb1c7","54ac1d4865a9d9b862643853","54af3864956a2e58059c2215","5469643c37600b40e0e09c5b","5792b409e0ab2d26009cf0d8","57acd55077f9402a00141401","57eea9868d5f2e240010ad64","57926929aff3762500cd5898","57b5cd5941333e2000b937c8","57b72baa548abd1f003bcaf4","57ee275a4c6244420075ebf8","57eef1628d5f2e2400121ccf","581740b8f789362000060449","57b71dce7a14ff35003a8f71","57a0f5a29872641f008221f2","57a0f75f38fe562e00142e8d","57a0f6d4dbb7a3240080af92","57a0f7991880ab2400e46162","57a0f7cc75334e2500aaf919","57a0f7f675334e2500aaf91b","57a0f82e83d65729005379c4","57a0f870bad3071f001b18d4","57a0f89edbb7a3240080af95","57a0f8d0dbb7a3240080af97","57ae02ef9c524e24004a982d","579fd557d4d20d2e0078cfa6","57b391345745be2500a1ec64","57b4afb26aec842500d5a81b","57b4a264bf1a942500cb1523","57b4e655d82d932e0099b14e","57acdf128455af2f00bf0d7f","57b5f8d97697232400aff91d","57acf3eee9d6ac2400df8393","57ad0d485c07bf1f002618f2","57b5fcc976b0a01f0032e3b0","57994ce51ac4c925005cf5a0","5480b9d01bf0b10000711c5f","5480ba761bf0b10000711c64","548c82360ffdc235e80ef04b","548c8f4a0ffdc235e80ef0a8","57321240d5d46b1f00595727","548c90020ffdc235e80ef0ad","56ba256117b8c3200095e4cb","5490cb7c623b972aa26b25a3","56fbecff7aa4192500fae78c","548ce3300ffdc235e80ef0b2","548cf1a90ffdc235e80ef0d1","57179e4ed3784c2100d37b07","571fddf784311b250055837c","549875268e52573b10d3bcd7","549875428e52573b10d3bcd9","562fec61c0fcbd86057bf07d","57e248eda8c1c11f001a3fed","57ee56d812ad92240072c440","57f2394812ad9224007b49cc","57ecdb7012ad9224006ca3df","57e392dc0abd872400143c39","58259fd79a8ab4200090a6fb","57f6176fe3daac3d00fbc6cf","5654bff0ec3aad88052b7355","54a0e1276fb0d331155bc72e","57c67dbb44550e210083d5b2","57c7c97865e150240069c650","57c922bc3b42e9210049a493","54a0e0ed6fb0d331155bc72b","54a0e15b6fb0d331155bc731","57cd119487eb605b0027e02b","57d135f64eaf3d9400802f81","57d659a0f38c9a2500b13d49","57d78a4c7dfc182000ad7bd0","57d8d4c220d0303300f8cbb8","54a0e19a6fb0d331155bc734","57df8437eeab762400e74357","57e0c1a529889d1f00eb99ed","54a0e3896fb0d331155bc73a","54a0e3bb6fb0d331155bc73d","54a0e3f46fb0d331155bc740","54a0e4256fb0d331155bc743","57db91572d403f2400e51a5f","556c90aa5c27898a0516235d","54a0e3426fb0d331155bc737","54a0e4576fb0d331155bc746","570fd3ab16594b2800f188c6","54b83bdb29843994803c8384","573e0842096b962600fe7610","54b8444429843994803c8396","54b8444b29843994803c8398","54b8445929843994803c839a","54b8446b29843994803c839e","54b8447d29843994803c83a0","550843b2060ceb170dca08ee","550c58512f58ba7a05415b4f","5514315c9f0c485405175773","550b086254a3637905993152","551ab8064c7305350525b389","57bf2ec5ebcf472500b135e9","5480b62e1bf0b10000711c59","56996044857edb1f00d970e9","5881aab92470df2500a41c6f","5892d336cc6a1e1b00477d3b","569d3752d32e4c1f00763276","57bd43b5a27a311f00dbec73","54baafc26ef7bdde070f2058","572e101c4ef43457019391ec","548cef7f0ffdc235e80ef0cc","54c83e88d517a56707adef71","58760c02be1e361f00904a0c","58788ea18aee482a00790161","587cb0b931c3fd20009f8401","593a2c18969521002076fca4","56a6c1918244c52500813bfe","572922f45182d12a00b6ca53","5498cf468e52573b10d3bd15","54bf095577d3005005c24481","58884fa78ef4b129006389f7","56fd7783f448484b00d94ea2","570542b72d457f2f00ca5195","5707cf3bd32e512400a9e1b5","57eeab99ea13c01f00c23c28","58347fa5069ce224002c4d5c","5941242d2cce74002bac80ee","59257c37aac647002baeae34","561bf0f9cdbad186055fc975","54a968fcb2a4303d05d4cb4d","587f2d471657a82500669ada","58859852b0f45c2f00ecd70e","54b83bf629843994803c8386","54b83c0a29843994803c8388","54b83c1429843994803c838a","55f5ae4230825985054bc4aa","594754eb1b1192003050c94d","595cbe09ca6b41002b67497e","57154aaef8de1e3500fd4c06","5954dd6a5becda003036f18a","5734bcfcc0ed732000d4559f","57431ef203cbef2a00939517","54b83c1e29843994803c838c","5584b03c2b0cc4bc05c3fc7a","5702b28b263b0220002cb0cb","548cf2850ffdc235e80ef0d6","54c30c1b08652d5305476fca","54b83c5629843994803c8394","54b83c4f29843994803c8392","54b83c2629843994803c838e","5522b98685fca53105544b53","55284f6f9a3631cf0eeb17af","552fe281130975b105e28551","553e452f68cd1887059406fb","55240efd3c19a4380597899f","5537b74bc8957187058aa245","55357df2cf20078a052c40ec","55269f6e047ae64e080b30aa","55351dc7d825368013088f24","552d164522b7474507f720d6","57190b869857762f00b601d9","57275fd2113c2d2500df2ae7","57206894ee2fc7200079fd4b","57545ddb307ab14500c737fe","575e79119722c21f00d9ceb0","57227d0b983aee2400412e2f","574eca895f51bc2500296ccb","576a767a6f000f3500b885f0","57486fab5c91da24009c38ff","57458980b54f652100524d40","576d60eb01d8dd2e0095f309","5763f84a216fb12400c815c0","5783305a03f4931f0056af3b","5702c5767cd2381f00d9060d","578b59589895c3210008800d","577502e04fe71e2700833897","5779f819fd900f7b003155f5","57436b7f096b9626000096be","57326baed5d46b1f00598d02","57311b50065e011f005d4bb3","57320afad92d0029009497b9","5739b01a7e450d26009631c0","570bd75453f0292e00c1bfbf","5548e492bea2548d0543da2e","5550f05bccf4f68605a5a0b7","577ca2d57e0491260072592f","575ff04a55929d2900aecceb","57322e8effd91c2e00e031b6","570c16c45e22972400568965","573a3cfe67df441f00c6a8d9","5575b4fe3fee028a059884f1","557731fb1b18498705ddcb91","573c4aa28edc9c1f009dbc54","577e74de1f0ada24007f8856","570bfbd5a060161f001c0cbc","57594e78b0634f2500493cb9","571658f1f8de1e3500fdb491","57677ccb7389922100801acf","579738f118e55625000e79cc"]

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
