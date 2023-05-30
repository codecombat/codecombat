// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PerfTester;
class Agent {
  constructor() {
    this.findAndWait = this.findAndWait.bind(this);
    this.clickAndWaitForRoute = this.clickAndWaitForRoute.bind(this);
    this.click = this.click.bind(this);
    this.ensureComplete = this.ensureComplete.bind(this);
    this.$iframe = $('<iframe id="frame" src="/nothing.html"></iframe>');
    this.iframe = this.$iframe[0];
  }

  clear() {
    return this.navigate('/nothing.html').then(() => {
      this.iframe.contentWindow.performance.clearResourceTimings();
      return this.iframe.contentWindow.performance.clearMeasures();
    });
  }

  navigate(url) {
    return new Promise((res, rej) => {
      this.$iframe.one('load', e => {
        this.iframe.contentWindow.performance.setResourceTimingBufferSize(1000);
        delete window.bored;
        return res();
      });
      return this.iframe.contentWindow.location.href = url;
    });
  }
  waitForCodeCombatLoaded() {
    return new Promise((res, rej) => {
      console.log("Hooking Router");
      // @iframe.contentWindow.globalVar.application.router.once 'did-load-route', () ->
      return this.globalVar.application.router.once('did-load-route', () => //TODO: Wait for supermodel to be loaded.
      res());
    });
  }

  wait(time) {
    return new Promise((res, rej) => setTimeout(res, time));
  }

  waitForAllImagesToBeLoaded() {
    const $jq = this.iframe.contentWindow.$;
    const imagePromises = [];
    for (var img of Array.from($jq('img:visible'))) {
      if (!img.complete) {
        var promise = new Promise(function(resolve) {
          if (img.complete) {
            return resolve();
          } else {
            img.onload = resolve;
            return img.onerror = resolve;
          }
        });
        promise.imgSrc = img.src;
        console.log("Waiting on", img.src);
        imagePromises.push(promise);
      }
    }
    return Promise.all(imagePromises);
  }

  findAndWait(what) {
    const target = this.iframe.contentWindow.$(what);
    if (target.length < 1) {
      //console.log "Cant find #{what}, waiting..."
      return this.wait(5).then(() => this.findAndWait(what));
    } else {
      return new Promise((res, rej) => res(target));
    }
  }

  clickAndWaitForRoute(what) {
    return this.findAndWait(what).then(target => {
      return new Promise((res, rej) => {
        target.click();
        this.globalVar.application.router.once('did-load-route', () => //TODO: Wait for supermodel to be loaded.
        res());
        return target.click();
      });
    });
  }

  click(what) {
    return this.findAndWait(what).then(target => {
      return target.click();
    });
  }

  ensureComplete() {
    const state = this.iframe.contentDocument.readyState;
    if (state !== 'complete') {
      console.log("Incomplete, waiting...");
      return this.wait(5).then(() => this.ensureComplete());
    } else {
      console.log("Document state is complete");
      return new Promise((res, rej) => res());
    }
  }

  retreiveTimings() {
    if (!this.iframe.contentWindow.bored) {
      return this.wait(1).then(() => this.retreiveTimings());
    }
    return new Promise((res, rej) => {
      return res({
        timing: this.iframe.contentWindow.performance.timing.toJSON(),
        resources: this.iframe.contentWindow.performance.getEntriesByType("resource").map(x => x.toJSON()),
        now: this.iframe.contentWindow.performance.now(),
        reportedByOurTracking: this.iframe.contentWindow.timeSpendWaiting
      });
    });
  }
}

module.exports = (PerfTester = (function() {
  PerfTester = class PerfTester extends Backbone.View {
    static initClass() {
      this.prototype.events =
        {'click .go': 'go'};
  
  
  
      this.prototype.tests = {
        homepageLoad: (agent, log) => {
          return agent.navigate('/')
          .then(() => agent.findAndWait('#classroom-in-box-container'))
          .then(() => agent.waitForAllImagesToBeLoaded())
          .then(() => agent.retreiveTimings()).then(data => {
            const time = data.timing.loadEventEnd - data.timing.navigationStart;
            const ttfb = data.timing.responseStart - data.timing.navigationStart;
            console.log(ttfb);
            log(`Loaded first page in ${time}ms`);
            log(`Time to first byte was ${ttfb}ms`);
            return (() => {
              const result = [];
              for (var k in data.timing) {
                var delta = data.timing[k] - data.timing.navigationStart;
                if (delta > 0) { result.push(log(`    ${k}: ${delta}`)); } else {
                  result.push(undefined);
                }
              }
              return result;
            })();
          });
        },
  
  
        homepageToPlaying: (agent, log) => {
          return agent.navigate('/')
          .then(() => {
            return agent.clickAndWaitForRoute('a[href="/play"]');
        }).then(() => agent.click('div.dungeon btn'))
          .then(() => log("Got to overworld"))
          .then(() => agent.ensureComplete())
          .then(() => agent.click('a[data-level-slug="dungeons-of-kithgard"]:visible')) 
          .then(() => agent.click('button.start-level:visible'))
          .then(() => log("Got to dungeon"))
          .then(() => agent.ensureComplete())
          .then(() => agent.click('div.available > button'))
          .then(() => log("Gear loaded"))
          .then(() => agent.click('#play-level-button:visible'))
          .then(() => agent.click('button.start-level-button:visible'))
          .then(() => {
            return agent.retreiveTimings();
        }).then(data => log("playing game"));
        },
  
        directToLibraryTact: (agent, log) => {
          return agent.navigate('play/level/library-tactician')
          .then(() => agent.click('#close-modal:visible')) 
          .then(() => agent.click('button.start-level-button:visible'));
        }, 
  
        privacyLoad: (agent, log) => {
          return agent.navigate('/privacy');
        }
      };
    }

    constructor() {
      this.log = this.log.bind(this);
      this.go = this.go.bind(this);
      super(...arguments);
    }

    log(what) {
       console.log(what);
       let ts = String(Math.floor(performance.now() - this.base));
       if (ts.length < 6) { ts = new Array(7 - ts.length).join(' ') + ts; }
       return this.$logout.prepend('<div>[<span style="color: cyan">' + ts + '</span> ms] '  + what + '</div>');
     }

    initialize() {
      window.currentView = this;
      this.agent = new Agent;
      this.$iframe = this.agent.$iframe;
      this.iframe = this.agent.iframe;
      this.$holder = $('<div id="holder"></div>');
      this.$holder.append(this.$iframe);
      this.$logout = $('<div id="logout"></div>');
      return this.render();
    }

    render() {
      this.$el.empty();
    
      this.$el.append(this.$logout);
      this.$el.append(this.$holder);
      return this.$el.append($('<button class="go btn btn-primary">Go</button>'));
    }
      //setTimeout @go, 1000
  
    go() {
      const n = 1;
      const tests = Object.keys(this.tests).slice(n, n+1);
      const results = {};
      //tests = ['directToLibraryTact']
      var next = () => {
        if (tests.length < 1) { return; } 
        const test = tests.shift();
        this.base = performance.now();
        this.log(`<b>--> Executing test ${test}</b>`);
        let ts = 0;
        return this.agent.clear().then(() => {
          return this.tests[test](this.agent, this.log).then(() => {
            ts = String(Math.ceil(performance.now() - this.base));
            return this.agent.retreiveTimings();
        }).then(timings => {
            const bw = timings.resources.map(x => x.transferSize).reduceRight((a, b) => b + a)/1024/1024;
            const weight = timings.resources.map(x => x.decodedBodySize).reduceRight((a, b) => b + a)/1024/1024;
            results[test] = {time: ts, bw, weight};
            this.log(`<b>--> Finished test ${test} in ${ts}ms, bandwidth ${bw.toFixed(2)}mb, page weight ${weight.toFixed(2)}mb</b>`);
            this.log(`x Tracked Time Waiting: ${timings.reportedByOurTracking} ms?`);
            return console.log(timings);
          }).then(next);
        });
      };
      

      this.$logout.empty();
      return next().then(() => {
        //@agent.clear()
        this.base = performance.now();
        this.log("All Tests Done!");
        console.log(results);
        return (() => {
          const result = [];
          for (var k in results) {
            var v = results[k];
            result.push(this.log(`  ${k} => ${v.time}ms | T: ${v.bw} | W: ${v.weight}`));
          }
          return result;
        })();
      });
    }
  };
  PerfTester.initClass();
  return PerfTester;
})());

