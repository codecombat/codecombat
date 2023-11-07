// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainLadderView;
require('app/styles/play/tournament_home.sass');
const RootView = require('views/core/RootView');
const template = require('templates/play/tournament_home');
const LevelSession = require('models/LevelSession');
const Level = require('models/Level');
const Clan = require('models/Clan');
const Tournament = require('models/Tournament');
const forms = require('core/forms');
const CocoCollection = require('collections/CocoCollection');
const { HTML5_FMT_DATETIME_LOCAL } = require('core/constants');

class LevelSessionsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = LevelSession;
  }

  constructor(model) {
    super();
    this.url = `/db/user/${me.id}/level.sessions?project=state.complete,levelID`;
  }
}
LevelSessionsCollection.initClass();

class LadderCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = Level;
  }

  constructor(model) {
    super();
    this.url = "/db/level/-/arenas";
  }
}
LadderCollection.initClass();


module.exports = (MainLadderView = (function() {
  MainLadderView = class MainLadderView extends RootView {
    static initClass() {
      this.prototype.id = 'main-ladder-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .create-button': 'createTournament',
        'click .edit-button': 'editTournament',
        'click .input-submit': 'submitEditing',
        'click .input-cancel': 'cancelEditing'
      };
    }

    constructor (options, pageType, objectId) {
      super(options)
      let url;
      this.pageType = pageType;
      this.objectId = objectId;
      this.ladderLevels = [];
      this.ladderImageMap = {};
      this.tournaments = [];

      if (this.pageType === 'clan') {
        url = `/db/tournaments?clanId=${this.objectId}`;
        this.clan = this.supermodel.loadModel(new Clan({_id: this.objectId})).model;
        this.clan.once('sync', clan => {
          console.log(clan, this.clan);
          return this.renderSelectors('#ladder-list');
        });
      } else if (this.pageType === 'student') { // deprecated
        url = `/db/tournaments?memberId=${this.objectId}`;
      }
      const tournaments = new CocoCollection([], {url, model: Tournament});
      this.listenTo(tournaments, 'sync', () => {
        this.tournaments = (Array.from(tournaments.models).map((t) => t.toJSON()))[0];
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      this.supermodel.loadCollection(tournaments, 'tournaments', {cache: false});

      this.editableTournament = {};

      this.ladders = this.supermodel.loadCollection(new LadderCollection()).model;
      this.listenToOnce(this.ladders, 'sync', this.onLaddersLoaded);
    }

    getMeta() {
      return {title: $.i18n.t('ladder.title')};
    }

    cancelEditing(e) {
      if (this.editableTournament.editing === 'new') {
        this.tournaments[this.clan.get('name')].pop();
      } else {
        const index = _.findIndex(this.tournaments[this.clan.get('name')], t => t.editing === 'edit');
        delete this.tournaments[this.clan.get('name')][index].editing;
      }
      this.editableTournament = {};
      return this.renderSelectors('.tournament-container');
    }

    submitEditing(e) {
      const attrs = forms.formToObject($(e.target).closest('.editable-tournament-form'));
      attrs.startDate = moment(attrs.startDate).toISOString();
      attrs.endDate = moment(attrs.endDate).toISOString();
      if (attrs.resultsDate) {
        attrs.resultsDate = moment(attrs.resultsDate).toISOString();
      }
      Object.assign(this.editableTournament, attrs);
      if (this.editableTournament.editing === 'new') {
        return $.ajax({
          method: 'POST',
          url: '/db/tournament',
          data: this.editableTournament,
          success: () => {
            return document.location.reload();
          }
        });
      } else if (this.editableTournament.editing === 'edit') {
        return $.ajax({
          method: 'PUT',
          url: `/db/tournament/${this.editableTournament._id}`,
          data: this.editableTournament,
          success: () => {
            return document.location.reload();
          }
        });
      }
    }

    editTournament(e) {
      const tournament = $(e.target).data('tournament');
      if (this.editableTournament.levelOriginal != null) {
        return;
      }

      const index = _.findIndex(this.tournaments[this.clan.get('name')], t => t._id === tournament._id);
      this.tournaments[this.clan.get('name')][index].editing = 'edit';
      this.editableTournament = this.tournaments[this.clan.get('name')][index];
      return this.renderSelectors('.tournament-container');
    }

    createTournament(e) {
      const level = $(e.target).data('level');
      if (this.editableTournament.levelOriginal != null) {
        // TODO alert do not create multiple tournament at the same time
        return;
      }
      this.editableTournament = {
        name: level.name,
        levelOriginal: level.original,
        image: level.image,
        slug: level.id,
        clan: this.objectId,
        state: 'disabled',
        startDate: new Date(),
        endDate: undefined,
        resultsDate: undefined,
        editing: 'new'
      };
      this.tournaments[this.clan.get('name')].push(this.editableTournament);
      return this.renderSelectors('.tournament-container');
    }

    onLaddersLoaded(e) {
      const levels = [];
      for (var ladder of Array.from(this.ladders.models)) {
        levels.push({
          name: ladder.get('name'),
          id: ladder.get('slug'),
          image: ladder.get('image'),
          original: ladder.get('original')
        });
        this.ladderImageMap[ladder.get('original')] = ladder.get('image');
      }
      return this.ladderLevels = levels;
    }

    hasControlOfTheClan() {
      return me.isAdmin() || (((this.clan != null ? this.clan.get('ownerID') : undefined) + '') === (me.get('_id') + ''));
    }

    formatTime(time) {
      if (time != null) {
        return moment(time).format(HTML5_FMT_DATETIME_LOCAL);
      }
      return time;
    }
  };
  MainLadderView.initClass();
  return MainLadderView;
})());
