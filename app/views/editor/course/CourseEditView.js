// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseEditView;
require('app/styles/editor/course/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/course/edit');
const Course = require('models/Course');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

const Concepts = require('collections/Concepts');
const schemas = require('app/schemas/schemas');
const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');

module.exports = (CourseEditView = (function() {
  CourseEditView = class CourseEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-course-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options, courseID) {
      super(options);
      this.courseID = courseID;
      this.course = new Course({_id: this.courseID});
      this.course.saveBackups = true;
      this.supermodel.loadModel(this.course);
    }

    onLoaded() {
      super.onLoaded();
      this.concepts = new Concepts([]);

      this.listenTo(this.concepts, 'sync', () => {
        schemas.concept.enum = _.map(this.concepts.models, c => c.get('key'));
        return this.onConceptsLoaded();
      });

      return this.concepts.fetch({
        data: { skip: 0, limit: 1000 }});
    }

    onConceptsLoaded() {
      this.buildTreema();
      return this.listenTo(this.course, 'change', () => {
        this.course.updateI18NCoverage();
        return this.treema.set('/', this.course.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.course.loaded)) { return; }
      const data = $.extend(true, {}, this.course.attributes);
      const options = {
        data,
        filePath: `db/course/${this.course.get('_id')}`,
        schema: Course.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'concepts-list': nodes.conceptNodes(this.concepts.models).ConceptsListNode,
          'concept': nodes.conceptNodes(this.concepts.models).ConceptNode
        }
      };
      this.treema = this.$el.find('#course-treema').treema(options);
      this.treema.build();
      return (this.treema.childrenTreemas.rewards != null ? this.treema.childrenTreemas.rewards.open(3) : undefined);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.course), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    onPopulateI18N() {
      return this.course.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.course.set(key, value);
      }
      this.course.updateI18NCoverage();

      const res = this.course.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/course/${this.course.get('slug') || this.course.id}`;
        return document.location.href = url;
      });
    }
  };
  CourseEditView.initClass();
  return CourseEditView;
})());
