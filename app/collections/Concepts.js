/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConceptCollection;
const CocoCollection = require('collections/CocoCollection');
const Concept = require('models/Concept');

module.exports = (ConceptCollection = (function() {
  ConceptCollection = class ConceptCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/concept';
      this.prototype.model = Concept;
    }
  };
  ConceptCollection.initClass();
  return ConceptCollection;
})());