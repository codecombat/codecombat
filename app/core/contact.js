/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
module.exports = {
  sendContactMessage(contactMessageObject, modal) {
    // deprecated
    if (modal != null) {
      modal.find('.sending-indicator').show();
    }
    const jqxhr = $.post('/contact', contactMessageObject, function(response) {
      if (!modal) { return; }
      modal.find('.sending-indicator').hide();
      modal.find('#contact-message').val('Thanks!');
      return _.delay(function() {
        modal.find('#contact-message').val('');
        return modal.modal('hide');
      }
      , 1000);
    });
    jqxhr.fail(function() {
      if (!modal) { return; }
      if (jqxhr.status === 500) {
        return modal.find('.sending-indicator').text($.i18n.t('loading_error.server_error'));
      }
    });
    return jqxhr;
  },

  send(options) {
    if (options == null) { options = {}; }
    options.type = 'POST';
    options.url = '/contact';
    return $.ajax(options);
  },

  sendParentSignupInstructions(parentEmail) {
    const jqxhr = $.ajax('/contact/send-parent-signup-instructions', {
      method: 'POST',
      data: {parentEmail}
    });
    return new Promise(jqxhr.then);
  },

  sendTeacherSignupInstructions(teacherEmail, studentName) {
    const jqxhr = $.ajax('/contact/send-teacher-signup-instructions', {
      method: 'POST',
      data: {teacherEmail, studentName}
    });
    return new Promise(jqxhr.then);
  },

  sendAPCSPContactMail({email, name, role, message}) {
    const jqxhr = $.ajax('/contact/apcsp', {
      method: 'POST',
      data: {email, name, role, message}
    });
    return new Promise(jqxhr.then);
  },

  sendTeacherGameDevProjectShare({teacherEmail, sessionId, codeLanguage, levelName}) {
    const jqxhr = $.ajax('/contact/send-teacher-game-dev-project-share', {
      method: 'POST',
      data: {teacherEmail, sessionId, levelName, codeLanguage: _.string.titleize(codeLanguage).replace('script', 'Script')}
    });
    return new Promise(jqxhr.then);
  },

  sendSlackMessage(data) {
    try {
      if (data.name == null) { data.name = typeof me !== 'undefined' && me !== null ? me.broadName() : undefined; }
      if (data.email == null) { data.email = typeof me !== 'undefined' && me !== null ? me.get('email') : undefined; }
    } catch (e) {
      data.lookupError = e;
    }
    const jqxhr = $.ajax({type: 'POST', url: '/contact/slacklog', data});
    return new Promise(jqxhr.then);
  }
};
