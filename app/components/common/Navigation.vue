<script>
  /**
   * Unified navigation bar component between CodeCombat and Ozaria.
   */
  export default Vue.extend({
    created() {
      this.me = me
      this.document = window.document
      this.serverConfig = window.serverConfig
    },
    methods: {
      checkLocation (route) {
        return document.location.href.search(route) >= 0
      },
      forumLink () {
        let link = 'http://discourse.codecombat.com/'
        let lang = (me.get('preferredLanguage') || 'en-US').split('-')[0]
        if (lang in ['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt']) {
          link += "c/other-languages/#{lang}"
        }
        return link
      }
    }
  })
</script>

<template lang="pug">
    nav#main-nav.navbar.navbar-default.navbar-fixed-top.text-center(:class="document.location.href.search('/league') >= 0 ? 'dark-mode' : ''")
      .container-fluid
        .row
          .col-md-12
            .navbar-header
              button.navbar-toggle.collapsed(data-toggle='collapse', data-target='#navbar-collapse' aria-expanded='false')
                span.sr-only(data-i18n="nav.toggle_nav")
                span.icon-bar
                span.icon-bar
                span.icon-bar
              a.navbar-brand(v-if="me.useTarenaLogo()" href="http://kidtts.tmooc.cn/ttsPage/login.html")
                img#logo-img.powered-by(src="/images/pages/base/logo.png")
                img#tarena-logo(src="/images/pages/base/logo-tarena.png")
              a.navbar-brand(v-else-if="serverConfig.codeNinjas" href="/home")
                img#logo-img.powered-by(src="/images/pages/base/logo.png")
                img.code-ninjas-logo(src="/images/pages/base/code-ninjas-logo-right.png")
              a.navbar-brand(v-else-if="me.showChinaResourceInfo()" href="/home")
                img#logo-img(src="/images/pages/base/logo-en+cn.png")
              a.navbar-brand(v-else href="/home")
                img#logo-img(src="/images/pages/base/logo.png")

            //- if view.isOldBrowser()
            //-   .navbar-browser-recommendation.navbar-header
            //-     .nav-spacer
            //-       .navbar-nav
            //-         a.text-p(href="https://www.google.cn/intl/zh-CN/chrome/", data-i18n="nav.browser_recommendation")

            #navbar-collapse.collapse.navbar-collapse
              .nav-spacer
              ul.nav.navbar-nav(v-if="!me.hideTopRightNav()")
                template(v-if="me.showChinaResourceInfo()")
                  li
                    a.text-p(data-i18n="nav.blog", href="https://blog.koudashijie.com")
                  li
                    a.text-p(data-event-action="Header Request Quote CTA", data-i18n="new_home.request_quote", href="/contact-cn")
                li
                  a.text-p.text-teal(v-if="checkLocation('/league')" href="/league", data-i18n="nav.esports")
                  a.text-p(v-else href="/league", data-i18n="nav.esports")

                li
                  a.text-p.text-teal(v-if="checkLocation('/parents')" href="/parents", data-i18n="nav.parent")
                  a.text-p(v-else href="/parents", data-i18n="nav.parent")

                li
                  a.text-p.text-teal(v-if="checkLocation('/impact')" href="/impact", data-i18n="nav.impact")
                  a.text-p(v-else href="/impact", data-i18n="nav.impact")

                li(v-if="me.isStudent()")
                  a.text-p.text-teal(v-if="checkLocation('/students')" href="/students", data-i18n="nav.my_courses")
                  a.text-p(v-else href="/students", data-i18n="nav.my_courses")

                li(v-if="me.isSchoolAdmin()")
                  a.text-p(href="/school-administrator", data-i18n="nav.my_teachers")

                li(v-if="!me.isAnonymous() && me.isTeacher()")
                  a.text-p.text-teal(v-if="checkLocation('/teachers/classes')" href="/teachers/classes", data-i18n="nav.my_classrooms")
                  a.text-p(v-else href="/teachers/classes", data-i18n="nav.my_classrooms")
                li(v-if="!me.isAnonymous() && !me.isStudent() && !me.isTeacher()")
                  a.text-p(href="/play", data-i18n="common.play")

                li(v-if="me.showForumLink()")
                  a.text-p(:href="forumLink()", data-i18n="nav.forum")

              ul.nav.navbar-nav(v-if="!me.isAnonymous()")
                li(v-if="me.isTarena()")
                  a.text-p#logout-button(data-i18n="login.log_out")
                li.dropdown(v-else)
                  a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                    img.img-circle.img-circle-small.m-r-1(:src="me.getPhotoURL()" :class="me.isTeacher() ? 'border-navy' : ''")
                    span(data-i18n="nav.my_account")
                    span.caret
                  ul.dropdown-menu
                    li.user-dropdown-header.text-center.hidden-xs.hidden-sm
                      a(:href="`/user/${me.getSlugOrID()}`")
                        img.img-circle(:src="me.getPhotoURL()" :class="me.isTeacher() ? 'border-navy' : ''")
                        h5 {{me.broadName()}}
                    //- Account links
                    li
                      a.account-dropdown-item(:href="`/user/${me.getSlugOrID()}`", data-i18n="nav.profile")
                    li
                      a.account-dropdown-item(href="/account/settings", data-i18n="play.settings")
                    li(v-if="me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly())")
                      a.account-dropdown-item(href="/account/payments", data-i18n="account.payments")
                    li(v-if="me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly()) || me.hasSubscription()")
                      a.account-dropdown-item(href="/account/subscription", data-i18n="account.subscription")
                    li(v-if="me.isAdmin()")
                      a.account-dropdown-item(href="/admin", data-i18n="account_settings.admin")
                    li(v-if="serverSession && serverSession.amActually")
                      a.account-dropdown-item#nav-stop-spying-button Stop Spying
                    li
                      a.account-dropdown-item#logout-button(data-i18n="login.log_out")

              ul.nav.navbar-nav
                li.dropdown
                  a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                    //- string replaced in RootView
                    span.language-dropdown-current Language
                    span.caret
                  ul(class="dropdown-menu language-dropdown" :class="!me.isAnonymous() ? 'pull-right' : ''")

              ul.nav.navbar-nav.text-p.login-buttons(v-if="me.isAnonymous()")
                li
                  a#create-account-link.signup-button(data-event-action="Header Sign Up CTA", data-i18n="signup.sign_up")
                li
                  a#login-link.login-button(data-event-action="Header Login CTA", data-i18n="signup.login")
</template>