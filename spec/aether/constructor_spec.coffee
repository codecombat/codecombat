Aether = require '../aether'

describe "Constructor Test Suite", ->
  describe "Default values", ->
    aether = new Aether()
    it "should initialize functionName as null", ->
      expect(aether.options.functionName).toBeNull()
    it "should have javascript as the default language", ->
      expect(aether.options.language).toEqual "javascript"
    xit "should be using ECMAScript 5", ->
      expect(aether.options.languageVersion).toBe "ES5"
    it "should have no functionParameters", ->
      expect(aether.options.functionParameters).toEqual []
    it "should not yield automatically by default", ->
      expect(aether.options.yieldAutomatically).toBe false
    it "should not yield conditionally", ->
      expect(aether.options.yieldConditionally).toBe false
    it "should have defined execution costs", ->
      expect(aether.options.executionCosts).toBeDefined()
    it "should have defined globals", ->
      expect(aether.options.globals).toBeDefined()
  describe "Custom option values", ->
    constructAther = (options) ->
      aether = new Aether(options)
    beforeEach ->
      aether = null
    it "should not allow non-supported languages", ->
      options = language: "Brainfuck"
      expect(-> constructAther(options)).toThrow()
    xit "should not allow non-supported language versions", ->
      options = languageVersion: "ES7"
      expect(-> constructAther(options)).toThrow()
    it "should not allow options that do not exist", ->
      options = blah: "blah"
      expect(-> constructAther(options)).toThrow()
