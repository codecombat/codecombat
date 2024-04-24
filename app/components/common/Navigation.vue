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

const cocoPath = function (relativePath) {
  return `${cocoBaseURL()}${relativePath}`
}

const ozPath = function (relativePath) {
  return `${ozBaseURL()}${relativePath}`
}

export const items = {
  CREATE_FREE_ACCOUNT: { class: 'signup-button', title: 'nav.create_free_account' },
  SCHOOL_AND_DISTRICT: { url: cocoPath('/schools'), title: 'nav.school_district_solutions' },
  TEACHER_TOOLKIT_PREVIEW: { url: '/teachers/resources', title: 'nav.teacher_toolkit_preview' },
  TEACHER_TOOLKIT: { url: '/teachers/resources', title: 'nav.teacher_toolkit' },
  STANDARDS: { url: cocoPath('/standards'), title: 'teacher_dashboard.standards_alignment' },
  EFFICACY: { url: ozPath('/efficacy'), title: 'nav.efficacy_studies' },
  SUCCESS: { url: '/impact', title: 'nav.success_stories' },
  PD: { url: '/pd', title: 'teacher_dashboard.pd' },
  HOC: { url: cocoPath('/teachers/hour-of-code'), title: 'nav.hoc' },
  GRANTS: { url: cocoPath('/grants'), title: 'nav.grants_funding_resources' },
  DEMO: { url: '/teachers/quote', title: 'nav.request_quote_demo' },
  COCO_CLASSROOM: { url: cocoPath('/schools'), title: 'nav.codecombat_classroom' },
  COCO_JUNIOR: { url: cocoPath('/play/junior'), title: 'nav.coco_junior_beta' },
  COCO_HOME: { url: cocoPath('/play'), title: 'nav.codecombat_home' },
  OZ_CLASSROOM: { url: ozPath('/'), title: 'nav.ozaria_classroom' },
  AP_CSP: { url: cocoPath('/apcsp'), title: 'nav.ap_csp' },
  AI_LEAGUE: { url: cocoPath('/league'), title: 'nav.ai_league_esports' },
  ROBLOX: { url: cocoPath('/roblox'), title: 'nav.codecombat_worlds_on_roblox' },
  AI_HACKSTACK: { url: cocoPath('/ai'), title: 'nav.ai_hackstack_beta' },
  AI_HACKSTACK_JUNIOR: { url: 'https://docs.google.com/forms/d/e/1FAIpQLSfcWo6JVeFP30OslksUwE1Z-XyWFIKW3h81v08aYU1-vbhSUA/viewform', attrs: { target: '_blank' }, title: 'nav.ai_hackstack_junior_beta' },
  LIVE_ONLINE_CLASSES: { url: cocoPath('/parents'), title: 'nav.live_online_classes' },
  PREMIUM: { url: cocoPath('/premium'), title: 'nav.premium_self_paced' },
  CODEQUEST: { url: cocoPath('/codequest'), title: 'nav.codequest' },
  LIBRARY_SOLUTIONS: { url: cocoPath('/libraries'), title: 'nav.library_solutions' },
  PARTNER_SOLUTIONS: { url: cocoPath('/partners'), title: 'nav.partner_solutions' },
  TEACHING_SOLUTIONS: { url: cocoPath('/schools'), title: 'nav.teaching_solutions' },
  PRIVACY: { url: '/privacy', title: 'nav.privacy' }
}

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
    },

    homeLink () {
      if (me.isCodeNinja() && me.isStudent()) { return '/students' }
      if (me.isCodeNinja() && me.isTeacher()) { return '/teachers/classes' }
      if (me.isTarena()) { return 'http://kidtts.tmooc.cn/ttsPage/login.html' }
      if (this.hideNav) { return '#' }
      return '/home'
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
    },

    getNavbarData () {
      const anonymous = {
        educators: {
          url: isCodeCombat ? '/schools' : '/',
          title: 'nav.educators',
          children: [
            items.CREATE_FREE_ACCOUNT,
            items.SCHOOL_AND_DISTRICT,
            items.TEACHER_TOOLKIT_PREVIEW,
            items.STANDARDS,
            items.EFFICACY,
            items.SUCCESS,
            items.PD,
            items.HOC,
            items.GRANTS,
            items.DEMO
          ]
        },
        parents: {
          url: this.cocoPath('/parents'),
          title: 'nav.parent'
        },
        play: {
          url: this.cocoPath('/play'),
          title: 'nav.play2',
          children: [
            {
              ...items.COCO_HOME,
              description: 'nav.coco_home_description'
            },
            {
              ...items.COCO_CLASSROOM,
              class: 'signup-button',
              url: null,
              description: 'nav.coco_classroom_description'
            },
            {
              ...items.COCO_JUNIOR,
              description: 'nav.coco_junior_description'
            },
            {
              ...items.OZ_CLASSROOM,
              description: 'nav.oz_classroom_description'
            },
            {
              ...items.AP_CSP,
              description: 'nav.ap_csp_description'
            },
            {
              ...items.AI_LEAGUE,
              description: 'nav.ai_league_description'
            },
            {
              ...items.ROBLOX,
              description: 'nav.roblox_description'
            },
            {
              ...items.AI_HACKSTACK,
              description: 'nav.ai_hackstack_description'
            },
            {
              ...items.AI_HACKSTACK_JUNIOR,
              description: 'nav.ai_hackstack_junior_description'
            }
          ]
        },
      }

      const educator = {
        'my-dashboards': {
          title: 'nav.my_dashborads',
          children: [
            { url: this.cocoPath('/teachers/classes'), hide: me.isSchoolAdmin(), title: 'CodeCombat Teacher Dashboard' },
            { url: this.ozPath('/teachers/classes'), hide: me.isSchoolAdmin(), title: 'Ozaria Teacher Dashboard' },
            { url: this.cocoPath('/school-administrator'), hide: !me.isSchoolAdmin(), title: 'CodeCombat Admin Dashboard' },
            { url: this.ozPath('/school-administrator'), hide: !me.isSchoolAdmin(), title: 'Ozaria Admin Dashboard' },
          ]
        },
        resources: {
          title: 'nav.resources',
          children: [
            items.TEACHER_TOOLKIT,
            items.SCHOOL_AND_DISTRICT,
            items.STANDARDS,
            { ...items.EFFICACY, filter: isOzaria },
            { ...items.SUCCESS, filter: isCodeCombat },
            items.PD,
            items.HOC,
            items.GRANTS,
            items.DEMO
          ]
        },
        curriculum: {
          title: 'nav.curriculum',
          children: [
            items.COCO_CLASSROOM,
            items.COCO_JUNIOR,
            items.OZ_CLASSROOM,
            items.AP_CSP,
            items.AI_LEAGUE,
            items.ROBLOX,
            items.AI_HACKSTACK,
            items.AI_HACKSTACK_JUNIOR
          ]
        }
      }

      const student = {
        'my-courses': {
          title: 'nav.my_courses',
          children: [
            items.COCO_CLASSROOM,
            items.OZ_CLASSROOM,
            items.AI_LEAGUE,
            items.ROBLOX,
            items.AI_HACKSTACK,
          ]
        }
      }

      const parent = {
        dashboard: {
          title: 'nav.dashboard',
          url: me.hasNoVerifiedChild() ? this.cocoPath('/parents/add-another-child') : this.cocoPath('/parents/dashboard')
        },
        'learning-options': {
          title: 'nav.learning_options',
          children: [
            items.LIVE_ONLINE_CLASSES,
            items.PREMIUM,
            items.CODEQUEST,
          ]
        },
        curriculum: {
          title: 'nav.curriculum',
          children: [
            items.COCO_HOME,
            items.COCO_JUNIOR,
            items.AI_LEAGUE,
            items.ROBLOX,
            items.AI_HACKSTACK,
            items.AI_JUNIOR
          ]
        }
      }
      const individual = {
        'learning-options': {
          title: 'nav.learning_options',
          children: [
            items.LIVE_ONLINE_CLASSES,
            items.PREMIUM,
            items.CODEQUEST,
          ]
        },
        play: {
          title: 'nav.play2',
          children: [
            items.COCO_HOME,
            items.COCO_JUNIOR,
            items.AI_LEAGUE,
            items.ROBLOX,
            items.AI_HACKSTACK,
            items.AI_JUNIOR,
          ]
        }
      }

      if (me.isAnonymous()) {
        return anonymous
      }

      if (me.isTeacher()) {
        return educator
      }

      if (me.isStudent()) {
        return student
      }

      if (me.isParentHome()) {
        return parent
      }

      return individual
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
            a.navbar-brand(v-if="me.useTarenaLogo()" :href="homeLink")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img#tarena-logo(src="/images/pages/base/logo-tarena.png" alt="Tarena logo")
            a.navbar-brand(v-else-if="serverConfig.codeNinjas || me.isCodeNinja()" :href="homeLink")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img.code-ninjas-logo(src="/images/pages/base/code-ninjas-logo-right.png" alt="Code Ninjas logo")
            a.navbar-brand(v-else-if="me.isTecmilenio()" :href="homeLink")
              picture
                source#logo-img.powered-by(srcset="/images/pages/base/logo.webp" type="image/webp")
                img#logo-img.powered-by(src="/images/pages/base/logo.png" alt="CodeCombat logo")
              img.tecmilenio-logo(src="/images/pages/payment/tecmilenio-logo-2.png" alt="Tecmilenio logo")
            a.navbar-brand(v-else-if="showHackStackLogo" :href="homeLink")
              img#logo-img(src="/images/pages/base/logo+hs.png" alt="CodeCombat and HackStack logo")
            a.navbar-brand(v-else-if="me.showChinaResourceInfo()" :href="homeLink")
              img#logo-img(src="/images/pages/base/logo-en+cn.png" alt="CodeCombat logo")
            a.navbar-brand(v-else :href="homeLink")
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

              li(v-for="navItem in getNavbarData()")
                ul.nav.navbar-nav(v-if="navItem.children")
                  li.dropdown.dropdown-hover
                    a.text-p(:href="navItem.url", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                      span {{ $t(navItem.title) }}
                      caret.dropdown-caret
                    ul(class="dropdown-menu" :class="navItem.children.some(child => child.description) && 'text-wide'")
                      li(v-for="child in navItem.children.filter(child => child.hide!==true)")
                        a.text-p(:href="child.url" :class="[child.class, child.url && checkLocation(child.url) && 'text-teal'].filter(Boolean)" v-bind="child.attrs") {{ $t(child.title) }}
                          div.text-description(v-if="child.description") {{ $t(child.description) }}

                a.text-p(v-else :href="navItem.url") {{ $t(navItem.title) }}

            ul.nav.navbar-nav.loggedin(v-if="!me.isAnonymous()")
              li(v-if="me.isTarena()")
                a.text-p#logout-button {{ $t('login.log_out') }}
              li.dropdown(v-else)
                a.dropdown-toggle.text-p(href="#", data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false")
                  img.img-circle.img-circle-small.m-r-1(:src="me.getPhotoURL()" :class="{'border-navy': me.isTeacher()}")
                  span.unreadMessage(v-if="unread")
                  span {{ $t('nav.my_account') }}
                  caret.dropdown-caret
                ul.dropdown-menu
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
                      caret.rotate-left(v-if="this.announcements.length")
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

  .dropdown-menu.text-wide {
    width: 400px;
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

    .nav.navbar-nav {
      max-width: 100%;
    }
  }

  .language-dropdown {
    left: unset;
    right: 0;

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
        max-width: 100%;
        flex-grow: 1;
        display: flex;
        justify-content: center;

        &.loggedin {
          flex-grow: 0;
          position: relative;
          padding-right: 6px;
          margin-right: 6px;

          &:after {
            border-right: 1px solid $light-grey-2;
            content: '';
            position: absolute;
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            height: 27px;
          }
        }
      }

      .right {
        margin-left: auto;
        display: flex;
        align-items: center;

        >.login-buttons {
          position: relative;
          padding-right: 6px;
          margin-right: 6px;

          &:after {
            border-right: 1px solid $light-grey-2;
            content: '';
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

  li {
    >.text-p>.text-description {
      font-size: 12px;
      color: $dark-grey-2;
      white-space: normal;
      overflow: hidden;
      max-height: 0;
      transition: max-height 0.3s ease-in-out;
    }

    &:hover>.text-p>.text-description {
      max-height: 100px;
    }
  }

  .login-buttons {
    li {
      margin: auto 10px;
    }
  }

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

  span.unreadMessage {
    width: 5px;
    height: 5px;
    position: absolute;
    top: 10px;
    left: 45px;
    border-radius: 50%;
    background-color: $yellow;
    box-shadow: 0 0 2px 2px $yellow;
  }

  .dropleft {
    .announcement-nav {
      position: absolute;
      left: auto;
      right: 100%;
      top: 0;
    }

    .rotate-left {
      transform: rotate(90deg);
    }
  }

  span.unread {
    width: 1.2em;
    height: 1.2em;
    margin-left: 1em;
    line-height: 1.2em;
    border-radius: 50%;
    background-color: $yellow;
    color: white;
    display: inline-block;
    margin-left: 0.5em;
  }

  .dropdown-caret {
    margin-left: 5px;
  }

  .account-dropdown-item {
    display: flex;
    justify-content: center;
    align-items: center;
  }
}
</style>
