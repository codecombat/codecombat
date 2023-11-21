// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ClassroomSettingsModal;
require('app/styles/courses/classroom-settings-modal.sass');
const Classroom = require('models/Classroom');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/courses/classroom-settings-modal');
const forms = require('core/forms');
const errors = require('core/errors');
const GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler');
const globalVar = require('core/globalVar');
const classroomsApi = require('core/api/classrooms');

const initializeFilePicker = function() {
  if (!globalVar.application.isIPadApp) { return require('core/services/filepicker')(); }
};

module.exports = (ClassroomSettingsModal = (function() {
  ClassroomSettingsModal = class ClassroomSettingsModal extends ModalView {
    constructor(...args) {
      super(...args);
      this.onFileChosen = this.onFileChosen.bind(this);
      this.onFileUploaded = this.onFileUploaded.bind(this);
    }

    static initClass() {
      this.prototype.id = 'classroom-settings-modal';
      this.prototype.template = template;
      this.prototype.schema = require('schemas/models/classroom.schema');

      this.prototype.events = {
        'click #save-settings-btn': 'onSubmitForm',
        'click #update-courses-btn': 'onClickUpdateCoursesButton',
        'submit form': 'onSubmitForm',
        'click #link-google-classroom-btn': 'onClickLinkGoogleClassroom',
        'click .create-manually': 'onClickCreateManually',
        'click .pick-image-button': 'onPickImage',
        'click #link-lms-classroom-btn': 'onClickLinkLMSClassroom',
        'change #classroom-items': 'onChangeClassroomItems'
      };
    }

    initialize(options) {
      let left, needle;
      if (options == null) { options = {}; }
      this.classroom = options.classroom || new Classroom();
      this.googleClassrooms = me.get('googleClassrooms') || [];
      this.lmsClassrooms = [];
      this.isGoogleClassroom = false;
      this.enableCpp = me.enableCpp();
      this.enableJava = me.enableJava();
      this.enableBlocks = me.isBetaTester() && (((needle = (left = __guard__(this.classroom.get('aceConfig'), x => x.language)) != null ? left : 'python'), ['python', 'javascript', 'lua'].includes(needle)));
      this.uploadFilePath = `db/classroom/${this.classroom.id}`;
      initializeFilePicker();
      if (this.shouldShowLMSButton()) {
        classroomsApi.getEdLinkClassrooms().then(resp => {
          this.lmsClassrooms = resp.data;
          if (this.showLMSDropDown) {
            this.render();
            return $('.class-name').hide();
          }
        });
      }
      this.showLMSDropDown = false;
    }

    afterRender() {
      super.afterRender();
      return forms.updateSelects(this.$('form'));
    }

    onChangeClassroomItems(e) {
      // Unless we manually change this, we're not saving it, so that we can easily change the schema default later
      return this.hasChangedClassroomItems = true;
    }

    onSubmitForm(e) {
      this.classroom.notyErrors = false;
      e.preventDefault();
      const form = this.$('form');
      forms.clearFormAlerts(form);
      const attrs = forms.formToObject(form, {ignoreEmptyString: false});
      if (attrs.language) {
        attrs.aceConfig = { language: attrs.language };
        delete attrs.language;
      } else {
        forms.setErrorToProperty(form, 'language', $.i18n.t('common.required_field'));
        return;
      }

      if (!attrs.type && me.isILK()) {
        forms.setErrorToProperty(form, 'type', $.i18n.t('common.required_field'));
        return;
      }

      if (attrs.classroomItems && this.hasChangedClassroomItems) {
        attrs.classroomItems = attrs.classroomItems[0] === 'on';
      } else {
        delete attrs.classroomItems;
      }

      if (attrs.liveCompletion) {
        attrs.aceConfig.liveCompletion = attrs.liveCompletion[0] === 'on';
        delete attrs.liveCompletion;
      }

      if (attrs.blocks) {
        attrs.aceConfig.blocks = attrs.blocks;
        delete attrs.blocks;
      }

      if (attrs.levelChat) {
        attrs.aceConfig.levelChat = attrs.levelChat[0] || 'none';
        delete attrs.levelChat;
      }

      if (!this.isGoogleClassroom && !this.showLMSDropDown) {
        delete attrs.googleClassroomId;
        delete attrs.lmsClassroomId;
      } else if (attrs.googleClassroomId) {
        const gClass = me.get('googleClassrooms').find(c=> c.id===attrs.googleClassroomId);
        attrs.name = gClass.name;
        delete attrs.lmsClassroomId;
      } else if (attrs.lmsClassroomId) {
        attrs.name = this.lmsClassrooms.find(c=> c.id===attrs.lmsClassroomId).name;
        delete attrs.googleClassroomId;
      } else {
        forms.setErrorToProperty(form, 'googleClassroomId', $.i18n.t('common.required_field'));
        return;
      }

      this.classroom.set(attrs);
      const schemaErrors = this.classroom.getValidationErrors();
      if (schemaErrors) {
        for (var error of Array.from(schemaErrors)) {
          if (error.schemaPath === "/properties/name/minLength") {
            error.message = 'Please enter a class name.';
          }
        }
        forms.applyErrorsToForm(form, schemaErrors);
        return;
      }

      const button = this.$('#save-settings-btn');
      this.oldButtonText = button.text();
      button.text($.i18n.t('common.saving')).attr('disabled', true);
      this.classroom.save();
      this.listenToOnce(this.classroom, 'error', function(model, jqxhr) {
        this.stopListening(this.classroom, 'sync', this.hide);
        button.text(this.oldButtonText).attr('disabled', false);
        return errors.showNotyNetworkError(jqxhr);
      });
      this.listenToOnce(this.classroom, 'sync', this.hide);
      return (window.tracker != null ? window.tracker.trackEvent("Teachers Edit Class Saved", {category: 'Teachers', classroomID: this.classroom.id}) : undefined);
    }

    onClickUpdateCoursesButton() {
      this.$('#update-courses-btn').attr('disabled', true);
      return Promise.resolve(this.classroom.updateCourses())
      .then(() => {
        this.$('#update-courses-btn').attr('disabled', false);
        return noty({ text: 'Updated', timeout: 2000 });
    })
      .catch(e => {
        console.log('e', e);
        this.$('#update-courses-btn').attr('disabled', false);
        return noty({ text: (e.responseJSON != null ? e.responseJSON.message : undefined) || e.responseText || 'Error!', type: 'error', timeout: 5000 });
    });
    }

    shouldShowGoogleClassroomButton() {
      return me.useGoogleClassroom() && this.classroom.isNew();
    }

    shouldShowLMSButton() {
      return me.isEdLinkAccount();
    }

    onClickLinkLMSClassroom() {
      this.showLMSDropDown = true;
      this.render();
      return $('.class-name').hide();
    }

    onClickLinkGoogleClassroom() {
      $('#link-google-classroom-btn').text("Linking...");
      $('#link-google-classroom-btn').attr('disabled', true);
      return application.gplusHandler.loadAPI({
        success: () => {
          return this.linkGoogleClassroom();
        }
      });
    }

    linkGoogleClassroom() {
      this.isGoogleClassroom = true;
      return GoogleClassroomHandler.importClassrooms()
      .then(() => {
        this.googleClassrooms = me.get('googleClassrooms').filter(c => !c.importedToCoco && !c.deletedFromGC);
        this.render();
        $('.google-class-name').show();
        $('.class-name').hide();
        return $('#link-google-classroom-btn').hide();
      })
      .catch(e => {
        noty({ text: e || "Error in importing classrooms", layout: 'topCenter', type: 'error', timeout: 3000 });
        return this.render();
      });
    }


    onClickCreateManually() {
      this.isGoogleClassroom = false;
      this.render();
      $('.google-class-name').hide();
      $('.class-name').show();
      return $('#link-google-classroom-btn').show();
    }

    onPickImage() {
      return filepicker.pick(this.onFileChosen);
    }

    onFileChosen(inkBlob) {
      const body = {
        url: inkBlob.url,
        filename: inkBlob.filename,
        mimetype: inkBlob.mimetype,
        path: this.uploadFilePath,
        force: true
      };

      this.uploadingPath = [this.uploadFilePath, inkBlob.filename].join('/');
      return $.ajax('/file', { type: 'POST', data: body, success: this.onFileUploaded });
    }

    onFileUploaded(e) {
      const textarea = $('textarea#classroom-announcement');
      return textarea.append(`![${e.metadata.name}](/file/${this.uploadingPath})`);
    }
  };
  ClassroomSettingsModal.initClass();
  return ClassroomSettingsModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}