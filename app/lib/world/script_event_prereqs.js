// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import { downTheChain } from './world_utils';

export const scriptMatchesEventPrereqs = function(script, event) {
  if (!script.eventPrereqs) { return true; }
  for (var ap of Array.from(script.eventPrereqs)) {
    var v = downTheChain(event, ap.eventProps);
    if ((ap.equalTo != null) && (v !== ap.equalTo)) { return false; }
    if ((ap.notEqualTo != null) && (v === ap.notEqualTo)) { return false; }
    if ((ap.greaterThan != null) && !(v > ap.greaterThan)) { return false; }
    if ((ap.greaterThanOrEqualTo != null) && !(v >= ap.greaterThanOrEqualTo)) { return false; }
    if ((ap.lessThan != null) && !(v < ap.lessThan)) { return false; }
    if ((ap.lessThanOrEqualTo != null) && !(v <= ap.lessThanOrEqualTo)) { return false; }
    if ((ap.containingString != null) && (!v || (v.search(ap.containingString) === -1))) { return false; }
    if ((ap.notContainingString != null) && ((v != null ? v.search(ap.notContainingString) : undefined) !== -1)) { return false; }
    if ((ap.containingRegexp != null) && (!v || (v.search(new RegExp(ap.containingRegexp)) === -1))) { return false; }
    if ((ap.notContainingRegexp != null) && ((v != null ? v.search(new RegExp(ap.notContainingRegexp)) : undefined) !== -1)) { return false; }
  }

  return true;
};
