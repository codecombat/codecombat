/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Problem = require('views/play/level/tome/Problem');
const locale = require('locale/locale');
locale.storeLoadedLanguage('rot13', require('locale/rot13')); // Normally locale.load does this for us

describe('Problem', function() {
  // boilerplate problem params
  const ace = {
    getSession() { return {
      getDocument() { return {
        createAnchor() {}
      }; },
      addMarker() {}
    }; }
  };
  const aether = {
    raw: "this.say('hi');\nthis.sad('bye');",
    language: { id: 'javascript' }
  };
  const aetherProblem = {
    hint: 'did you mean say instead of sad?',
    id: 'unknown_ReferenceError',
    level: 'error',
    message: 'Line 1: tmp2[tmp3] is not a function',
    range: [
      { row: 1 },
      { row: 1 }
    ],
    type: 'runtime'
  };
  const levelID = 'awesome';

  describe('.translate()', () => it('translates messages with line numbers, error types, and placeholders', function() {
    const oldLang = $.i18n.language;
    return $.i18n.changeLanguage('rot13', function() {
      let english = 'Line 12: ReferenceError: `somethin` is not defined';
      let rot13 = 'Yvar 12: ErsreraprReebe: `somethin` vf abg qrsvarq';
      expect(Problem.prototype.translate(english)).toEqual(rot13);
      english = "`foo`'s argument `bar` has a problem. Is there an enemy within your line-of-sight yet?";
      rot13 = "`foo`'f nethzrag `bar` unf n ceboyrz. Vf gurer na rarzl jvguva lbhe yvar-bs-fvtug lrg?";
      expect(Problem.prototype.translate(english)).toEqual(rot13);
      english=`\
\`attack\`'s argument \`target\` should have type \`unit\`, but got \`function\`.
Target a unit.\
`;
      rot13=`\
\`attack\`'f nethzrag \`target\` fubhyq unir glcr \`unit\`, ohg tbg \`function\`.
Gnetrg n havg.\
`;
      expect(Problem.prototype.translate(english)).toEqual(rot13);
      return $.i18n.changeLanguage(oldLang);
    });
  }));

  // TODO: Problems are no longer saved when creating Problems; instead it's in SpellView. Update tests?
  xit('save user code problem', function() {
    new Problem({aether, aetherProblem, ace, isCast: false, levelID});
    expect(jasmine.Ajax.requests.count()).toBe(1);

    const request = jasmine.Ajax.requests.mostRecent();
    expect(request.url).toEqual("/db/user.code.problem");

    const params = JSON.parse(request.params);
    expect(params.code).toEqual(aether.raw);
    expect(params.codeSnippet).toEqual("this.sad('bye');");
    expect(params.errHint).toEqual(aetherProblem.hint);
    expect(params.errId).toEqual(aetherProblem.id);
    expect(params.errLevel).toEqual(aetherProblem.level);
    expect(params.errMessage).toEqual(aetherProblem.message);
    expect(params.errRange).toEqual(aetherProblem.range);
    expect(params.errType).toEqual(aetherProblem.type);
    expect(params.language).toEqual(aether.language.id);
    return expect(params.levelID).toEqual(levelID);
  });

  xit('save user code problem no range', function() {
    aetherProblem.range = null;
    new Problem({aether, aetherProblem, ace, isCast: false, levelID});
    expect(jasmine.Ajax.requests.count()).toBe(1);

    const request = jasmine.Ajax.requests.mostRecent();
    expect(request.url).toEqual("/db/user.code.problem");

    const params = JSON.parse(request.params);
    expect(params.code).toEqual(aether.raw);
    expect(params.errHint).toEqual(aetherProblem.hint);
    expect(params.errId).toEqual(aetherProblem.id);
    expect(params.errLevel).toEqual(aetherProblem.level);
    expect(params.errMessage).toEqual(aetherProblem.message);
    expect(params.errType).toEqual(aetherProblem.type);
    expect(params.language).toEqual(aether.language.id);
    expect(params.levelID).toEqual(levelID);

    // Difference when no range
    expect(params.codeSnippet).toBeUndefined();
    return expect(params.errRange).toBeUndefined();
  });

  return xit('save user code problem multi-line snippet', function() {
    aether.raw = "this.say('hi');\nthis.sad\n('bye');";
    aetherProblem.range = [ { row: 1 }, { row: 2 } ];

    new Problem({aether, aetherProblem, ace, isCast: false, levelID});
    expect(jasmine.Ajax.requests.count()).toBe(1);

    const request = jasmine.Ajax.requests.mostRecent();
    expect(request.url).toEqual("/db/user.code.problem");

    const params = JSON.parse(request.params);
    expect(params.code).toEqual(aether.raw);
    expect(params.codeSnippet).toEqual("this.sad\n('bye');");
    expect(params.errHint).toEqual(aetherProblem.hint);
    expect(params.errId).toEqual(aetherProblem.id);
    expect(params.errLevel).toEqual(aetherProblem.level);
    expect(params.errMessage).toEqual(aetherProblem.message);
    expect(params.errRange).toEqual(aetherProblem.range);
    expect(params.errType).toEqual(aetherProblem.type);
    expect(params.language).toEqual(aether.language.id);
    return expect(params.levelID).toEqual(levelID);
  });
});
