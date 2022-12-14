<script>
import {
  CODECOMBAT,
  CODECOMBAT_CHINA,
  OZARIA,
  OZARIA_CHINA,
  isOldBrowser,
  isCodeCombat,
  isOzaria,
  getQueryVariable
} from 'core/utils'
import { mapActions, mapGetters } from 'vuex'
import FinalFooter from './FinalFooter'

/**
 * Unified footer component between CodeCombat and Ozaria.
 */
export default Vue.extend({
  components:{
    FinalFooter
  },
  computed: {
    isCodeCombat () {
      return isCodeCombat
    },

    isOzaria () {
      return isOzaria
    },

    isChinaHome () {
      return features.chinaHome
    },

    cocoBaseURL () {
      if (this.isCodeCombat) {
        return ''
      }

      if (!application.isProduction()) {
        return `${document.location.protocol}//codecombat.com`
      }

      // We are on ozaria domain.
      return `${document.location.protocol}//${document.location.host}`
        .replace(OZARIA, CODECOMBAT)
        .replace(OZARIA_CHINA, CODECOMBAT_CHINA)
    },

    ozBaseURL () {
      if (this.isOzaria) {
        return ''
      }

      if (!application.isProduction()) {
        return `${document.location.protocol}//ozaria.com`
      }

      // We are on codecombat domain.
      return `${document.location.protocol}//${document.location.host}`
        .replace(CODECOMBAT, OZARIA)
        .replace(CODECOMBAT_CHINA, OZARIA_CHINA)
    },

    hideFooter () {
      return getQueryVariable('landing', false)
    },

    forumLink () {
      let link = 'https://discourse.codecombat.com/'
      const lang = (me.get('preferredLanguage') || 'en-US').split('-')[0]
      if (['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt'].includes(lang)) {
        link += `c/other-languages/${lang}`
      }
      return link
    },

    footerUrls () {
      /* footer url example
         column: {
         title: i18n keys on column title
         condition: display column or not, i.e. me.isStudent()
         lists: lists of links in footer }
         each link: {
         url: a.href
         title: i18n keys on link title
         extra: if we do not use i18n title, set this as span.spr
         attrs: extra dom attributes setting in object, i.e. {target: '_blank'}
         }

         chinaFooter is standalone so don't worry on China resources.
       */
      const globalFooter = [
        {
          title: '',
          condition: me.isStudent(),
          lists: []
        },
        {
          title: 'nav.general',
          condition: true, // always display
          lists: [
            { url: this.cocoPath('/about'), title: 'nav.about', attrs: { 'data-event-action': 'Click: Footer About' } },
            { url: 'https://codecombat.zendesk.com/hc/en-us', title: 'contact.faq', attrs: { target: '_blank', 'data-event-action': 'Click: Footer FAQ' } },
            { url: this.cocoPath('/about#careers'), title: 'nav.careers' },
            { title: 'nav.contact', attrs: { class: 'contact-modal', tabindex: -1 }, hide: !me.isTeacher() },
            { title: 'nav.contact', url: 'mailto:support@codecombat.com', attrs: { tabindex: -1 }, hide: me.isTeacher() },
            { url: this.cocoPath('/parents'), title: 'nav.parent' },
            { url: 'https://blog.codecombat.com/', title: 'nav.blog' }
          ]
        },
        {
          title: 'nav.educators',
          condition: !me.isStudent(),
          lists: [
            { url: '/efficacy', title: 'efficacy.ozaria_efficacy', hide: this.isCodeCombat},
            { url: '/impact', title: 'nav.impact', hide: this.isOzaria },
            { url: '/teachers/resources', title: 'nav.resource_hub' },
            { url: '/teachers/classes', title: 'nav.my_classrooms' },
            { url: this.ozPath('/'), title: 'new_home.try_ozaria', attrs: { 'data-event-action': 'Click: Footer Try Ozaria' }, hide: this.isOzaria},
            { url: this.cocoPath('/'), title: 'nav.return_coco', attrs: { 'data-event-action': 'Click: Footer Return to CodeCombat' }, hide: this.isCodeCombat},
            { url: this.cocoPath('/partners'), title: 'nav.partnerships' },
            { url: this.cocoPath('/podcast'), title: 'nav.podcast' }
          ]
        },
        {
          title: 'nav.get_involved',
          condition: true,
          lists: [
            { url: 'https://github.com/codecombat/codecombat', extra: 'GitHub' },
            { url: this.cocoPath('/community'), title: 'nav.community' },
            { url: this.cocoPath('/contribute'), title: 'nav.contribute' },
            { url: this.cocoPath('/league'), title: 'game_menu.multiplayer_tab' },
            { url: this.forumLink, title: 'nav.forum', attrs: { target: '_blank' }, hide: me.isStudent() || !me.showForumLink() }
          ]
        }
      ]

      const chinaFooter = [
        {
          title: '',
          condition: me.isStudent() || this.isChinaHome,
          lists: []
        },
        {
          title: 'nav.general',
          condition: !this.isChinaHome,
          lists: [
            { url: this.cocoPath('/events'), title: 'nav.events' },
            { url: this.cocoPath('/contact-cn'), title: 'nav.contact', hide: me.isStudent() },
            { url: this.cocoPath('/CoCoStar'), title: 'nav.star' },
          ]
        },
        {
          title: 'nav.educators',
          condition: !me.isStudent() && !this.isChinaHome,
          lists: [
            { url: '/teachers/resources/faq-zh-HANS.coco', title: 'teacher.educator_faq' },
            { url: '/teachers/resources', title: 'nav.resource_hub' },
            { url: '/teachers/resources', extra: '课程体系' },
            { url: 'teachers/classes', title: 'nav.my_classrooms' }
          ]
        },
        {
          title: 'nav.related_urls',
          condition: true,
          lists: [
            { url: 'https://xuetang.koudashijie.com', extra: '扣哒学堂' },
            { url: 'https://aojiarui.com', extra: '奥佳睿' },
            { url: 'https://aishiqingsai.org.cn', extra: 'AI世青赛' },

            { url: 'https://koudashijie.com', extra: '扣哒世界', hide: !this.isChinaHome },
            { url: 'https://codecombat.cn', extra: 'CodeCombat 个人版', hide: this.isChinaHome },
          ]
        }
      ]

      if (window.me.showChinaResourceInfo()) {
        return chinaFooter
      } else {
        return globalFooter
      }
    }
  },

  created () {
    // Bind the global values to the vue component.
    this.me = me
    this.document = window.document
  },
  methods: {
    footerEvent (e) {
      // Only track if user has clicked a link on the footer
      if (!e || !e.target || e.target.tagName !== 'A') {
        return
      }

      if (!window.tracker) {
        return
      }

      const clickedAnchorTag = e.target
      const action = `Link: ${clickedAnchorTag.getAttribute('href') || clickedAnchorTag.getAttribute('data-event-action')}`
      const properties = {
        category: 'Footer',
        // Inspired from the HomeView homePageEvent method
        user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
      }

      window.tracker.trackEvent(action, properties)
    },

    /**
     * This is used to highlight footer routes we are currently on.
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
  }
})
</script>

<template lang="pug">
footer#site-footer.small(:class="/^\\/(league|play\\/ladder)/.test(document.location.pathname) ? 'dark-mode' : ''" @click="footerEvent")
  .container(v-if="!hideFooter")
    .row
      .col-lg-12
        .row
          .col-lg-3(v-for="col in footerUrls" v-if="col.condition" :class="!col.lists.length ? 'shrunken-empty-column' : ''")
            h3 {{ $t(col.title) }}
            ul.list-unstyled
              li(v-for="l in col.lists" v-if="!l.hide")
                a(:href="l.url" v-bind="l.attrs") {{ $t(l.title) }}
                  span.spr(v-if="l.extra") {{ l.extra }}
              li(v-if="col.title === 'nav.general'")
                mklog-ledger(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W' kind='popper')
                  a(href="#changelog")
                    span Changelog
                    mklog-since-last-viewed(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W', color="candy")
          .col-lg-3
            template(v-if="!me.showingStaticPagesWhileLoading() && me.useSocialSignOn()")
              h3 {{ $t("nav.follow_us") }}
              div.social-buttons
                a(href="https://www.youtube.com/channel/UCEl7Rs_jtl3hcbnp0xZclQA" target="_blank" data-event-action="Click: Footer Youtube")
                  img(src="/images/pages/base/youtube_symbol_button.png" width="40" alt="YouTube")
                a(href="https://twitter.com/codecombat" target="_blank" data-event-action="Click: Footer Twitter")
                  img(src="/images/pages/base/twitter_logo_btn.png" width="40" alt="Twitter")
                a(href="https://www.facebook.com/codecombat" target="_blank" data-event-action="Click: Footer Facebook")
                  img(src="/images/pages/base/facebook_logo_btn.png" width="40" alt="Facebook")
                a(href="https://www.instagram.com/codecombat/" target="_blank" data-event-action="Click: Footer Instagram")
                  img(src="/images/pages/base/instagram-logo.png" width="40" alt="Instagram")
            template(v-if="me.showChinaResourceInfo()")
              h3 {{ $t("nav.follow_us") }}
              .follow_us
                .socialicon
                  .si.si-wechat
                    .mpqrcode(v-if="isChinaHome")
                      img.mpqr(src="https://assets.koudashijie.com/images/homeVersion/mpqr.jpeg")
                    .mpqrcode(v-else)
                      .span
                        span='老师请扫'
                        img.mpqr(src="https://assets.koudashijie.com/images/mpqrcode.jpeg")
                      .span
                        span='家长请扫'
                        img.mpqr(src="https://assets.koudashijie.com/images/mpqrcode-xuetang.jpeg")
                  template(v-if="!isChinaHome")
                    .si.si-tiktok
                      .tkqrcode
                        img.tkqr(src="https://assets.koudashijie.com/images/home/tiktokqr.jpg")
                    a.si.si-weibo(href='https://weibo.com/u/7404903646', target="_blank")
                    a.si.si-bilibili(href='https://space.bilibili.com/470975161/', target="_blank")

  final-footer
</template>

<style lang="sass" scoped>
@import "app/styles/bootstrap/variables"
@import "app/styles/mixins"
@import "app/styles/style-flat-variables"

footer#site-footer
  background-color: $navy
  color: white
  padding-top: 20px
  margin-top: 50px

  @media print
    display: none

  .small
    font-family: $body-font
    font-weight: normal
    font-size: 14px
    line-height: 19px
    letter-spacing: 0.58px

  h3
    color: $teal
    font-family: Arvo
    font-size: 24px
    font-weight: bold
    letter-spacing: 0.48px
    line-height: 30px
    margin: 20px auto
    display: block
    font-variant: normal

  li
    font-family: "Open Sans"
    font-size: 18px
    letter-spacing: 0.75px
    line-height: 26px
    font-weight: 200

  .col-lg-3
    padding-bottom: 15px
    @media (max-width: $screen-md-min)
      padding-left: 27px

    &.shrunken-empty-column
      margin-right: -12.5%

  @media (max-width: $screen-sm-min)
    background-color: #201a15
    background-image: none
    height: auto

  a
    color: white

  .social-buttons > a
    margin-right: 20px

  .small
    color: rgba(255,255,255,0.8)

  .mpqr
    width: 95px

  .follow_us
    display: flex
    flex-direction: column
    .socialicon
      display: flex
      justify-content: space-between
      .si
        width: 50px
        height: 45px
        background-size: 50px
        background-position: center
        background-repeat: no-repeat
        position: relative
        cursor: pointer
      .si-bilibili
        background-image: url('https://assets.koudashijie.com/images/home/icon/bilibili-dark.png')
        &:hover
          background-image: url('https://assets.koudashijie.com/images/home/icon/bilibili-light.png')
      .si-wechat
        background-image: url('https://assets.koudashijie.com/images/home/icon/wechat-dark.png')
        &:hover
          background-image: url('https://assets.koudashijie.com/images/home/icon/wechat-light.png')
        &:hover .mpqrcode
          display: flex
      .si-tiktok
        background-image: url('https://assets.koudashijie.com/images/home/icon/tiktok-dark.png')
        &:hover
          background-image: url('https://assets.koudashijie.com/images/home/icon/tiktok-light.png')
        &:hover .tkqrcode
          display: flex
      .si-weibo
        background-image: url('https://assets.koudashijie.com/images/home/icon/weibo-dark.png')
        &:hover
          background-image: url('https://assets.koudashijie.com/images/home/icon/weibo-light.png')

    .tkqrcode
      display: none
      position: absolute
      top: 50px
      left: 0
      .tkqr
        width: 120px
    .mpqrcode
      display: none
      position: absolute
      top: 50px
      left: 0
      .span
        margin-right: 20px
        display: flex
        flex-direction: column
        align-items: center

  #final-footer
    padding: 20px 70px 14px
    color: rgba(255,255,255,0.8)
    background-color: $navy
    font-size: 14px

    .float-right
      padding-top: 15px
      float: right

    @media (max-width: $screen-md-min)
      position: inherit
      height: auto
      .float-right
        float: none

    @media (max-width: $screen-sm-min)
      background-color: #201a15

    a
      color: rgba(255,255,255,0.8)
      margin-left: 20px

    img
      height: 40px
      margin-right: 20px

    img#mps
      height: 1em
      margin-right: 0

    .small
      color: rgba(255,255,255,0.8)

    .contact
      margin-right: 20px

  mklog-ledger
    --mklog-color-brand-background: #0E4C60
    --mklog-color-brand-text: #1FBAB4

  mklog-since-last-viewed
    margin-left: 5px

footer#site-footer.dark-mode
  /*background-color: #0C1016*/

</style>
