<script>
import { cocoBaseURL, getQueryVariable, isCodeCombat, isOzaria, ozBaseURL } from 'core/utils'
import { mapGetters } from 'vuex'
import FinalFooter from './FinalFooter'

/**
 * Unified footer component between CodeCombat and Ozaria.
 */
export default Vue.extend({
  components:{
    FinalFooter
  },
  computed: {
    ...mapGetters({
      'preferredLocale': 'me/preferredLocale',
    }),

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
      return cocoBaseURL()
    },

    ozBaseURL () {
      return ozBaseURL()
    },

    hideFooter () {
      return getQueryVariable('landing', false)
    },

    forumLink () {
      let link = 'https://discourse.codecombat.com/'
      const lang = this.preferredLocale.split('-')[0]
      if (['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt'].includes(lang)) {
        link += `c/other-languages/${lang}`
      }
      return link
    },

    apiLink () {
      let link = 'https://github.com/codecombat/codecombat-api'
      const lang = this.preferredLocale.split('-')[0]
      if (['zh'].includes(lang) || features.china) {
        link = this.cocoPath('/api-docs')
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
            { url: 'https://codecombat.zendesk.com/hc/en-us', title: 'nav.help_center', attrs: { target: '_blank', 'data-event-action': 'Click: Footer Help Center' } },
            { url: this.cocoPath('/about#careers'), title: 'nav.careers' },
            { title: 'nav.contact', attrs: { class: 'contact-modal', tabindex: -1 } },
            { url: 'https://blog.codecombat.com/', title: 'nav.blog' }
          ]
        },
        {
          title: 'nav.educators',
          condition: !me.isStudent() && !me.isRegisteredHomeUser(),
          lists: [
            { url: '/efficacy', title: 'nav.research_efficacy', hide: this.isCodeCombat },
            { url: '/impact', title: 'nav.research_impact', hide: this.isOzaria },
            { url: '/teachers/resources', title: 'nav.resource_hub' },
            { url: '/teachers/classes', title: 'nav.my_classrooms' },
            { url: '/pricing', title: 'nav.pricing', hide: true },
            { url: this.ozPath('/'), title: 'new_home.try_ozaria', attrs: { 'data-event-action': 'Click: Footer Try Ozaria' }, hide: this.isOzaria},
            { url: this.cocoPath('/'), title: 'nav.return_coco', attrs: { 'data-event-action': 'Click: Footer Return to CodeCombat' }, hide: this.isCodeCombat},
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
            { url: this.forumLink, title: 'nav.forum', attrs: { target: '_blank' }, hide: me.isStudent() || !me.showForumLink() },
            { url: this.apiLink, title: 'nav.api', attrs: { target: '_blank' }, hide: me.isStudent() }
          ]
        },{
          title: 'nav.products',
          condition: true,
          lists: [
            { url: this.ozPath('/'), title: 'nav.ozaria_classroom' },
            { url: this.cocoPath('/impact'), title: 'nav.codecombat_classroom' },
            { url: this.ozPath('/professional-development'), title: 'nav.professional_development' },
            { url: this.cocoPath('/parents'), title: 'nav.live_online_classes' },
            { url: this.cocoPath('/premium'), title: 'nav.codecombat_home' },
            { url: this.cocoPath('/league'), title: 'nav.esports' },
            { url: this.cocoPath('/partners'), title: 'nav.partnerships' },
            { url: this.cocoPath('/libraries'), title: 'nav.libraries' },
            { url: this.cocoPath('/roblox'), title: 'nav.codecombat_worlds_on_roblox' },
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
     */
    checkLocation (route) {
      const location = document.location.href
          .replace(document.location.hash, '')
          .replace(document.location.search, '')
      return route === new URL(location).pathname
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
      .col-lg-12.footer-links
        .row.footer-links__row
          .col.footer-links__col(v-for="col in footerUrls" v-if="col.condition" :class="!col.lists.length ? 'shrunken-empty-column' : ''")
            h3 {{ $t(col.title) }}
            ul.list-unstyled
              li(v-for="l in col.lists" v-if="!l.hide")
                a(v-if="!checkLocation(l.url)" :href="l.url" v-bind="l.attrs") {{ $t(l.title) }}
                  span.spr(v-if="l.extra") {{ l.extra }}
                span.active(v-if="checkLocation(l.url)") {{ $t(l.title) }}
                  span.spr(v-if="l.extra") {{ l.extra }}

              li(v-if="col.title === 'nav.general'")
                mklog-ledger(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W' kind='popper')
                  a(href="#changelog")
                    span Changelog
                    mklog-since-last-viewed(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W', color="candy")
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
  .active
    color: $teal

  .social-buttons > a
    margin-right: 10px

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

  .footer-links
    &__row
      display: flex
      flex-wrap: wrap
      margin-left: -15px
      margin-right: -15px
      justify-content: space-between
    &__col
      padding-left: 15px
      padding-right: 15px
      max-width: 25%
      @media (max-width: $screen-sm-min)
        flex: 0 0 50%
        max-width: 50%
      @media (max-width: $screen-xs-min)
        flex: 0 0 100%
        max-width: 100%

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
