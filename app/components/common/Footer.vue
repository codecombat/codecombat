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
  import { COCO_CHINA_CONST } from 'core/constants'
  
  /**
   * Unified footer component between CodeCombat and Ozaria.
   */
  export default Vue.extend({
    computed: {
      isCodeCombat () {
        return isCodeCombat
      },

      isOzaria () {
        return isOzaria
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
      }
    },

    created () {
      // Bind the global values to the vue component.
      this.me = me
      this.document = window.document
      this.COCO_CHINA_CONST = COCO_CHINA_CONST
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
            .col-lg-3
              h3 {{ $t("nav.general") }}
              ul.list-unstyled
                li
                  a(:href="cocoPath('/about')" data-event-action="Click: Footer About") {{ $t("nav.about") }}
                li(v-if="!me.showChinaResourceInfo()")
                  - var faqURL = "https://codecombat.zendesk.com/hc/en-us"
                  a(href=faqURL, target="_blank" data-event-action="Click: Footer FAQ") {{ $t("contact.faq") }}
                li(v-if="!me.showChinaResourceInfo()")
                  a(:href="cocoPath('/about#careers')") {{ $t("nav.careers") }}
                li(v-if="!me.showChinaResourceInfo()")
                  a.contact-modal(tabindex=-1) {{ $t("nav.contact") }}
                li(v-else-if="!me.isStudent()")
                  a(:href="cocoPath('/contact-cn')") {{ $t("nav.contact") }}
                li(v-if="!me.showChinaResourceInfo()")
                  a(:href="cocoPath('/parents')") {{ $t("nav.parent") }}
                li(v-if="!me.showChinaResourceInfo()")
                  a(href="https://blog.codecombat.com/", , target="_blank") {{ $t("nav.blog") }}
                li(v-if="me.isAdmin()")
                  mklog-ledger(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W' kind='popper')
                    a(href="#changelog")
                      span Changelog
                      mklog-since-last-viewed(v-pre organization='org-2F8P67Q21Vm51O97wEnzbtwrg9W', color="candy")
                li(v-if="me.showChinaResourceInfo()")
                  a(href="https://beian.miit.gov.cn/") 京ICP备19012263号
            .col-lg-3
              if !me.isStudent()
                h3 {{ $t("nav.educators") }}
                ul.list-unstyled
                  li(v-if="!me.showChinaResourceInfo()")
                    if isOzaria
                      a(href="/efficacy") {{ $t("efficacy.ozaria_efficacy") }}
                    else
                      a(href="/impact") {{ $t("nav.impact") }}
                  li
                    a(href="/teachers/resources") {{ $t("nav.resource_hub") }}
                  li
                    a(href="/teachers/classes") {{ $t("nav.my_classrooms") }}
                  li(v-if="isCodeCombat")
                    a(:href="ozPath('/')" data-event-action="Click: Footer Try Ozaria") {{ $t("new_home.try_ozaria") }}
                  li(v-else)
                    a(:href="cocoPath('/')" data-event-action="Click: Footer Return to CodeCombat") {{ $t("nav.return_coco") }}
                  li(v-if="!me.showChinaResourceInfo()")
                    a(:href="cocoPath('/partners')") {{ $t("nav.partnerships") }}
                  li(v-if="!me.showChinaResourceInfo()")
                    a(:href="cocoPath('/podcast')") {{ $t("nav.podcast") }}
            .col-lg-3(v-if="!me.showChinaResourceInfo()")
              h3 {{ $t("nav.get_involved") }}
              ul.list-unstyled
                li
                  a(href="https://github.com/codecombat/codecombat")
                    span.spr GitHub
                    //iframe.github-star-button(src="https://ghbtns.com/github-btn.html?user=codecombat&repo=codecombat&type=watch&count=true", allowtransparency="true", frameborder="0", scrolling="0", width="110", height="20") // Cute, but maybe not worth the extra requests.
                li
                  a(:href="cocoPath('/community')") {{ $t("nav.community") }}
                li
                  a(:href="cocoPath('/contribute')") {{ $t("nav.contribute") }}
                li
                  a(:href="cocoPath('/league')") {{ $t("game_menu.multiplayer_tab") }}
                if !me.isStudent() && me.showForumLink()
                  li
                    a(:href="forumLink", , target="_blank") {{ $t("nav.forum") }}
            .col-lg-3
              if !me.showingStaticPagesWhileLoading() && me.useSocialSignOn()
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
                  
              else if me.showChinaResourceInfo()
                h3 {{ $t("nav.follow_us") }}
                img.mpqr(src="https://assets.koudashijie.com/images/mpqrcode.jpeg")

    #final-footer(dir="ltr")
      if isOzaria
        img(src="/images/ozaria/home/ozaria-wordmark-500px.png" alt="Ozaria logo")
      else
        img(src="/images/pages/base/logo.png" alt="CodeCombat logo")
      .float-right
        if me.showChinaResourceInfo()
          span.contact= "商务合作："+COCO_CHINA_CONST.CONTACT_EMAIL
          span.contact= "业务咨询："+COCO_CHINA_CONST.CONTACT_PHONE
        span {{ $t("nav.copyright_prefix") }}
        span= ' ©2022 CodeCombat Inc. '
        span {{ $t("nav.copyright_suffix") }}
        a.small(href="/legal") {{ $t("nav.term_of_service") }}
        a.small(href="/privacy") {{ $t("nav.privacy") }}
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
