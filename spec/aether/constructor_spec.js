/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Constructor Test Suite", function() {
  describe("Default values", function() {
    const aether = new Aether();
    it("should initialize functionName as null", () => expect(aether.options.functionName).toBeNull());
    it("should have javascript as the default language", () => expect(aether.options.language).toEqual("javascript"));
    xit("should be using ECMAScript 5", () => expect(aether.options.languageVersion).toBe("ES5"));
    it("should have no functionParameters", () => expect(aether.options.functionParameters).toEqual([]));
    it("should not yield automatically by default", () => expect(aether.options.yieldAutomatically).toBe(false));
    it("should not yield conditionally", () => expect(aether.options.yieldConditionally).toBe(false));
    it("should have defined execution costs", () => expect(aether.options.executionCosts).toBeDefined());
    return it("should have defined globals", () => expect(aether.options.globals).toBeDefined());
  });
  return describe("Custom option values", function() {
    const constructAther = function(options) {
      let aether;
      return aether = new Aether(options);
    };
    beforeEach(function() {
      let aether;
      return aether = null;
    });
    it("should not allow non-supported languages", function() {
      const options = {language: "Brainfuck"};
      return expect(() => constructAther(options)).toThrow();
    });
    xit("should not allow non-supported language versions", function() {
      const options = {languageVersion: "ES7"};
      return expect(() => constructAther(options)).toThrow();
    });
    return it("should not allow options that do not exist", function() {
      const options = {blah: "blah"};
      return expect(() => constructAther(options)).toThrow();
    });
  });
});
