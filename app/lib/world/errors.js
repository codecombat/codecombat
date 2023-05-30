// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import Vector from './vector';

export const ArgumentError = (function() {
  class ArgumentError extends Error {
    static initClass() {
      this.className = 'ArgumentError';
    }
    constructor(message, functionName, argumentName, intendedType, actualValue, numArguments, hint) {
      super(message);
      this.message = message;
      this.functionName = functionName;
      this.argumentName = argumentName;
      this.intendedType = intendedType;
      this.actualValue = actualValue;
      this.numArguments = numArguments;
      this.hint = hint;
      this.name = 'ArgumentError';
      if (Error.captureStackTrace != null) {
        Error.captureStackTrace(this, this.constructor);
      }
    }

    toString() {
      let s = `\`${this.functionName}\``;
      if (this.argumentName === 'return') {
        s += "'s return value";
      } else if (this.argumentName === '_excess') {
        s += ` takes only ${this.numArguments} argument${this.numArguments > 1 ? 's' : ''}.`;
      } else if (this.argumentName) {
        s += `'s argument \`${this.argumentName}\``;
      } else {
        s += ' takes no arguments.';
      }

      let actualType = typeof this.actualValue;
      if ((this.actualValue == null)) {
        actualType = 'null';
      } else if (_.isArray(this.actualValue)) {
        actualType = 'array';
      }
      const typeMismatch = this.intendedType && !this.intendedType.match(actualType);
      if (typeMismatch) {
        let v = '';
        if (actualType === 'string') {
          v = `\"${this.actualValue}\"`;
        } else if (actualType === 'number') {
          if (Math.round(this.actualValue) === this.actualValue) { this.actualValue; } else { this.actualValue.toFixed(2); }
        } else if (actualType === 'boolean') {
          v = `${this.actualValue}`;
        } else if ((this.actualValue != null) && this.actualValue.id && this.actualValue.trackedPropertiesKeys) {
          // (Don't import Thang, but determine whether it is Thang.)
          v = this.actualValue.toString();
        } else if (this.actualValue instanceof Vector) {
          v = this.actualValue.toString();
        }
        var showValue = showValue || this.actualValue instanceof Vector;
        s += ` should have type \`${this.intendedType}\`, but got \`${actualType}\`${v ? `: \`${v}\`` : ''}.`;
      } else if (this.argumentName && (this.argumentName !== '_excess')) {
        s += ' has a problem.';
      }
      if (this.message) { s += '\n' + this.message; }
      return s;
    }
  };
  ArgumentError.initClass();
  return ArgumentError;
})();
