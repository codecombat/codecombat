<script>
  /**
   * Unified navigation bar component between CodeCombat and Ozaria.
   */
  export default Vue.extend({
    created() {
      // Bind the global values to the vue component.
      this.me = me
      this.document = window.document
      this.serverConfig = window.serverConfig
      this.serverSession = window.serverSession
    },

    computed: {
      isOldBrowser () {
        if (features.china && $.browser) {
          if (!($.browser.webkit || $.browser.mozilla || $.browser.msedge)) {
            return true 
          }
          const majorVersion = $.browser.versionNumber
          if ($.browser.mozilla && majorVersion < 25) {
            return true 
          }
          if ($.browser.chrome && majorVersion < 72) {  // forbid some chinese browser
            return true
          }
          if ($.browser.safari && majorVersion < 6) { // 6 might have problems with Aether, or maybe just old minors of 6: https://errorception.com/projects/51a79585ee207206390002a2/errors/547a202e1ead63ba4e4ac9fd
            return true
          }
        }
        return false
      }
    },

    methods: {
      checkLocation (route) {
        return document.location.href.search(route) >= 0
      },

      forumLink () {
        let link = 'http://discourse.codecombat.com/'
        let lang = (me.get('preferredLanguage') || 'en-US').split('-')[0]
        if (lang in ['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt']) {
          link += `c/other-languages/${lang}`
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
                span.sr-only {{ $t('nav.toggle_nav') }}
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

            .navbar-browser-recommendation.navbar-header(v-if="isOldBrowser")
              .nav-spacer
                .navbar-nav
                  a.text-p(href="https://www.google.cn/intl/zh-CN/chrome/") {{ $t('nav.browser_recommendation') }}

            #navbar-collapse.collapse.navbar-collapse
              .nav-spacer
              ul.nav.navbar-nav(v-if="!me.hideTopRightNav()")
                template(v-if="me.showChinaResourceInfo()")
                  li
                    a.text-p(href="https://blog.koudashijie.com") {{ $t('nav.blog') }}
                  li
                    a.text-p(data-event-action="Header Request Quote CTA", href="/contact-cn") {{ $t('new_home.request_quote') }}

                li
                  a.text-p(:class="checkLocation('/league') && 'text-teal'" href="/league") {{ $t('nav.esports') }}

                li
                  a.text-p(:class="checkLocation('/parents') && 'text-teal'" href="/parents") {{ $t('nav.parent') }}

                li
                  a.text-p(:class="checkLocation('/impact') && 'text-teal'" href="/impact") {{ $t('nav.impact') }}

                li(v-if="me.isStudent()")
                  a.text-p(:class="checkLocation('/students') && 'text-teal'" href="/students") {{ $t('nav.my_courses') }}

                li(v-if="me.isSchoolAdmin()")
                  a.text-p(href="/school-administrator") {{ $t('nav.my_teachers') }}

                li(v-if="!me.isAnonymous() && me.isTeacher()")
                  a.text-p(:class="checkLocation('/teachers/classes') && 'text-teal'" href="/teachers/classes") {{ $t('nav.my_classrooms') }}

                li(v-if="!me.isAnonymous() && !me.isStudent() && !me.isTeacher()")
                  a.text-p(href="/play") {{ $t('common.play') }}

                li(v-if="me.showForumLink()")
                  a.text-p(:href="forumLink()") {{ $t('nav.forum') }}

              ul.nav.navbar-nav(v-if="!me.isAnonymous()")
                li(v-if="me.isTarena()")
                  a.text-p#logout-button {{ $t('login.log_out') }}
                li.dropdown(v-else)
                  a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                    img.img-circle.img-circle-small.m-r-1(:src="me.getPhotoURL()" :class="me.isTeacher() ? 'border-navy' : ''")
                    span {{ $t('nav.my_account') }}
                    span.caret
                  ul.dropdown-menu
                    li.user-dropdown-header.text-center.hidden-xs.hidden-sm
                      a(:href="`/user/${me.getSlugOrID()}`")
                        img.img-circle(:src="me.getPhotoURL()" :class="me.isTeacher() ? 'border-navy' : ''")
                        h5 {{ me.broadName() }}
                    //- Account links
                    li
                      a.account-dropdown-item(:href="`/user/${me.getSlugOrID()}`") {{ $t('nav.profile') }}
                    li
                      a.account-dropdown-item(href="/account/settings") {{ $t('play.settings') }}
                    li(v-if="me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly())")
                      a.account-dropdown-item(href="/account/payments") {{ $t('account.payments') }}
                    li(v-if="me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly()) || me.hasSubscription()")
                      a.account-dropdown-item(href="/account/subscription") {{ $t('account.subscription') }}
                    li(v-if="me.isAdmin()")
                      a.account-dropdown-item(href="/admin") {{ $t('account_settings.admin') }}
                    li(v-if="serverSession && serverSession.amActually")
                      a.account-dropdown-item#nav-stop-spying-button Stop Spying
                    li
                      a.account-dropdown-item#logout-button {{ $t('login.log_out') }}

              ul.nav.navbar-nav
                li.dropdown
                  a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                    //- string replaced in RootView
                    span.language-dropdown-current Language
                    span.caret
                  ul(class="dropdown-menu language-dropdown" :class="!me.isAnonymous() ? 'pull-right' : ''")

              ul.nav.navbar-nav.text-p.login-buttons(v-if="me.isAnonymous()")
                li
                  a#create-account-link.signup-button(data-event-action="Header Sign Up CTA") {{ $t('signup.sign_up') }}
                li
                  a#login-link.login-button(data-event-action="Header Login CTA") {{ $t('signup.login') }}
</template>

<style lang="scss" scoped>
/* These styles are global. This is required so bootstrap.... :( */
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";


#main-nav.navbar {
  background: white;
  margin-bottom: 0;
  white-space: nowrap; // prevent home icon from going under brand
  box-shadow: unset;
  font-weight: 400;

  p, .text-p {
    font-family: $body-font;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0.75px;
    line-height: 26px;
  }

  #create-account-link {
    background-color: $teal;
    color: white;
    border: 1px solid $teal;
    border-radius: 4px 0 0 4px;
    width: 131px;
    &:hover {
      background-color: #2DCEC8;
      border: 1px solid #2DCEC8;
      transition: background-color .35s, border .35s;
    }
  }

  #login-link {
    width: 94px;
    border: 1px solid $teal;
    border-radius: 0 4px 4px 0;
    color: $teal;
    &:hover {
      background-color: #1FBAB4;
      color: white;
      transition: color .35s, background-color .35s;
    }
  }
  .nav-spacer{
    height: 12px;
  }

  .navbar-browser-recommendation {
    margin-left: 1em;
    padding-top: 15px;

    a {
      font-size: 16px;
      padding: 10px 15px;
      float: left;
      &:hover {
        color: $teal;
        text-decoration: none;
      }
    }
  }

  .login-buttons {
    margin: 2px 70px 0px 10px;
    @media (max-width: $screen-md-min) {
      display: inline-block;
      margin: 2px 10px 29.5px;
    }
    @media (max-width: $wider-breakpoint) {
      margin-right: 10px;
    }
    & li {
      display: inline-block;
    }
  }
  a.navbar-brand {
    padding: 14px 0 16px 70px;
    margin: 0px;
    @media (max-width: $wider-breakpoint) {
      padding-left: 10px;
    }

    #logo-img {
      height: 40px;

      &.powered-by {
        height: 30px;
        width: auto;
        margin-top: -5px;
      }
    }

    .code-ninjas-logo, #tarena-logo {
      height: 40px;
      width: auto;
      margin-right: 10px;
    }
  }

  .navbar-toggle {
    color: black;
    margin: 30px 70px 0;
    border-color: $navy;
    @media (max-width: 767px) {
      margin: 15px 10px 0;
    }

    .icon-bar {
      background-color: $navy;
    }
  }

  @media (min-width: $grid-float-breakpoint) {
    #navbar-collapse {
      float: right;
    }

    .dropdown-menu {
      max-width: 330px;
      overflow-x: auto;
    }
  }
  .language-dropdown {
    max-height: 60vh;
    overflow-y: auto;
  }

  #navbar-collapse {
    max-height: 100vh;

    .text-teal {
      color: $teal;
    }
  }

  .nav > li > a {
    // TODO: Move this to bootstrap variables for navbars

    // TODO: getting overridden by .navbar .nav > li > a for some reason
    font-family: $body-font;
    text-shadow: unset;
    padding: 10px 15px;
    @media (max-width: $wider-breakpoint) {
      padding: 10px 10px;
    }

    color: $navy;
    &:hover {
      color: $teal;
    }
  }
  // TODO: what is this for?
  .nav > li.disabled > a {
    color: black;
    &:hover {
      background: white;
      color: black;
      cursor: default;
    }
  }

  @media (max-width: $grid-float-breakpoint) {
    .nav > li > a {
      padding: 10px 20px;
      height: 45px;
    }
    .language-dropdown-item {
      color: $navy;
    }
    .account-dropdown-item {
      color: $navy;
    }
  }

  // TODO: still used?
  .img-circle {
    border: $gold 8px solid;
    width: 98px;
    height: 98px; // Includes the border
  }

  .img-circle-small {
    border: $gold 3px solid;
    width: 33px;
    height: 33px;
  }

  // For teacher avatars
  .border-burgundy {
    border-color: $navy;
  }

  .border-navy {
    border-color: $navy;
  }
}
</style>