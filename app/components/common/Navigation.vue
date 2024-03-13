<script>// eslint-disable-line vue/multi-word-component-names
import {
  cocoBaseURL,
  CODECOMBAT,
  getQueryVariable,
  isChinaOldBrowser,
  isCodeCombat,
  isOzaria,
  OZARIA,
  ozBaseURL
} from 'core/utils'
import AnnouncementModal from '../../views/announcement/announcementModal'
import AnnouncementNav from '../../views/announcement/AnnouncementNav'
import { mapActions, mapGetters } from 'vuex'
import CTAButton from '../../components/common/buttons/CTAButton'
import CaretDown from '../../components/common/elements/CaretDown'

/**
 * Unified navigation bar component between CodeCombat and Ozaria.
 */
export default Vue.extend({
  components: {
    AnnouncementModal,
    AnnouncementNav,
    'cta-button': CTAButton,
    caret: CaretDown
  },
  computed: {
    ...mapGetters('announcements', [
      'announcements',
      'unread',
      'announcementInterval',
      'announcementModalOpen',
      'announcementDisplay'
    ]),
    languageCode () {
      return me.get('preferredLanguage')
    },
    isChinaOldBrowser () {
      return isChinaOldBrowser()
    },

    isCodeCombat () {
      return isCodeCombat
    },

    isOzaria () {
      return isOzaria
    },

    cocoBaseURL () {
      return cocoBaseURL()
    },

    ozBaseURL () {
      return ozBaseURL()
    },

    hideNav () {
      return getQueryVariable('landing', false)
    },

    showHackStackLogo () {
      return window.location.pathname.startsWith('/ai')
    }
  },

  created () {
    // Bind the global values to the vue component.
    this.me = me
    this.document = window.document
    this.serverConfig = window.serverConfig
    this.serverSession = window.serverSession
    this.CODECOMBAT = CODECOMBAT
    this.OZARIA = OZARIA
  },
  mounted () {
    setTimeout(() => {
      this.checkAnnouncements('fromNav')
      if (!this.announcementInterval) { // todo: using websocket to get new announcements
        this.startInterval('fromNav')
      }
    }, 2000)
  },
  beforeUnmounted () {
    if (this.announcementInterval) { clearInterval(this.announcementInterval) }
  },
  methods: {
    ...mapActions('announcements', [
      'closeAnnouncementModal',
      'checkAnnouncements',
      'startInterval'
    ]),
    navEvent (e) {
      // Only track if user has clicked a link on the nav bar
      if (!e || !e.target || e.target.tagName !== 'A') {
        return
      }

      if (!window.tracker) {
        return
      }

      const clickedAnchorTag = e.target
      const action = `Link: ${clickedAnchorTag.getAttribute('href') || clickedAnchorTag.getAttribute('data-event-action')}`
      const properties = {
        category: 'Nav',
        // Inspired from the HomeView homePageEvent method
        user: me.get('role') || (me.isAnonymous() && 'anonymous') || 'homeuser'
      }

      window.tracker.trackEvent(action, properties)
    },

    /**
     * This is used to highlight nav routes we are currently on.
     * It can optionally also check if the user is on codecombat or ozaria.
     */
    checkLocation (route, host = undefined) {
      let hostCheck = true
      if (host === CODECOMBAT) {
        hostCheck = this.isCodeCombat
      } else if (host === OZARIA) {
        hostCheck = this.isOzaria
      }
      return hostCheck && document.location.href.search(route) >= 0
    },

    /**
     * Returns a codecombat url for a relative path.
     * If the user is already on codecombat, will return a relative URL.
     * If the user is on ozaria, will return an absolute url to codecombat.com
     *
     * Handles subdomains such as staging.ozaria.com, will return absolute path
     * to staging.codecombat.com
     *
     * The domains used in China are also handled, i.e. koudashijie
     */
    cocoPath (relativePath) {
      return `${this.cocoBaseURL}${relativePath}`
    },

    ozPath (relativePath) {
      return `${this.ozBaseURL}${relativePath}`
    },

    readAnnouncement () {
      return application.router.navigate('/announcements', { trigger: true })
    }
  }
})
</script>

<template lang="pug">
  nav#main-nav.navbar.navbar-default.navbar-fixed-top.text-center(:class="/^\\/(league|play\\/ladder)/.test(document.location.pathname) ? 'dark-mode' : ''" @click="navEvent")
    announcement-modal(v-if="announcementModalOpen" @close="closeAnnouncementModal" :announcement="announcementDisplay")
    .container
      .row
        .col-md-12.header-container
          .navbar-header
            button.navbar-toggle.collapsed(data-toggle='collapse', data-target='#navbar-collapse' aria-expanded='false')
              span.sr-only {{ $t('nav.toggle_nav') }}
              span.icon-bar
              span.icon-bar
              span.icon-bar
            a.navbar-brand(v-if="me.useTarenaLogo()" href="http://kidtts.tmooc.cn/ttsPage/login.html")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img#tarena-logo(src="/images/pages/base/logo-tarena.png" alt="Tarena logo")
            a.navbar-brand(v-else-if="serverConfig.codeNinjas" href="/home")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img.code-ninjas-logo(src="/images/pages/base/code-ninjas-logo-right.png" alt="Code Ninjas logo")
            a.navbar-brand(v-else-if="me.isTecmilenio()" href="/home")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img.tecmilenio-logo(src="/images/pages/payment/tecmilenio-logo-2.png" alt="Tecmilenio logo")
            a.navbar-brand(v-else-if="showHackStackLogo" href="/home")
              img#logo-img(src="/images/pages/base/logo+hs.png" alt="CodeCombat and HackStack logo")
            a.navbar-brand(v-else-if="me.showChinaResourceInfo()" href="/home")
              img#logo-img(src="/images/pages/base/logo-en+cn.png" alt="CodeCombat logo")
            a.navbar-brand(v-else :href="hideNav ? '#' : '/home'")
              picture
                source#logo-img(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img(src="/images/pages/base/logo.png" alt="CodeCombat logo")

          .navbar-browser-recommendation.navbar-header(v-if="isChinaOldBrowser")
            .nav-spacer
              .navbar-nav
                a.text-p(href="https://www.google.cn/intl/zh-CN/chrome/") {{ $t('nav.browser_recommendation') }}

          #navbar-collapse.collapse.navbar-collapse
            .nav-spacer
            ul.nav.navbar-nav(v-if="!me.hideTopRightNav() && !hideNav")
              li
              template(v-if="me.showChinaResourceInfo()")
                li
                  a.text-p(href="https://blog.koudashijie.com") {{ $t('nav.blog') }}

                li
                  a.text-p(data-event-action="Header Request Quote CTA", href="/contact-cn") {{ $t('new_home.request_quote') }}

              li(v-if="me.isAnonymous()")
                ul.nav.navbar-nav
                  li.dropdown.dropdown-hover
                    a.text-p(:href="isCodeCombat ? '/schools' : '/'", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false" :class="isOzaria && 'text-teal'")
                      span {{ $t('nav.educators') }}
                      caret
                    ul(class="dropdown-menu")
                      li
                        a.text-p(:href="ozPath('/')")
                          span(:class="isOzaria && !checkLocation('/professional-development') && 'text-teal'") {{ $t('nav.ozaria_classroom') }}
                      li
                        a.text-p(:href="cocoPath('/schools')" :class="checkLocation('/schools', CODECOMBAT) && 'text-teal'") {{ $t('nav.codecombat_classroom') }}
                      li
                        a.text-p(:href="ozPath('/professional-development')")
                          span(:class="checkLocation('/professional-development') && 'text-teal'") {{ $t('nav.professional_development') }}

              li(v-if="!me.isStudent() && !me.isTeacher() && (me.get('country') !== 'hong-kong') && !me.isParentHome()")
                a.text-p(:class="checkLocation('/parents') && !checkLocation('/parents/signup') && 'text-teal'" :href="cocoPath('/parents')") {{ $t('nav.parent') }}

              li(v-if="me.isParentHome()")
                a.text-p(:class="checkLocation('/parents/dashboard') && 'text-teal'" :href="me.hasNoVerifiedChild() ? cocoPath('/parents/add-another-child') : cocoPath('/parents/dashboard')") {{ $t('nav.dashboard') }}

              li
                a.text-p(:class="checkLocation('/league') && 'text-teal'" :href="cocoPath('/league')") {{ $t('nav.esports') }}

              li(v-if="me.isTeacher()")
                ul.nav.navbar-nav
                  li.dropdown.dropdown-hover
                    a.dropdown-toggle.text-p(href="/teachers/classes", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                      span {{ $t('nav.dashboard') }}
                      caret
                    ul(class="dropdown-menu")
                      li
                        a.text-p(:href="ozPath('/teachers/classes')")
                      li

                      li(v-if="me.isSchoolAdmin()")
                        a.text-p(:href="ozPath('/school-administrator')")
                          span(:class="checkLocation('/school-administrator', OZARIA) && 'text-teal'") {{ $t(`nav.ozaria_admin_dashboard`) }}
                      li(v-if="me.isSchoolAdmin()")
                        a.text-p(:class="checkLocation('/school-administrator', CODECOMBAT) && 'text-teal'" :href="cocoPath('/school-administrator')") {{ $t(`nav.codecombat_admin_dashboard`) }}

              li(v-else-if="me.isStudent()")
                ul.nav.navbar-nav
                  li.dropdown.dropdown-hover
                    a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                      span {{ $t('nav.my_courses') }}
                      caret
                    ul(class="dropdown-menu")
                      li
                        a.text-p(:href="ozPath('/students')")
                          span(:class="checkLocation('/students', OZARIA) && 'text-teal'") {{ $t('nav.ozaria_classroom') }}
                      li
                        a.text-p(:class="checkLocation('/students', CODECOMBAT) && 'text-teal'" :href="cocoPath('/students')") {{ $t('nav.codecombat_classroom') }}

              li(v-if="!me.isAnonymous() && !me.isStudent() && !me.isTeacher()")
                a.text-p(:href="cocoPath('/play')") {{ $t('common.play') }}

            ul.nav.navbar-nav(v-if="!me.isAnonymous()")
              li(v-if="me.isTarena()")
                a.text-p#logout-button {{ $t('login.log_out') }}
              li.dropdown(v-else)
                a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                  img.img-circle.img-circle-small.m-r-1(:src="me.getPhotoURL()" :class="{'border-navy': me.isTeacher()}")
                  span.unreadMessage(v-if="unread")
                  span {{ $t('nav.my_account') }}
                  caret
                ul.dropdown-menu.pull-right
                  li.user-dropdown-header.text-center.hidden-xs.hidden-sm
                    a(:href="cocoPath(`/user/${me.getSlugOrID()}`)")
                      img.img-circle(:src="me.getPhotoURL()" :class="me.isTeacher() ? 'border-navy' : ''")
                      h5 {{ me.broadName() }}
                  //- Account links
                  li(v-if="isCodeCombat")
                    a.account-dropdown-item(:href="cocoPath(`/user/${me.getSlugOrID()}`)") {{ $t('nav.profile') }}
                  li
                    a.account-dropdown-item(href="/account/settings") {{ $t('play.settings') }}
                  li(v-if="isCodeCombat && (me.isAdmin() || me.isTeacher() || me.isParentHome() || me.isRegisteredHomeUser())")
                    a.account-dropdown-item#manage-billing(href="/payments/manage-billing", target="_blank") {{ $t('account.manage_billing') }}
                  li.dropdown.dropleft.dropdown-hover(v-if="true || unread")
                    a.account-dropdown-item.dropdown-toggle(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false" @click="readAnnouncement")
                      caret(v-if="this.announcements.length")
                      span {{ $t('announcement.notifications') }}
                      span.unread(v-if="unread") {{ unread }}
                    announcement-nav.announcement-nav(v-if="this.announcements.length")
                  li(v-if="isCodeCombat && (me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly()))")
                    a.account-dropdown-item(href="/account/payments") {{ $t('account.payments') }}
                  li(v-if="isCodeCombat && (me.isAdmin() || !(me.isTeacher() || me.isStudent() || me.freeOnly()) || me.hasSubscription())")
                    a.account-dropdown-item(href="/account/subscription") {{ $t('account.subscription') }}
                  li(v-if="me.isAPIClient()")
                    a.account-dropdown-item(href="/partner-dashboard", target="_blank") {{ $t('nav.api_dashboard') }}
                  li(v-if="me.isAdmin() || me.isOnlineTeacher() || me.isParentAdmin()")
                    a.account-dropdown-item(href="/admin") {{ $t('account_settings.admin') }}
                  li(v-if="me.isAdmin() || me.isOnlineTeacher()")
                    a.account-dropdown-item(href="/event-calendar/classes") {{ $t('events.calendar') }}
                  li(v-if="serverSession && serverSession.amActually")
                    a.account-dropdown-item#nav-stop-spying-button(href="#") {{ $t('login.stop_spying') }}
                  li(v-if="me.isTeacher()")
                    a.account-dropdown-item#nav-student-mode(href="#") {{ $t('login.test_as_student') }}
                  li(v-else-if="serverSession && serverSession.switchingUserActualId && me.isTestStudent()")
                    a.account-dropdown-item#nav-stop-switching-button(href="#") {{ $t('login.stop_switching') }}
                  li
                    a.account-dropdown-item#logout-button(href="#") {{ $t('login.log_out') }}
            .right
              ul.nav.navbar-nav.text-p.login-buttons(v-if="me.isAnonymous() && !hideNav")
                li
                  cta-button#login-link.login-button(data-event-action="Header Login CTA" size="small" type="no-background") {{ $t('signup.login') }}
                li
                  cta-button#create-account-link.signup-button(data-event-action="Header Sign Up CTA" size="small") {{ $t('signup.sign_up') }}
              ul.nav.navbar-nav
                li.dropdown
                  a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                    //- string replaced in RootView
                    span.language-dropdown-current Language
                  ul(class="dropdown-menu language-dropdown")
</template>

<style lang="scss" scoped>
/* These styles are global. This is required so bootstrap.... :( */

@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "app/styles/component_variables.scss";

#main-nav.navbar {
  background: white;

  ::v-deep .emoji-flag {
    font-size: 30px
  }

  // Add dark mode styles
  &.dark-mode {

    &,
    .dropdown-menu {
      background: $dark-grey-2;
    }

    .dropdown-menu {
      h5 {
        color: white;
      }

      ::v-deep {
        li {
          background: $dark-grey-2;

          a {
            color: white;
            background: $dark-grey-2;

            &:hover {
              background: lighten($dark-grey-2, 10%);
            }
          }
        }
      }
    }

    p,
    li,
    span,
    a,
    button,
    div {
      color: white;
    }

    .nav {
      >li {
        >a {
          color: white;
        }
      }
    }
  }

  .dropdown-menu,
  ::v-deep .language-dropdown {
    @media (max-width: 991px) {
      li>a {
        color: $dark-grey-2;
      }
    }
  }

  p,
  li,
  span,
  a,
  button,
  div {
    font-family: $main-font-family;
    font-size: 16px;
    font-weight: 400;
    line-height: 150%;
  }

  .navbar-brand {
    #logo-img {
      max-height: 41px;
    }
  }

  .navbar-collapse {
    max-height: min(600px, 50vh);
  }

  .language-dropdown {
    transform: translateX(-60%);
    @media screen and (min-width: $screen-md-min) {
      max-height: calc(100vh - 80px);
      overflow-y: scroll;
    }
  }

  .header-container {
    @media (min-width: 992px) {
      display: flex;
      align-items: center;
      justify-content: space-between;

      .navbar-header {
        flex-grow: 0;
      }

      .navbar-collapse {
        flex-grow: 1;
      }
    }
  }

  .navbar-collapse {
    @media (min-width: 992px) {
      display: flex !important;
      justify-content: space-between;
      align-items: center;

      .nav.navbar-nav {
        flex-grow: 1;
        display: flex;
        justify-content: center;
      }

      .right {
        margin-left: auto;
        display: flex;
        align-items: center;
        > .login-buttons {
          position:relative;
          padding-right: 6px;
          margin-right: 6px;
          &:after {
            border-right: 1px solid $light-grey-2;
            content:'';
            position: absolute;
            right: 0;
            top: 5px;
            height: calc(100% - 10px);
          }
        }
      }
    }
  }

  @media (min-width: $grid-float-breakpoint) {
    .dropdown-hover:hover {
      &>ul {
        /* Allows for mouse over to expand dropdown */
        display: unset;
      }
    }
  }

  .nav {
    >li {
      >a {
        color: $dark-grey-2;
        text-align: center;
        font-family: $main-font-family;
        font-style: normal;
        text-shadow: none;
      }
    }
  }

  .login-buttons {
    li {
      margin: auto 10px;
    }
  }
}
</style>
