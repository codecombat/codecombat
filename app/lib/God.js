// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Each LevelView or Simulator has a God which listens for spells cast and summons new Angels on the main thread to
// oversee simulation of the World on worker threads. The Gods and Angels even have names. It's kind of fun.
// (More fun than ThreadPool and WorkerAgentManager and such.)

let God;
const {now} = require('lib/world/world_utils');
const World = require('lib/world/world');
const CocoClass = require('core/CocoClass');
const Angel = require('lib/Angel');
const GameUIState = require('models/GameUIState');
const errors = require('core/errors');
const globalVar = require('core/globalVar');

module.exports = (God = (function() {
  God = class God extends CocoClass {
    static initClass() {
      this.nicks = ['Athena', 'Baldr', 'Crom', 'Dagr', 'Eris', 'Freyja', 'Great Gish', 'Hades', 'Ishtar', 'Janus', 'Khronos', 'Loki', 'Marduk', 'Negafook', 'Odin', 'Poseidon', 'Quetzalcoatl', 'Ra', 'Shiva', 'Thor', 'Umvelinqangi', 'Týr', 'Vishnu', 'Wepwawet', 'Xipe Totec', 'Yahweh', 'Zeus', '上帝', 'Tiamat', '盘古', 'Phoebe', 'Artemis', 'Osiris', '嫦娥', 'Anhur', 'Teshub', 'Enlil', 'Perkele', 'Chaos', 'Hera', 'Iris', 'Theia', 'Uranus', 'Stribog', 'Sabazios', 'Izanagi', 'Ao', 'Tāwhirimātea', 'Tengri', 'Inmar', 'Torngarsuk', 'Centzonhuitznahua', 'Hunab Ku', 'Apollo', 'Helios', 'Thoth', 'Hyperion', 'Alectrona', 'Eos', 'Mitra', 'Saranyu', 'Freyr', 'Koyash', 'Atropos', 'Clotho', 'Lachesis', 'Tyche', 'Skuld', 'Urðr', 'Verðandi', 'Camaxtli', 'Huhetotl', 'Set', 'Anu', 'Allah', 'Anshar', 'Hermes', 'Lugh', 'Brigit', 'Manannan Mac Lir', 'Persephone', 'Mercury', 'Venus', 'Mars', 'Azrael', 'He-Man', 'Anansi', 'Issek', 'Mog', 'Kos', 'Amaterasu Omikami', 'Raijin', 'Susanowo', 'Blind Io', 'The Lady', 'Offler', 'Ptah', 'Anubis', 'Ereshkigal', 'Nergal', 'Thanatos', 'Macaria', 'Angelos', 'Erebus', 'Hecate', 'Hel', 'Orcus', 'Ishtar-Deela Nakh', 'Prometheus', 'Hephaestos', 'Sekhmet', 'Ares', 'Enyo', 'Otrera', 'Pele', 'Hadúr', 'Hachiman', 'Dayisun Tngri', 'Ullr', 'Lua', 'Minerva'];

      this.prototype.subscriptions = {
        'tome:cast-spells': 'onTomeCast',
        'tome:spell-debug-value-request': 'retrieveValueFromFrame',
        'god:new-world-created': 'onNewWorldCreated'
      };
    }

    constructor(options) {
      super();
      let angelCount;
      this.retrieveValueFromFrame = this.retrieveValueFromFrame.bind(this);
      this.onDebugWorkerMessage = this.onDebugWorkerMessage.bind(this);
      if (options == null) { options = {}; }
      this.retrieveValueFromFrame = _.throttle(this.retrieveValueFromFrame, 1000);
      if (this.gameUIState == null) { this.gameUIState = options.gameUIState || new GameUIState(); }
      this.capstoneStage = options.capstoneStage || 1;
      this.indefiniteLength = options.indefiniteLength || false;

      // Angels are all given access to this.
      this.angelsShare = {
        workerCode: options.workerCode || '/javascripts/workers/worker_world.js',  // Either path or function
        headless: options.headless,  // Whether to just simulate the goals, or to deserialize all simulation results
        spectate: options.spectate,
        god: this,
        godNick: this.nick,
        gameUIState: this.gameUIState,
        workQueue: [],
        firstWorld: true,
        world: undefined,
        goalManager: undefined,
        worldClassMap: undefined,
        angels: [],
        busyAngels: []  // Busy angels will automatically register here.
      };

      // Determine how many concurrent Angels/web workers to use at a time
      // ~20MB per idle worker + angel overhead - every Angel maps to 1 worker
      if (options.maxAngels != null) {
        angelCount = options.maxAngels;
      } else if (globalVar.application.isIPadApp) {
        angelCount = 1;
      } else if (this.indefiniteLength) {  // Don't do much with angels in game-dev, will mostly be synchronous
        angelCount = 1;
      } else {
        angelCount = 2;
      }

      // Don't generate all Angels at once.
      for (let i = 0, end = angelCount, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) { _.delay((() => { if (!this.destroyed) { return new Angel(this.angelsShare); } }), 250 * i); }
    }

    destroy() {
      for (var angel of Array.from(this.angelsShare.angels.slice())) { angel.destroy(); }
      if (this.angelsShare.goalManager != null) {
        this.angelsShare.goalManager.destroy();
      }
      if (this.debugWorker != null) {
        this.debugWorker.terminate();
      }
      if (this.debugWorker != null) {
        this.debugWorker.removeEventListener('message', this.onDebugWorkerMessage);
      }
      return super.destroy();
    }

    setLevel(level) {
      this.level = level;
    }
    setLevelSessionIDs(levelSessionIDs) {
      this.levelSessionIDs = levelSessionIDs;
    }
    setGoalManager(goalManager) {
      if (this.angelsShare.goalManager !== goalManager) { if (this.angelsShare.goalManager != null) {
        this.angelsShare.goalManager.destroy();
      } }
      this.angelsShare.goalManager = goalManager;
      const state = __guard__(__guard__(goalManager != null ? goalManager.options : undefined, x1 => x1.session), x => x.get("state"));
      if (state != null ? state.capstoneStage : undefined) {
        return this.capstoneStage = state.capstoneStage;
      }
    }

    setWorldClassMap(worldClassMap) { return this.angelsShare.worldClassMap = worldClassMap; }

    onTomeCast(e) {
      if (e.god !== this) { return; }
      this.lastSubmissionCount = e.submissionCount;
      this.lastFixedSeed = e.fixedSeed;
      this.lastFlagHistory = (Array.from(e.flagHistory).filter((flag) => flag.source !== 'code'));
      this.lastDifficulty = e.difficulty;
      return this.createWorld(e);
    }

    createWorld({spells, preload, realTime, justBegin, keyValueDb, synchronous, spellJustLoaded}) {
      let angel;
      console.log(`${this.nick}: Let there be light upon ${this.level.name}! (preload: ${preload})`);
      let userCodeMap = this.getUserCodeMap(spells);
      if (spellJustLoaded && !justBegin) {
        // If spellJustLoaded it signals that this is the first world after the level
        // was created. We want no user code to run on loading and no errors to show up.
        // Thus we unassign the user's code.
        // `justBegin` is set if the level is game-dev or capstone.
        // We have to do this because it appears the capstone breaks if the code is cleared.
        userCodeMap = {};
      }
      // We only want one world being simulated, so we abort other angels, unless we had one preloading this very code.
      let hadPreloader = false;
      for (angel of Array.from(this.angelsShare.busyAngels.slice())) {
        var isPreloading = angel.running && angel.work.preload && _.isEqual(angel.work.userCodeMap, userCodeMap, function(a, b) {
          if (((a != null ? a.raw : undefined) != null) && ((b != null ? b.raw : undefined) != null)) { return a.raw === b.raw; }
          return undefined;
        });  // Let default equality test suffice.
        if (!hadPreloader && isPreloading && !realTime) {
          angel.finalizePreload();
          hadPreloader = true;
        } else if (preload && angel.running && !angel.work.preload) {
          // It's still running for real, so let's not preload.
          return;
        } else {
          angel.abort();
        }
      }
      if (hadPreloader) { return; }

      this.angelsShare.workQueue = [];
      const work = {
        userCodeMap,
        level: this.level,
        levelSessionIDs: this.levelSessionIDs,
        submissionCount: this.lastSubmissionCount,
        fixedSeed: this.lastFixedSeed,
        flagHistory: this.lastFlagHistory,
        difficulty: this.lastDifficulty,
        capstoneStage: this.capstoneStage,
        goals: (this.angelsShare.goalManager != null ? this.angelsShare.goalManager.getGoals() : undefined),
        headless: this.angelsShare.headless,
        preload,
        synchronous: synchronous != null ? synchronous : (typeof Worker === 'undefined' || Worker === null),  // Profiling world simulation is easier on main thread, or we are IE9.
        realTime,
        justBegin,
        indefiniteLength: this.indefiniteLength && realTime,
        keyValueDb,
        language: me.get('preferredLanguage', true)  // TODO: get target user's language if we're simulating some other user's session?
      };
      this.angelsShare.workQueue.push(work);
      for (angel of Array.from(this.angelsShare.angels)) { angel.workIfIdle(); }
      return work;
    }

    getUserCodeMap(spells) {
      const userCodeMap = {};
      for (var spellKey in spells) {
        var spell = spells[spellKey];
        (userCodeMap[spell.thang.thang.id] != null ? userCodeMap[spell.thang.thang.id] : (userCodeMap[spell.thang.thang.id] = {}))[spell.name] = spell.thang.aether.serialize();
      }
      return userCodeMap;
    }


    //### New stuff related to debugging ####
    retrieveValueFromFrame(args) {
      if (this.destroyed) { return; }
      if (!args.thangID || !args.spellID || !args.variableChain) { return; }
      if (!this.currentUserCodeMap) { return console.error('Tried to retrieve debug value with no currentUserCodeMap'); }
      if (this.debugWorker == null) { this.debugWorker = this.createDebugWorker(); }
      if (args.frame == null) { args.frame = this.angelsShare.world.age / this.angelsShare.world.dt; }
      return this.debugWorker.postMessage({
        func: 'retrieveValueFromFrame',
        args: {
          userCodeMap: this.currentUserCodeMap,
          level: this.level,
          levelSessionIDs: this.levelSessionIDs,
          submissionCount: this.lastSubmissionCount,
          fixedSeed: this.fixedSeed,
          flagHistory: this.lastFlagHistory,
          difficulty: this.lastDifficulty,
          capstoneStage: this.capstoneStage,
          goals: (this.goalManager != null ? this.goalManager.getGoals() : undefined),
          frame: args.frame,
          currentThangID: args.thangID,
          currentSpellID: args.spellID,
          variableChain: args.variableChain
        }
      });
    }

    createDebugWorker() {
      const worker = new Worker('/javascripts/workers/worker_world.js');
      worker.addEventListener('message', this.onDebugWorkerMessage);
      worker.addEventListener('error', errors.onWorkerError);
      return worker;
    }

    onDebugWorkerMessage(event) {
      switch (event.data.type) {
        case 'console-log':
          return console.log(`|${this.nick}'s debugger|`, ...Array.from(event.data.args));
        case 'debug-value-return':
          return Backbone.Mediator.publish('god:debug-value-return', event.data.serialized, {god: this});
        case 'debug-world-load-progress-changed':
          return Backbone.Mediator.publish('god:debug-world-load-progress-changed', {progress: event.data.progress, god: this});
      }
    }

    onNewWorldCreated(e) {
      return this.currentUserCodeMap = this.filterUserCodeMapWhenFromWorld(e.world.userCodeMap);
    }

    filterUserCodeMapWhenFromWorld(worldUserCodeMap) {
      const newUserCodeMap = {};
      for (var thangName in worldUserCodeMap) {
        var thang = worldUserCodeMap[thangName];
        newUserCodeMap[thangName] = {};
        for (var spellName in thang) {
          var aether = thang[spellName];
          var shallowFilteredObject = _.pick(aether, ['raw', 'pure', 'originalOptions']);
          newUserCodeMap[thangName][spellName] = _.cloneDeep(shallowFilteredObject);
          newUserCodeMap[thangName][spellName] = _.defaults(newUserCodeMap[thangName][spellName], {
            flow: {},
            metrics: {},
            problems: {
              errors: [],
              infos: [],
              warnings: []
            },
            style: {}
          });
        }
      }
      return newUserCodeMap;
    }
  };
  God.initClass();
  return God;
})());


const imitateIE9 = false;  // (and in world_utils.coffee)
if (imitateIE9) {
  window.Worker = null;
  window.Float32Array = null;
}
  // Also uncomment vendor_with_box2d.js in index.html if you want Collision to run and Thangs to move.

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}