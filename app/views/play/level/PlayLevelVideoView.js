/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PlayLevelVideoView;
import RootComponent from 'views/core/RootComponent';
import PlayLevelVideoComponent from './PlayLevelVideoComponent.vue';
import utils from 'core/utils';

export default PlayLevelVideoView = (function() {
  PlayLevelVideoView = class PlayLevelVideoView extends RootComponent {
    static initClass() {
      this.prototype.id = 'play-level-video-view';
      this.prototype.template = require('app/templates/base-flat');
      this.prototype.VueComponent = PlayLevelVideoComponent;
      this.prototype.skipMetaBinding = true;
    }

    initialize(options, levelID) {
      this.levelID = levelID;
      if (this.propsData == null) { this.propsData = {}; }
      this.propsData.levelSlug = this.levelID;
      this.propsData.courseID = utils.getQueryVariable('course');
      this.propsData.courseInstanceID = utils.getQueryVariable('course-instance');
      this.propsData.codeLanguage = utils.getQueryVariable('codeLanguage');
      this.propsData.levelOriginalID = utils.getQueryVariable('level');
      return super.initialize(options);
    }

    destroy() {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy();
      }
      return super.destroy();
    }
  };
  PlayLevelVideoView.initClass();
  return PlayLevelVideoView;
})();
