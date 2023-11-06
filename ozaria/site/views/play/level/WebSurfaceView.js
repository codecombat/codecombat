/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let WebSurfaceView;
require('app/styles/play/level/web-surface-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('templates/play/level/web-surface-view');
const HtmlExtractor = require('lib/HtmlExtractor');

module.exports = (WebSurfaceView = (function() {
  WebSurfaceView = class WebSurfaceView extends CocoView {
    constructor(...args) {
      super(...args);
      this.onIframeMessage = this.onIframeMessage.bind(this);
    }

    static initClass() {
      this.prototype.id = 'web-surface-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'tome:html-updated': 'onHTMLUpdated',
        'web-dev:hover-line': 'onHoverLine',
        'web-dev:stop-hovering-line': 'onStopHoveringLine'
      };
    }

    initialize(options) {
      this.goals = (Array.from((options.goalManager != null ? options.goalManager.goals : undefined) != null ? (options.goalManager != null ? options.goalManager.goals : undefined) : []).filter((goal) => goal.html));
      // Consider https://www.npmjs.com/package/css-select to do this on virtualDom instead of in iframe on concreteDOM
      return super.initialize(options);
    }

    getRenderData() {
      return _.merge(super.getRenderData(), { fullUnsafeContentHostname: serverConfig.fullUnsafeContentHostname });
    }

    afterRender() {
      super.afterRender();
      this.iframe = this.$('iframe')[0];
      return $(this.iframe).on('load', e => {
        window.addEventListener('message', this.onIframeMessage);
        this.iframeLoaded = true;
        if (typeof this.onIframeLoaded === 'function') {
          this.onIframeLoaded();
        }
        return this.onIframeLoaded = null;
      });
    }

    // TODO: make clicking Run actually trigger a 'create' update here (for resetting scripts)

    onHTMLUpdated(e) {
      let scripts, styles;
      if (!this.iframeLoaded) {
        return this.onIframeLoaded = () => { if (!this.destroyed) { return this.onHTMLUpdated(e); } };
      }

      // TODO: pull out the actual scripts, styles, and body/elements they are doing so we can merge them with our initial structure on the other side
      ({ virtualDom: this.virtualDom, styles, scripts } = HtmlExtractor.extractStylesAndScripts(e.html));
      this.cssSelectors = HtmlExtractor.extractCssSelectors(styles, scripts);
      // TODO: Do something better than this hack for detecting which lines are CSS, which are HTML
      this.rawCssLines = HtmlExtractor.extractCssLines(styles);
      this.rawJQueryLines = HtmlExtractor.extractJQueryLines(scripts);

      const messageType = e.create || !this.virtualDom ? 'create' : 'update';
      return this.iframe.contentWindow.postMessage({type: messageType, dom: this.virtualDom, styles, scripts, goals: this.goals}, '*');
    }

    combineNodes(type, nodes) {
      if (_.any(nodes, node => node.type !== type)) {
        throw new Error(`Can't combine nodes of different types. (Got ${nodes.map(n => n.type)})`);
      }
      const children = nodes.map(n => n.children).reduce(((a, b) => a.concat(b)), []);
      if (_.isEmpty(children)) {
        return deku.element(type, {});
      } else {
        return deku.element(type, {}, children);
      }
    }

    onStopHoveringLine() {
      return this.iframe.contentWindow.postMessage({ type: 'highlight-css-selector', selector: '' }, '*');
    }

    onHoverLine({ row, line }) {
      let hoveredCssSelector, trimLine;
      if (_.contains(this.rawCssLines, line)) {
        // They're hovering over lines of CSS, not HTML
        trimLine = (__guard__(line.match(/\s(.*)\s*{/), x => x[1]) || line).trim().split(/ +/).join(' ');
        hoveredCssSelector = _.find(this.cssSelectors, selector => trimLine === selector);
      } else if (_.contains(this.rawJQueryLines, line)) {
        // It's a jQuery call
        trimLine = (__guard__(line.match(/\$\(\s*['"](.*)['"]\s*\)/), x1 => x1[1]) || '').trim();
        hoveredCssSelector = _.find(this.cssSelectors, selector => trimLine === selector);
      } else {
        // They're not hovering over a line with a selector, so don't highlight anything
        hoveredCssSelector = '';
      }
      this.iframe.contentWindow.postMessage({ type: 'highlight-css-selector', selector: hoveredCssSelector }, '*');
      return null;
    }

    onIframeMessage(event) {
      const origin = event.origin || event.originalEvent.origin;
      if (!new RegExp(`^https?:\/\/${serverConfig.fullUnsafeContentHostname}$`).test(origin)) {
        return console.log('Ignoring message from bad origin:', origin);
      }
      if (event.source !== this.iframe.contentWindow) {
        return console.log('Ignoring message from somewhere other than our iframe:', event.source);
      }
      switch (event.data.type) {
        case 'goals-updated':
          return Backbone.Mediator.publish('god:new-html-goal-states', {goalStates: event.data.goalStates, overallStatus: event.data.overallStatus});
        case 'error':
          // NOTE: The line number in this is relative to the script tag, not the user code. The offset is added in SpellView.
          return Backbone.Mediator.publish('web-dev:error', _.pick(event.data, ['message', 'line', 'column', 'url']));
        default:
          return console.warn('Unknown message type', event.data.type, 'for message', event, 'from origin', origin);
      }
    }

    destroy() {
      window.removeEventListener('message', this.onIframeMessage);
      return super.destroy();
    }
  };
  WebSurfaceView.initClass();
  return WebSurfaceView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}