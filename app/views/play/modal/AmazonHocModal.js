/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AmazonHocModal;
import 'app/styles/play/modal/amazon-hoc-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/play/modal/amazon-hoc-modal';

export default AmazonHocModal = (function() {
  AmazonHocModal = class AmazonHocModal extends ModalView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'amazon-hoc-modal';
  
      this.prototype.events = {
        'click #close-modal': 'hide',
        'mouseup #aws-educate-link': 'onClickAwsEducateLink', // mouseup detects middle click as well
        'mouseup #aws-alexa-link': 'onClickAwsAlexaLink',
        'mouseup #aws-future-eng-link': 'onClickAwsFutureEngLink'
      };
    }

    onClickAwsEducateLink() {
      return (window.tracker != null ? window.tracker.trackEvent('Click Amazon link', {label: 'aws-educate-link'}) : undefined);
    }

    onClickAwsAlexaLink() {
      return (window.tracker != null ? window.tracker.trackEvent('Click Amazon link', {label: 'aws-alexa-link'}) : undefined);
    }

    onClickAwsFutureEngLink() {
      return (window.tracker != null ? window.tracker.trackEvent('Click Amazon link', {label: 'aws-future-eng-link'}) : undefined);
    }
  };
  AmazonHocModal.initClass();
  return AmazonHocModal;
})();
