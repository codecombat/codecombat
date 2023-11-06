// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainAdminView;
require('app/styles/admin.sass');
const {backboneFailure, genericFailure} = require('core/errors');
const errors = require('core/errors');
const RootView = require('views/core/RootView');
const template = require('app/templates/admin');
const AdministerUserModal = require('views/admin/AdministerUserModal');
const MaintenanceModal = require('views/admin/MaintenanceModal');
const TeacherLicenseCodeModal = require('views/admin/TeacherLicenseCodeModal');
const ModelModal = require('views/modal/ModelModal');
const forms = require('core/forms');
const utils = require('core/utils');
const { updateAvailabilityStatus, getAvailability } = require('core/api/parents');

const Campaigns = require('collections/Campaigns');
const Classroom = require('models/Classroom');
const CocoCollection = require('collections/CocoCollection');
const Course = require('models/Course');
const Courses = require('collections/Courses');
const LevelSessions = require('collections/LevelSessions');
const InteractiveSessions = require('collections/InteractiveSessions');
const Prepaid = require('models/Prepaid');
const User = require('models/User');
const Users = require('collections/Users');
const Mandate = require('models/Mandate');
const momentTimezone = require('moment-timezone');
if (window.saveAs == null) { window.saveAs = require('file-saver/FileSaver.js'); } // `window.` is necessary for spec to spy on it
if (window.saveAs.saveAs) { window.saveAs = window.saveAs.saveAs; }  // Module format changed with webpack?

module.exports = (MainAdminView = (function() {
  MainAdminView = class MainAdminView extends RootView {
    constructor(...args) {
      super(...args);
      this.onSearchRequestSuccess = this.onSearchRequestSuccess.bind(this);
      this.onSearchRequestFailure = this.onSearchRequestFailure.bind(this);
      this.onClickFreeSubLink = this.onClickFreeSubLink.bind(this);
      this.onClickToggleAdminAvailability = this.onClickToggleAdminAvailability.bind(this);
      this.onClickTerminalSubLink = this.onClickTerminalSubLink.bind(this);
      this.onClickTerminalActivationLink = this.onClickTerminalActivationLink.bind(this);
      this.editMandate = this.editMandate.bind(this);
      if (window.serverSession.amActually) {
        this.amActually = new User({_id: window.serverSession.amActually});
        this.amActually.fetch();
        this.supermodel.trackModel(this.amActually);
      }
      this.featureMode = window.serverSession.featureMode;
      if (me.isParentAdmin()) {
        this.checkParentAdminAvailability();
      }
      this.timeZone = (typeof features !== 'undefined' && features !== null ? features.chinaInfra : undefined) ? 'Asia/Shanghai' : 'America/Los_Angeles';
      this.prepaidEndDate = momentTimezone().tz(this.timeZone).add(1, 'year').format('YYYY-MM-DD');
    }

    static initClass() {
      this.prototype.id = 'admin-view';
      this.prototype.template = template;
      this.prototype.lastUserSearchValue = '';

      this.prototype.events = {
        'submit #espionage-form': 'onSubmitEspionageForm',
        'submit #user-search-form': 'onSubmitUserSearchForm',
        'click #stop-spying-btn': 'onClickStopSpyingButton',
        'click #increment-button': 'incrementUserAttribute',
        'click .user-spy-button': 'onClickUserSpyButton',
        'click .teacher-dashboard-button': 'onClickTeacherDashboardButton',
        'click #user-search-result': 'onClickUserSearchResult',
        'click #create-free-sub-btn': 'onClickFreeSubLink',
        'click #terminal-create': 'onClickTerminalSubLink',
        'click #terminal-activation-create': 'onClickTerminalActivationLink',
        'click .classroom-progress-csv': 'onClickExportProgress',
        'click #clear-feature-mode-btn': 'onClickClearFeatureModeButton',
        'click .edit-mandate': 'onClickEditMandate',
        'click #maintenance-mode': 'onClickMaintenanceMode',
        'click #teacher-license-code': 'onClickTeacherLicenseCode',
        'click #toggle-admin-availability': 'onClickToggleAdminAvailability'
      };
    }

    getTitle() { return $.i18n.t('account_settings.admin'); }

    checkParentAdminAvailability() {
      this.parentAdminUpdateInProgress = true;
      return getAvailability()
      .then(({adminAvailabilityStatus}) => {
        this.parentAdminAvailabilityStatus = adminAvailabilityStatus;
        this.parentAdminUpdateInProgress = false;
        return this.render();
      });
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.parentAdminAvailabilityStatus = this.parentAdminAvailabilityStatus || 'on';
      context.parentAdminUpdateInProgress = this.parentAdminUpdateInProgress || false;
      return context;
    }

    afterInsert() {
      let search, spy, userID;
      super.afterInsert();
      if (search = utils.getQueryVariable('search')) {
        $('#user-search').val(search);
        $('#user-search-button').click();
      }
      if (spy = utils.getQueryVariable('spy')) {
        if (this.amActually) {
          this.stopSpying();
        } else {
          $('#espionage-name-or-email').val(spy);
          $('#enter-espionage-mode').click();
        }
      }
      if ((me.isAdmin() || me.isOnlineTeacher()) && (userID = utils.getQueryVariable('user'))) {
        return this.openModalView(new AdministerUserModal({}, userID));
      }
    }

    clearQueryParams() { return window.history.pushState({}, '', document.location.href.split('?')[0]); }

    stopSpying() {
      const button = this.$('#stop-spying-btn');
      return me.stopSpying({
        success() { return document.location.reload(); },
        error() {
          forms.enableSubmit(button);
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }

    onClickStopSpyingButton() {
      const button = this.$('#stop-spying-btn');
      forms.disableSubmit(button);
      this.clearQueryParams();
      return this.stopSpying();
    }

    onClickClearFeatureModeButton(e) {
      e.preventDefault();
      return application.featureMode.clear();
    }

    onSubmitEspionageForm(e) {
      e.preventDefault();
      const button = this.$('#enter-espionage-mode');
      const userNameOrEmail = this.$el.find('#espionage-name-or-email').val().toLowerCase().trim();
      forms.disableSubmit(button);
      this.clearQueryParams();
      return me.spy(userNameOrEmail, {
        success() { return window.location.reload(); },
        error() {
          forms.enableSubmit(button);
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }

    onClickUserSpyButton(e) {
      e.stopPropagation();
      const userID = $(e.target).closest('tr').data('user-id');
      const button = $(e.currentTarget);
      forms.disableSubmit(button);
      return me.spy(userID, {
        success() { return window.location.reload(); },
        error() {
          forms.enableSubmit(button);
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }

    onClickTeacherDashboardButton(e) {
      e.stopPropagation();
      const userID = $(e.target).closest('tr').data('user-id');
      const button = $(e.currentTarget);
      forms.disableSubmit(button);
      const url = `/teachers/classes?teacherID=${userID}`;
      return application.router.navigate(url, { trigger: true });
    }

    onSubmitUserSearchForm(e) {
      e.preventDefault();
      const searchValue = this.$el.find('#user-search').val().trim();
      if (searchValue === this.lastUserSearchValue) { return; }
      if (!(this.lastUserSearchValue = searchValue.toLowerCase())) { return this.onSearchRequestSuccess([]); }
      forms.disableSubmit(this.$('#user-search-button'));
      let q = this.lastUserSearchValue;
      let role = undefined;
      q = q.replace(/role:([^ ]+) /, function(dummy, m1) {
        role = m1;
        return '';
      });

      const data = {adminSearch: q};
      if (role != null) { data.role = role; }
      return $.ajax({
        type: 'GET',
        url: '/db/user',
        data,
        success: this.onSearchRequestSuccess,
        error: this.onSearchRequestFailure
      });
    }

    onSearchRequestSuccess(users) {
      forms.enableSubmit(this.$('#user-search-button'));
      let result = '';
      if (users.length) {
        result = [];
        for (var user of Array.from(users)) {
          var trialRequestBit;
          if (user._trialRequest) {
            trialRequestBit = `<br/>${user._trialRequest.nces_name || user._trialRequest.organization} / ${user._trialRequest.nces_district || user._trialRequest.district}`;
          } else {
            trialRequestBit = "";
          }

          result.push(`\
<tr data-user-id='${user._id}'> \
<td><code>${user._id}</code></td> \
<td>${user.role || ''}</td> \
<td><img src='/db/user/${user._id}/avatar?s=18' class='avatar'> ${_.escape(user.name || 'Anonymous')}</td> \
<td>${_.escape(user.email)}${trialRequestBit}</td> \
<td>${user.firstName || ''}</td> \
<td>${user.lastName || ''}</td> \
<td> \
${me.isAdmin() ? "<button class='user-spy-button'>Spy</button>" : ""} \
<!-- New Teacher Dashboard doesn't allow admin to navigate to a teacher classroom. --> \
${new User(user).isTeacher() && !utils.isOzaria ? "<button class='teacher-dashboard-button'>View Classes</button>" : ""} \
</td> \
</tr>`);
        }
        result = `<table class=\"table\">${result.join('\n')}</table>`;
      }
      return this.$el.find('#user-search-result').html(result);
    }

    onSearchRequestFailure(jqxhr, status, error) {
      if (this.destroyed) { return; }
      forms.enableSubmit(this.$('#user-search-button'));
      return console.warn(`There was an error looking up ${this.lastUserSearchValue}:`, error);
    }

    incrementUserAttribute(e) {
      const val = $('#increment-field').val();
      me.set(val, me.get(val) + 1);
      return me.save();
    }

    onClickUserSearchResult(e) {
      const userID = $(e.target).closest('tr').data('user-id');
      if (userID) { return this.openModalView(new AdministerUserModal({}, userID)); }
    }

    onClickFreeSubLink(e) {
      delete this.freeSubLink;
      if (!me.isAdmin()) { return; }
      const options = {
        url: '/db/prepaid/-/create',
        data: {type: 'subscription', maxRedeemers: 1},
        method: 'POST'
      };
      options.success = (model, response, options) => {
        // TODO: Don't hardcode domain.
        if (application.isProduction()) {
          this.freeSubLink = `https://codecombat.com/account/subscription?_ppc=${model.code}`;
        } else {
          this.freeSubLink = `http://localhost:3000/account/subscription?_ppc=${model.code}`;
        }
        return (typeof this.render === 'function' ? this.render() : undefined);
      };
      options.error = (model, response, options) => {
        return console.error('Failed to create prepaid', response);
      };
      return this.supermodel.addRequestResource('create_prepaid', options, 0).load();
    }

    onClickToggleAdminAvailability(e) {
      if (this.parentAdminUpdateInProgress) {
        return;
      }

      const status = $(e.target).data('value');
      this.parentAdminUpdateInProgress = true;
      this.parentAdminAvailabilityStatus = status;
      if (typeof this.render === 'function') {
        this.render();
      }

      return updateAvailabilityStatus(status)
      .then(response => {
        this.parentAdminUpdateInProgress = false;
        this.parentAdminAvailabilityStatus = response.status;
        return noty({ text: `Status successfully updated to \"${response.status}\"`, layout: 'topCenter', type: 'success', timeout: 3000 });
    }).catch(e => {
        noty({ text: 'Status save failure: ' + e, layout: 'topCenter', type: 'error', timeout: 3000 });
        return this.parentAdminUpdateInProgress = false;
      }).finally(() => {
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
    }

    onClickTerminalSubLink(e) {
      this.freeSubLink = '';
      if (!me.isAdmin()) { return; }

      const options = {
        url: '/db/prepaid/-/create',
        method: 'POST',
        data: {
          type: 'terminal_subscription',
          maxRedeemers: parseInt($("#users").val()),
          months: parseInt($("#months").val())
        }
      };

      options.success = (model, response, options) => {
        // TODO: Don't hardcode domain.
        if (application.isProduction()) {
          this.freeSubLink = `https://codecombat.com/account/prepaid?_ppc=${model.code}`;
        } else {
          this.freeSubLink = `http://localhost:3000/account/prepaid?_ppc=${model.code}`;
        }
        return (typeof this.render === 'function' ? this.render() : undefined);
      };
      options.error = (model, response, options) => {
        return console.error('Failed to create prepaid', response);
      };
      return this.supermodel.addRequestResource('create_prepaid', options, 0).load();
    }

    onClickTerminalActivationLink(e) {
      if (!me.isAdmin()) { return; }
      const attrs = {
        type: 'terminal_subscription',
        creator: me.id,
        maxRedeemers: parseInt($("#users").val()),
        generateActivationCodes: true,
        endDate: $("#endDate").val() + ' ' + "23:59",
        properties: {
          months: parseInt($("#months").val())
        }
      };
      const prepaid = new Prepaid(attrs);
      prepaid.save(0);
      return this.listenTo(prepaid, 'sync', function() {
        let csvContent = 'Code,Months,Expires\n';
        const ocode = prepaid.get('code').toUpperCase();
        const {
          months
        } = prepaid.get('properties');
        for (var code of Array.from(prepaid.get('redeemers'))) {
          csvContent += `${ocode.slice(0, 4)}-${code.code.toUpperCase()}-${ocode.slice(4)},${months},${code.date}\n`;
        }
        const file = new Blob([csvContent], {type: 'text/csv;charset=utf-8'});
        return window.saveAs(file, 'ActivationCodes.csv');
      });
    }

    afterRender() {
      super.afterRender();
      return this.$el.find('.search-help-toggle').click(() => {
        return this.$el.find('.search-help').toggle();
      });
    }

    onClickExportProgress() {
      $('.classroom-progress-csv').prop('disabled', true);
      const classCode = $('.classroom-progress-class-code').val();
      let classroom = null;
      let courses = null;
      const courseLevels = [];
      const courseInteractives = [];
      let sessions = null;
      let interactiveSessions = null;
      let users = null;
      const userMap = {};
      const userLevelPlaytimeMap = {};
      return Promise.resolve(new Classroom().fetchByCode(classCode))
      .then(model => {
        classroom = new Classroom({ _id: model.data._id });
        return Promise.resolve(classroom.fetch());
    }).then(model => {
        courses = new Courses();
        return Promise.resolve(courses.fetch());
      }).then(models => {
        const iterable = classroom.get('courses');
        for (let index = 0; index < iterable.length; index++) {
          var course = iterable[index];
          for (var level of Array.from(course.levels)) {
            courseLevels.push({
              courseIndex: index + 1,
              levelID: level.original,
              slug: level.slug,
              courseSlug: courses.get(course._id).get('slug')
            });
            for (var intro of Array.from(level.introContent != null ? level.introContent : [])) {
              // TODO: this only works for Python presently
              if (intro.type === 'interactive') {
                courseInteractives.push({
                  courseIndex: index + 1,
                  interactiveID: intro.contentId.python != null ? intro.contentId.python : intro.contentId,
                  courseSlug: courses.get(course._id).get('slug')
                });
              }
            }
          }
        }
        users = new Users();
        return Promise.resolve($.when(...Array.from(users.fetchForClassroom(classroom) || [])));
      }).then(models => {
        for (var user of Array.from(users.models)) { userMap[user.id] = user; }
        sessions = new LevelSessions();
        return Promise.resolve($.when(...Array.from(sessions.fetchForAllClassroomMembers(classroom) || [])));
      }).then(models => {
        for (var session of Array.from(sessions.models)) {
          var playtime;
          if (!__guard__(session.get('state'), x => x.complete)) { continue; }
          var levelID = session.get('level').original;
          var userID = session.get('creator');
          if (userLevelPlaytimeMap[userID] == null) { userLevelPlaytimeMap[userID] = {}; }
          if (userLevelPlaytimeMap[userID][levelID] == null) { userLevelPlaytimeMap[userID][levelID] = {}; }
          if (session.get('contentPlaytimes')) {
            playtime = 0;
            for (var content of Array.from(session.get('contentPlaytimes'))) { playtime += content.playtime != null ? content.playtime : 0; }
          } else {
            playtime = session.get('playtime');
          }
          userLevelPlaytimeMap[userID][levelID] = playtime;
        }
        interactiveSessions = new InteractiveSessions();
        if (utils.isOzaria) {
          return Promise.resolve($.when(...Array.from(interactiveSessions.fetchForAllClassroomMembers(classroom) || [])));
        } else {
          return Promise.resolve([]);
        }
      }).then(models => {
        let acronym, interactive, interactiveID, level, userID;
        const userInteractiveAttemptMap = {};
        for (var session of Array.from(interactiveSessions.models)) {
          if (!session.get('complete')) { continue; }
          interactiveID = session.get('interactiveId');
          userID = session.get('userId');
          if (userInteractiveAttemptMap[userID] == null) { userInteractiveAttemptMap[userID] = {}; }
          if (userInteractiveAttemptMap[userID][interactiveID] == null) { userInteractiveAttemptMap[userID][interactiveID] = {}; }
          userInteractiveAttemptMap[userID][interactiveID] = session.get('submissionCount');
        }

        const userRows = [];
        for (userID in userMap) {
          var left;
          var user = userMap[userID];
          var row = [(left = user.get('name')) != null ? left : 'Anonymous'];
          for (level of Array.from(courseLevels)) {
            if ((userLevelPlaytimeMap[userID] != null ? userLevelPlaytimeMap[userID][level.levelID] : undefined) != null) {
              var rawSeconds = parseInt(userLevelPlaytimeMap[userID][level.levelID]);
              if (false) {
                // Old way, with human-readable times
                var hours = Math.floor(rawSeconds / 60 / 60);
                var minutes = Math.floor((rawSeconds / 60) - (hours * 60));
                var seconds = Math.round(rawSeconds - (hours * 60) - (minutes * 60));
                if (hours < 10) { hours = `0${hours}`; }
                if (minutes < 10) { minutes = `0${minutes}`; }
                if (seconds < 10) { seconds = `0${seconds}`; }
                row.push(`${hours}:${minutes}:${seconds}`);
              } else {
                // New way, with machine-analyzable times (seconds)
                row.push(Math.round(rawSeconds));
              }
            } else {
              row.push('Incomplete');
            }
          }

          for (interactive of Array.from(courseInteractives)) {
            var attempts = userInteractiveAttemptMap[userID] != null ? userInteractiveAttemptMap[userID][interactive.interactiveID] : undefined;
            if (attempts) {
              row.push(attempts);
            } else {
              row.push('Incomplete');
            }
          }

          userRows.push(row);
        }

        let columnLabels = "Username";
        let currentLevel = 1;
        const courseLabelIndexes = {CS: 1, GD: 0, WD: 0, CH: 1};
        let lastCourseIndex = 1;
        let lastCourseLabel = utils.isOzaria ? 'CH1' : 'CS1';
        for (level of Array.from(courseLevels)) {
          if (level.courseIndex !== lastCourseIndex) {
            currentLevel = 1;
            lastCourseIndex = level.courseIndex;
            acronym = (() => { switch (false) {
              case !/game-dev/.test(level.courseSlug): return 'GD';
              case !/web-dev/.test(level.courseSlug): return 'WD';
              case !/chapter/.test(level.courseSlug): return 'CH';
              default: return 'CS';
            } })();
            lastCourseLabel = acronym + ++courseLabelIndexes[acronym];
          }
          columnLabels += `,${lastCourseLabel}.${currentLevel++} ${level.slug}`;
        }
        let currentInteractive = 1;
        courseLabelIndexes.CH = 1;
        lastCourseIndex = 1;
        lastCourseLabel = 'CH1';
        for (interactive of Array.from(courseInteractives)) {
          if (interactive.courseIndex !== lastCourseIndex) {
            currentInteractive = 1;
            lastCourseIndex = interactive.courseIndex;
            acronym = 'CH';
            lastCourseLabel = acronym + ++courseLabelIndexes[acronym];
          }
          columnLabels += `,${lastCourseLabel}.${currentInteractive++} ${interactive.interactiveID}`;
        }
        let csvContent = `data:text/csv;charset=utf-8,${columnLabels}\n`;
        for (var studentRow of Array.from(userRows)) {
          csvContent += studentRow.join(',') + "\n";
        }
        csvContent = csvContent.substring(0, csvContent.length - 1);
        const encodedUri = encodeURI(csvContent);
        window.open(encodedUri);
        return $('.classroom-progress-csv').prop('disabled', false);
        }).catch(function(error) {
        $('.classroom-progress-csv').prop('disabled', false);
        console.error(error);
        throw error;
      });
    }

    onClickEditMandate(e) {
      if (this.mandate == null) { this.mandate = this.supermodel.loadModel(new Mandate()).model; }
      if (this.mandate.loaded) {
        return this.editMandate(this.mandate);
      } else {
        return this.listenTo(this.mandate, 'sync', this.editMandate);
      }
    }

    onClickMaintenanceMode(e) {
      if (me.isAdmin()) { return (typeof this.openModalView === 'function' ? this.openModalView(new MaintenanceModal()) : undefined); }
    }

    onClickTeacherLicenseCode(e) {
      if (me.isAdmin()) { return (typeof this.openModalView === 'function' ? this.openModalView(new TeacherLicenseCodeModal()) : undefined); }
    }

    editMandate(mandate) {
      mandate = new Mandate({_id: mandate.get('0')._id});  // Work around weirdness in this actually being a singleton
      return (typeof this.openModalView === 'function' ? this.openModalView(new ModelModal({models: [mandate]})) : undefined);
    }
  };
  MainAdminView.initClass();
  return MainAdminView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}