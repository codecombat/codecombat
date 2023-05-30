// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import errorModalTemplate from 'app/templates/core/error';
import { applyErrorsToForm } from 'core/forms';

export const parseServerError = function(text) {
  let error;
  try {
    error = JSON.parse(text) || {message: 'Unknown error.'};
  } catch (SyntaxError) {
    error = {message: text || 'Unknown error.'};
  }
  if (_.isArray(error)) { error = error[0]; }
  return error;
};

export const genericFailure = function(jqxhr) {
  Backbone.Mediator.publish('errors:server-error', {response: jqxhr});
  if (!jqxhr.status) { return connectionFailure(); }

  let error = parseServerError(jqxhr.responseText);
  let {
    message
  } = error;
  if (error.property) { message = error.property + ' ' + message; }
  console.warn(jqxhr.status, jqxhr.statusText, error);
  const existingForm = $('.form:visible:first');
  if (existingForm[0]) {
    const missingErrors = applyErrorsToForm(existingForm, [error]);
    return (() => {
      const result = [];
      for (error of Array.from(missingErrors)) {
        result.push(existingForm.append($('<div class="alert alert-danger"></div>').text(error.message)));
      }
      return result;
    })();
  } else {
    const res = errorModalTemplate({
      status: jqxhr.status,
      statusText: jqxhr.statusText,
      message
    });
    return showErrorModal(res);
  }
};

export const backboneFailure = (model, jqxhr, options) => genericFailure(jqxhr);

export const connectionFailure = function() {
  const html = errorModalTemplate({
    status: 0,
    statusText: 'Connection Gone',
    message: 'No response from the CoCo servers, captain.'
  });
  return showErrorModal(html);
};

export const showNotyNetworkError = function() {
  const jqxhr = _.find(arguments, 'promise'); // handles jquery or backbone network error (jqxhr is first or second parameter)
  return noty({
    text: (jqxhr.responseJSON != null ? jqxhr.responseJSON.message : undefined) || (jqxhr.responseJSON != null ? jqxhr.responseJSON.errorName : undefined) || 'Unknown error',
    layout: 'topCenter',
    type: 'error',
    timeout: 5000,
    killer: false,
    dismissQueue: true
  });
};

var showErrorModal = function(html) {
  // TODO: make a views/modal/error_modal view for this to use so the template can reuse templates/core/modal-base?
  $('#modal-wrapper').html(html);
  $('.modal:visible').modal('hide');
  return $('#modal-error').modal('show');
};

let shownWorkerError = false;

export const onWorkerError = function() {
  // TODO: Improve worker error handling in general
  // TODO: Remove this code when IE11 is deprecated OR Aether is removed.

  // Sometimes on IE11, Aether isn't loaded. Handle that error by messaging the user, reloading the page.
  // Note: Edge is also considered 'msie'.
  if ((!shownWorkerError) && $.browser.msie && ($.browser.versionNumber === 11)) {
    const text = 'Explorer failure. Reloading...';
    shownWorkerError = true;
    setTimeout((() => document.location.reload()), 5000);
    return noty({text, layout: 'topCenter', type: 'error'});
  }
};
