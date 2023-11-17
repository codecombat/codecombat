/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const HeroSelectModal = require('views/courses/HeroSelectModal');
const factories = require('test/app/factories');
const api = require('core/api');

describe('HeroSelectModal', function() {

  let modal = null;
  const coursesView = null;
  let user = null;

  const hero1 = factories.makeThangType({ original: "hero1original", _id: "hero1id", heroClass: "Warrior", name: "Hero 1" });
  const hero2 = factories.makeThangType({ original: "hero2original", _id: "hero2id", heroClass: "Warrior", name: "Hero 2" });
  const heroesResponse = JSON.stringify([hero1, hero2]);

  beforeEach(function(done) {
    window.me = (user = factories.makeUser({ heroConfig: { thangType: hero1.get('original') } }));
    const heroesPromise = Promise.resolve([hero1.attributes, hero2.attributes]);
    spyOn(api.thangTypes, 'getHeroes').and.returnValue(heroesPromise);
    modal = new HeroSelectModal();
    const subview = modal.subviews.hero_select_view;
    jasmine.demoModal(modal);
    return heroesPromise.then(() => _.defer(function() {
      modal.render();
      return done();
    }));
  });

  afterEach(() => modal.stopListening());

  it('highlights the current hero', () => expect(__guard__(__guard__(modal.$(`.hero-option[data-hero-original='${hero1.get('original')}']`), x1 => x1[0]), x => x.className.split(" "))).toContain('selected'));

  it('saves when you change heroes', function(done) {
    modal.$(`.hero-option[data-hero-original='${hero2.get('original')}']`).click();
    return setTimeout(function() { // TODO Webpack: Figure out how to not need this race condition
      expect(user.fakeRequests.length).toBe(1);
      const request = user.fakeRequests[0];
      expect(request != null ? request.method : undefined).toBe("PUT");
      expect(__guard__(JSON.parse(request != null ? request.params : undefined).heroConfig, x => x.thangType)).toBe(hero2.get('original'));
      return done();
    }
    , 500);
  });

  return it('triggers its events properly', function(done) {
    spyOn(modal, 'trigger');
    modal.render();
    modal.$('.hero-option:nth-child(2)').click();
    const request = jasmine.Ajax.requests.mostRecent();
    request.respondWith({ status: 200, responseText: me.attributes });
    expect(modal.trigger).toHaveBeenCalled();
    expect(modal.trigger.calls.argsFor(0)[0]).toBe('hero-select:success');
    expect(modal.trigger).not.toHaveBeenCalledWith('hide');
    modal.$('.select-hero-btn').click();
    expect(modal.trigger).toHaveBeenCalledWith('hide');
    return done();
  });
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}