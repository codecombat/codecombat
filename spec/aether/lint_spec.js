/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Linting Test Suite", function() {
  describe("Default linting", function() {
    const aether = new Aether();
    return it("Should warn about missing semicolons", function() {
      const code = "var bandersnatch = 'frumious'";
      const {
        warnings
      } = aether.lint(code);
      expect(warnings.length).toEqual(1);
      return expect(warnings[0].message).toEqual('Missing semicolon.');
    });
  });

  return describe("Custom lint levels", () => it("Should allow ignoring of warnings", function() {
    const options = {problems: {jshint_W033: {level: 'ignore'}}};
    const aether = new Aether(options);
    const code = "var bandersnatch = 'frumious'";
    const {
      warnings
    } = aether.lint(code);
    return expect(warnings.length).toEqual(0);
  }));
});
