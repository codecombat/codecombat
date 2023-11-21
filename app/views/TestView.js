// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TestView;
require('app/styles/test-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/test-view');
const requireUtils = require('lib/requireUtils');
const storage = require('core/storage');
const globalVar = require('core/globalVar');
const utils = require('core/utils');
const loadAetherLanguage = require("lib/loadAetherLanguage");

require('vendor/styles/jasmine.css');
window.getJasmineRequireObj = require('exports-loader?getJasmineRequireObj!vendor/scripts/jasmine');
window.jasmineRequire = window.getJasmineRequireObj();
if (!application.karmaTest) { // Karma doesn't use these two libraries, needs them not to run
  require('imports-loader?jasmineRequire=>window.jasmineRequire!vendor/scripts/jasmine-html');
  require('imports-loader?jasmineRequire=>window.jasmineRequire!vendor/scripts/jasmine-boot');
}
require('imports-loader?getJasmineRequireObj=>window.getJasmineRequireObj!vendor/scripts/jasmine-mock-ajax');

const requireTests = require.context('test', true, /.*\.js$/)

const TEST_REQUIRE_PREFIX = './';
const TEST_URL_PREFIX = '/test/';

const customMatchers = {
  toDeepEqual(util, customEqualityTesters) {
    return {
      compare(actual, expected) {
        const pass = _.isEqual(actual, expected);
        const message = `Expected ${JSON.stringify(actual, null, '\t')} to DEEP EQUAL ${JSON.stringify(expected, null, '\t')}`;
        return { pass, message };
      }
    };
  }
};

module.exports = (TestView = (TestView = (function() {
  TestView = class TestView extends RootView {
    static initClass() {
      this.prototype.id = 'test-view';
      this.prototype.template = template;
      this.prototype.reloadOnClose = true;
      this.prototype.className = 'style-flat';

      this.prototype.events = {
        'click #show-demos-btn': 'onClickShowDemosButton',
        'click #hide-demos-btn': 'onClickHideDemosButton'
      };
    }

    // INITIALIZE

    constructor (options, subPath) {
      super(...arguments)
      if (subPath == null) { subPath = ''; }
      this.subPath = subPath;
      if (this.subPath[0] === '/') { this.subPath = this.subPath.slice(1); }
      this.demosOn = storage.load('demos-on');
      this.failureReports = [];
      this.loadedFileIDs = [];
    }

    afterInsert() {
      super.afterInsert();
      return Promise.all(
        ["python", "coffeescript", "lua"].map(
          loadAetherLanguage
        )
      ).then(() => {
        this.initSpecFiles();
        this.render();
        TestView.runTests(this.specFiles, this.demosOn, this);
        return window.runJasmine();
      });
    }

    // EVENTS

    onClickShowDemosButton() {
      storage.save('demos-on', true);
      return document.location.reload();
    }

    onClickHideDemosButton() {
      storage.remove('demos-on');
      return document.location.reload();
    }

    // RENDER DATA

    getRenderData() {
      const c = super.getRenderData(...arguments);
      c.parentFolders = requireUtils.getParentFolders(this.subPath, TEST_URL_PREFIX);
      c.children = requireUtils.parseImmediateChildren(this.specFiles, this.subPath, TEST_REQUIRE_PREFIX, TEST_URL_PREFIX);
      const parts = this.subPath.split('/');
      c.currentFolder = parts[parts.length-1] || parts[parts.length-2] || 'All';
      return c;
    }

    // RUNNING TESTS

    initSpecFiles() {
      this.specFiles = TestView.getAllSpecFiles();
      if (this.subPath) {
        const prefix = TEST_REQUIRE_PREFIX + this.subPath;
        return this.specFiles = ((() => {
          const result = [];
          for (const f of Array.from(this.specFiles)) {
            if (_.string.startsWith(f, prefix)) {
              result.push(f);
            }
          }
          return result;
        })());
      }
    }

    static runTests(specFiles, demosOn, view) {
      if (demosOn == null) { demosOn = false; }
      const VueTestUtils = require('@vue/test-utils');
      const locale = require('locale/locale');

      VueTestUtils.config.mocks["$t"] = function(text) {
        if (text.includes('.')) {
          const res = text.split(".");
          return locale.en.translation[res[0]][res[1]];
        } else {
          return locale.en.translation[text];
        }
      };

      jasmine.getEnv().addReporter({
        suiteStack: [],

        specDone(result) {
          if (result.status === 'failed') {
            const report = {
              suiteDescriptions: _.clone(this.suiteStack),
              failMessages: (Array.from(result.failedExpectations).map((fe) => fe.message)),
              testDescription: result.description
            };
            if (view != null) {
              view.failureReports.push(report);
            }
            return (view != null ? view.renderSelectors('#failure-reports') : undefined);
          }
        },

        suiteStarted(result) {
          return this.suiteStack.push(result.description);
        },

        suiteDone(result) {
          return this.suiteStack.pop();
        }

      });

      application.testing = true;
      if (specFiles == null) { specFiles = this.getAllSpecFiles(); }
      if (demosOn) {
        jasmine.demoEl = _.once($el => $('#demo-area').append($el));
        jasmine.demoModal = _.once(modal => globalVar.currentView.openModalView(modal));
      } else {
        jasmine.demoEl = _.noop;
        jasmine.demoModal = _.noop;
      }

      jasmine.Ajax.install();
      return describe('Client', function() {
        beforeEach(function() {
          me.clear();
          me.markToRevert();
          jasmine.Ajax.requests.reset();
          Backbone.Mediator.init();
          Backbone.Mediator.setValidationEnabled(false);
          spyOn(application.tracker, 'trackEvent').and.returnValue(Promise.resolve());
          spyOn(application.tracker, 'trackPageView').and.returnValue(Promise.resolve());
          spyOn(application.tracker, 'identify').and.returnValue(Promise.resolve());
          spyOn(application.tracker, 'identifyAfterNextPageLoad').and.returnValue(Promise.resolve());
          application.timeoutsToClear = [];
          jasmine.addMatchers(customMatchers);
          return this.notySpy = spyOn(window, 'noty');
        }); // mainly to hide them
          // TODO Stubbify more things
          //   * document.location
          //   * firebase
          //   * all the services that load in main.html

        afterEach(function() {
          jasmine.Ajax.stubs.reset();
          return application.timeoutsToClear != null ? application.timeoutsToClear.forEach(timeoutID => clearTimeout(timeoutID)) : undefined;
        });
          // TODO Clean up more things
          //   * Events

        return Array.from(specFiles).map((file) => requireTests(file));
      }); // This runs the spec files
    }
    static getAllSpecFiles() {
      const allTests = requireTests.keys();
      const product = utils.isOzaria ? 'ozaria' : 'codecombat';
      const productSuffix = { codecombat: 'coco', ozaria: 'ozar' }[product];
      const otherProductSuffix = { codecombat: 'ozar', ozaria: 'coco' }[product];
      const productSpecificTests = []
      for (const file of Array.from(allTests)) {
        if (!new RegExp(`\\.${otherProductSuffix}\\.js$`).test(file)) {
          productSpecificTests.push(file)
        }
      }
      return productSpecificTests
    }

    destroy() {
      // hack to get jasmine tests to properly run again on clicking links, and make sure if you
      // leave this page (say, back to the main site) that test stuff doesn't follow you.
      return document.location.reload();
    }
  };
  TestView.initClass();
  return TestView;
})()));
