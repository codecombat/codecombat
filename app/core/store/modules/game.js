// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import levelSchema from 'schemas/models/level';

import api from 'core/api';
import utils from 'core/utils';
import aetherUtils from 'lib/aether_utils';

// TODO: Be explicit about the properties being stored
const emptyLevel = _.zipObject((Array.from(_.keys(levelSchema.properties)).map((key) => [key, null])));

// This module should eventually include things such as: session, player code, score, thangs, etc
export default {
  namespaced: true,
  state: {
    level: emptyLevel,
    hintsVisible: false,
    timesCodeRun: 0,
    timesAutocompleteUsed: 0,
    playing: false,
    tutorial: [],
    tutorialActive: false,
    codeBankOpen: false,
    clickedUpdateCapstoneCode: false,
    hasPlayedGame: false,
    // Source for solving the level, and number of times it has been used:
    levelSolution: {
      // Number of times state.levelSolution has been auto filled into the code editor.
      autoFillCount: 0,
      source: ''
    }
  },
  mutations: {
    setPlaying(state, playing) {
      return state.playing = playing;
    },
    setLevel(state, updates) {
      return state.level = $.extend(true, {}, updates);
    },
    setLevelSolution(state, solution) {
      return state.levelSolution = solution;
    },
    setHintsVisible(state, visible) {
      return state.hintsVisible = visible;
    },
    incrementTimesCodeRun(state) {
      return state.timesCodeRun += 1;
    },
    setTimesCodeRun(state, times) {
      return state.timesCodeRun = times;
    },
    incrementTimesAutocompleteUsed(state) {
      return state.timesAutocompleteUsed += 1;
    },
    setTimesAutocompleteUsed(state, times) {
      return state.timesAutocompleteUsed = times;
    },
    addTutorialStep(state, step) {
      if (state.tutorial.find(s => // There is a function property that needs to be omitted because they don't compare
      _.isEqual(_.omit(step, _.functions(step)), _.omit(s, _.functions(s))))) {
        return;
      }

      if (step.intro) {
        return state.tutorial = [step, ...Array.from(state.tutorial)];
      } else {
        return state.tutorial.push(step);
      }
    },
    resetTutorial(state, options) {
      if (options == null) { options = {}; }
      state.tutorialActive = false;
      if (options.keepIntro && (state.tutorial[0] != null ? state.tutorial[0].intro : undefined)) {
        return state.tutorial = [state.tutorial[0]];
      } else {
        return state.tutorial = [];
      }
    },
    setTutorialActive(state, tutorialActive) {
      return state.tutorialActive = tutorialActive;
    },
    setCodeBankOpen(state, open) {
      return state.codeBankOpen = open;
    },
    setClickedUpdateCapstoneCode(state, clicked) {
      return state.clickedUpdateCapstoneCode = clicked;
    },
    setHasPlayedGame(state, hasPlayed) {
      return state.hasPlayedGame = hasPlayed;
    }
  },
  actions: {
    // Idempotent, will not add the same step twice
    addTutorialStep({ commit, rootState, dispatch }, step) {
      // Turns voiceOver property into a function to play voice over if possible.

      if (step.voiceOver) {
        const soundIdPromise = dispatch('voiceOver/preload', step.voiceOver, { root: true });
        // Lazy function we can call to play the voice over.
        // TODO: Localize by passing in different file path based on i18n.
        step.playVoiceOver = () => dispatch('voiceOver/playVoiceOver', soundIdPromise, { root: true });
      }


      return commit('addTutorialStep', step);
    },
    setTutorialActive({ commit, rootState }, tutorialActive) {
      return commit('setTutorialActive', tutorialActive);
    },
    restartTutorial({ commit }) {
      commit('setTutorialActive', false);
      // Give it a moment to react first...
      return setTimeout(() => commit('setTutorialActive', true)
      , 500);
    },
    resetTutorial({ commit }, options) {
      return commit('resetTutorial', options);
    },
    // Idempotent, will not add the same step twice
    // Appends steps to the tutorial, extracting information from each say event in sayEvents
    addTutorialStepsFromSayEvents({ commit, rootState, dispatch }, sayEvents) {
      return sayEvents.forEach(function(sayEvent) {
        const { say, tutorial } = sayEvent;

        return dispatch('addTutorialStep', {
          message: utils.i18n(say, 'text'),
          // To stay backwards compatible with old Vega messages,
          // they are turned into stationary Vega messages with no other qualities:
          position: (tutorial != null ? tutorial.position : undefined) || 'stationary',
          targetElement: (tutorial != null ? tutorial.targetElement : undefined),
          animation: (tutorial != null ? tutorial.animation : undefined),
          targetLine: (tutorial != null ? tutorial.targetLine : undefined),
          targetThangs: (tutorial != null ? tutorial.targetThangs : undefined),
          grayOverlay: (tutorial != null ? tutorial.grayOverlay : undefined),
          advanceOnTarget: (tutorial != null ? tutorial.advanceOnTarget : undefined),
          internalRelease: (tutorial != null ? tutorial.internalRelease : undefined),
          voiceOver: say.voiceOver
        });
      });
    },
    toggleCodeBank({ commit, rootState }) {
      return commit('setCodeBankOpen', !rootState.game.codeBankOpen);
    },
    setClickedUpdateCapstoneCode({ commit }, clicked) {
      return commit('setClickedUpdateCapstoneCode', clicked);
    },
    setHasPlayedGame({ commit }, hasPlayed) {
      return commit('setHasPlayedGame', hasPlayed);
    },
    autoFillSolution({ commit, rootState }, codeLanguage) {
      let component, e, hero, jsSource, plan, rawSource, solutions, source;
      if (utils.isCodeCombat) {
        if (codeLanguage == null) { let left;
        codeLanguage = (left = utils.getQueryVariable('codeLanguage')) != null ? left : 'javascript'; } // Belongs in Vuex eventually
        const noSolution = function() {
          const text = `No ${codeLanguage} solution available for ${rootState.game.level.name}.`;
          noty({ text, timeout: 3000 });
          return console.error(text);
        };

        if (!(hero = _.find((rootState.game.level != null ? rootState.game.level.thangs : undefined) != null ? (rootState.game.level != null ? rootState.game.level.thangs : undefined) : [], {id: 'Hero Placeholder'}))) {
          noSolution();
          return;
        }

        if (!(component = _.find(hero.components != null ? hero.components : [], c => __guard__(__guard__(c != null ? c.config : undefined, x1 => x1.programmableMethods), x => x.plan)))) {
          noSolution();
          return;
        }

        ({
          plan
        } = component.config.programmableMethods);

        solutions = _.filter(((plan != null ? plan.solutions : undefined) != null ? (plan != null ? plan.solutions : undefined) : []), s => !s.testOnly && s.succeeds);
        rawSource = __guard__(_.find(solutions, {language: codeLanguage}), x => x.source);
        if (!rawSource && (jsSource = __guard__(_.find(solutions, {language: 'javascript'}), x1 => x1.source))) {
          // If there is no target language solution yet, generate one from JavaScript.
          rawSource = aetherUtils.translateJS(jsSource, codeLanguage);
        }

        if (!rawSource) {
          noSolution();
          return;
        }

        try {
          source = _.template(rawSource)(utils.i18n(plan, 'context'));
        } catch (error) {
          e = error;
          console.error(`Cannot auto fill solution: ${e.message}`);
        }

        if (_.isEmpty(source)) {
          noSolution();
          return;
        }

        return commit('setLevelSolution', {
          autoFillCount: rootState.game.levelSolution.autoFillCount + 1,
          source
        });
      } else { // Ozaria
        try {
          hero = _.find(((rootState.game.level != null ? rootState.game.level.thangs : undefined) != null ? (rootState.game.level != null ? rootState.game.level.thangs : undefined) : []), {id: 'Hero Placeholder'});
          component = _.find(hero.components != null ? hero.components : [], x => __guard__(__guard__(x != null ? x.config : undefined, x3 => x3.programmableMethods), x2 => x2.plan));
          plan = __guard__(component.config != null ? component.config.programmableMethods : undefined, x2 => x2.plan);
          solutions = _.filter(((plan != null ? plan.solutions : undefined) != null ? (plan != null ? plan.solutions : undefined) : []), s => !s.testOnly && s.succeeds);
          rawSource = __guard__(_.find(solutions, {language: codeLanguage}), x3 => x3.source);
          if (!rawSource && (jsSource = __guard__(_.find(solutions, {language: 'javascript'}), x4 => x4.source))) {
  // If there is no target language solution yet, generate one from JavaScript.
            rawSource = aetherUtils.translateJS(jsSource, codeLanguage);
          }
          const external_ch1_avatar = __guard__(rootState.me.ozariaUserOptions != null ? rootState.me.ozariaUserOptions.avatar : undefined, x5 => x5.avatarCodeString) != null ? __guard__(rootState.me.ozariaUserOptions != null ? rootState.me.ozariaUserOptions.avatar : undefined, x5 => x5.avatarCodeString) : 'crown';
          const context = _.merge({ external_ch1_avatar }, utils.i18n(plan, 'context'));
          source = _.template(rawSource)(context);

          if (!_.isEmpty(source)) {
            return commit('setLevelSolution', {
              autoFillCount: rootState.game.levelSolution.autoFillCount + 1,
              source
            });
          } else {
            noty({ text: "No solution available.", timeout: 3000 });
            return console.error(`Could not find solution for ${rootState.game.level.name}`);
          }
        } catch (error1) {
          e = error1;
          const text = `Cannot auto fill solution: ${e.message}`;
          console.error(text);
          return noty({ type: 'error', text });
        }
      }
    }
  },
  getters: {
    codeBankOpen(state) { return state.codeBankOpen; },
    tutorialSteps(state) { return state.tutorial; },
    tutorialActive(state) { return state.tutorialActive; },
    clickedUpdateCapstoneCode(state) { return state.clickedUpdateCapstoneCode; },
    hasPlayedGame(state) { return state.hasPlayedGame; },
    levelSolution(state) { return state.levelSolution; }
  }
};

Backbone.Mediator.subscribe('level:set-playing', function(e) {
  let left;
  const playing = (left = (e != null ? e : {}).playing) != null ? left : true;
  return application.store.commit('game/setPlaying', playing);
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}