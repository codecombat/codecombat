<script>
import {
  isCodeCombat,
  isOzaria
} from 'core/utils'

import { COCO_CHINA_CONST } from 'core/constants'

/**
 * Unified footer component between CodeCombat and Ozaria.
 */
export default Vue.extend({
  data () {
    return {
      socialLinks: [
        {
          href: 'https://www.facebook.com/codecombat',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
              <path
                  d="M80 299.3V512H196V299.3h86.5l18-97.8H196V166.9c0-51.7 20.3-71.5 72.7-71.5c16.3 0 29.4 .4 37 1.2V7.9C291.4 4 256.4 0 236.2 0C129.3 0 80 50.5 80 159.4v42.1H14v97.8H80z" />
          </svg>`,
          alt: 'Facebook'
        }, {
          href: 'https://twitter.com/CodeCombat',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
              <path
                  d="M459.4 151.7c.3 4.5 .3 9.1 .3 13.6 0 138.7-105.6 298.6-298.6 298.6-59.5 0-114.7-17.2-161.1-47.1 8.4 1 16.6 1.3 25.3 1.3 49.1 0 94.2-16.6 130.3-44.8-46.1-1-84.8-31.2-98.1-72.8 6.5 1 13 1.6 19.8 1.6 9.4 0 18.8-1.3 27.6-3.6-48.1-9.7-84.1-52-84.1-103v-1.3c14 7.8 30.2 12.7 47.4 13.3-28.3-18.8-46.8-51-46.8-87.4 0-19.5 5.2-37.4 14.3-53 51.7 63.7 129.3 105.3 216.4 109.8-1.6-7.8-2.6-15.9-2.6-24 0-57.8 46.8-104.9 104.9-104.9 30.2 0 57.5 12.7 76.7 33.1 23.7-4.5 46.5-13.3 66.6-25.3-7.8 24.4-24.4 44.8-46.1 57.8 21.1-2.3 41.6-8.1 60.4-16.2-14.3 20.8-32.2 39.3-52.6 54.3z" />
          </svg>`,
          alt: 'Twitter'
        }, {
          href: 'https://www.instagram.com/codecombat/',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">
              <path
                  d="M224.1 141c-63.6 0-114.9 51.3-114.9 114.9s51.3 114.9 114.9 114.9S339 319.5 339 255.9 287.7 141 224.1 141zm0 189.6c-41.1 0-74.7-33.5-74.7-74.7s33.5-74.7 74.7-74.7 74.7 33.5 74.7 74.7-33.6 74.7-74.7 74.7zm146.4-194.3c0 14.9-12 26.8-26.8 26.8-14.9 0-26.8-12-26.8-26.8s12-26.8 26.8-26.8 26.8 12 26.8 26.8zm76.1 27.2c-1.7-35.9-9.9-67.7-36.2-93.9-26.2-26.2-58-34.4-93.9-36.2-37-2.1-147.9-2.1-184.9 0-35.8 1.7-67.6 9.9-93.9 36.1s-34.4 58-36.2 93.9c-2.1 37-2.1 147.9 0 184.9 1.7 35.9 9.9 67.7 36.2 93.9s58 34.4 93.9 36.2c37 2.1 147.9 2.1 184.9 0 35.9-1.7 67.7-9.9 93.9-36.2 26.2-26.2 34.4-58 36.2-93.9 2.1-37 2.1-147.8 0-184.8zM398.8 388c-7.8 19.6-22.9 34.7-42.6 42.6-29.5 11.7-99.5 9-132.1 9s-102.7 2.6-132.1-9c-19.6-7.8-34.7-22.9-42.6-42.6-11.7-29.5-9-99.5-9-132.1s-2.6-102.7 9-132.1c7.8-19.6 22.9-34.7 42.6-42.6 29.5-11.7 99.5-9 132.1-9s102.7-2.6 132.1 9c19.6 7.8 34.7 22.9 42.6 42.6 11.7 29.5 9 99.5 9 132.1s2.7 102.7-9 132.1z" />
          </svg>`,
          alt: 'Instagram'
        }, {
          href: 'https://www.linkedin.com/company/codecombat',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">
              <path
                  d="M100.3 448H7.4V148.9h92.9zM53.8 108.1C24.1 108.1 0 83.5 0 53.8a53.8 53.8 0 0 1 107.6 0c0 29.7-24.1 54.3-53.8 54.3zM447.9 448h-92.7V302.4c0-34.7-.7-79.2-48.3-79.2-48.3 0-55.7 37.7-55.7 76.7V448h-92.8V148.9h89.1v40.8h1.3c12.4-23.5 42.7-48.3 87.9-48.3 94 0 111.3 61.9 111.3 142.3V448z" />
          </svg>`,
          alt: 'LinkedIn'
        }, {
          href: 'https://www.youtube.com/@CodeCombat1',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512">
              <path
                  d="M549.7 124.1c-6.3-23.7-24.8-42.3-48.3-48.6C458.8 64 288 64 288 64S117.2 64 74.6 75.5c-23.5 6.3-42 24.9-48.3 48.6-11.4 42.9-11.4 132.3-11.4 132.3s0 89.4 11.4 132.3c6.3 23.7 24.8 41.5 48.3 47.8C117.2 448 288 448 288 448s170.8 0 213.4-11.5c23.5-6.3 42-24.2 48.3-47.8 11.4-42.9 11.4-132.3 11.4-132.3s0-89.4-11.4-132.3zm-317.5 213.5V175.2l142.7 81.2-142.7 81.2z" />
          </svg>`,
          alt: 'YouTube'
        }, {
          href: 'https://www.tiktok.com/@codecombat_tiktok',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">
              <path
                  d="M448 209.9a210.1 210.1 0 0 1 -122.8-39.3V349.4A162.6 162.6 0 1 1 185 188.3V278.2a74.6 74.6 0 1 0 52.2 71.2V0l88 0a121.2 121.2 0 0 0 1.9 22.2h0A122.2 122.2 0 0 0 381 102.4a121.4 121.4 0 0 0 67 20.1z" />
          </svg>`,
          alt: 'TikTok'
        }, {
          href: 'https://discord.gg/vkW2dCYaxe',
          img: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512">
              <path
                  d="M524.5 69.8a1.5 1.5 0 0 0 -.8-.7A485.1 485.1 0 0 0 404.1 32a1.8 1.8 0 0 0 -1.9 .9 337.5 337.5 0 0 0 -14.9 30.6 447.8 447.8 0 0 0 -134.4 0 309.5 309.5 0 0 0 -15.1-30.6 1.9 1.9 0 0 0 -1.9-.9A483.7 483.7 0 0 0 116.1 69.1a1.7 1.7 0 0 0 -.8 .7C39.1 183.7 18.2 294.7 28.4 404.4a2 2 0 0 0 .8 1.4A487.7 487.7 0 0 0 176 479.9a1.9 1.9 0 0 0 2.1-.7A348.2 348.2 0 0 0 208.1 430.4a1.9 1.9 0 0 0 -1-2.6 321.2 321.2 0 0 1 -45.9-21.9 1.9 1.9 0 0 1 -.2-3.1c3.1-2.3 6.2-4.7 9.1-7.1a1.8 1.8 0 0 1 1.9-.3c96.2 43.9 200.4 43.9 295.5 0a1.8 1.8 0 0 1 1.9 .2c2.9 2.4 6 4.9 9.1 7.2a1.9 1.9 0 0 1 -.2 3.1 301.4 301.4 0 0 1 -45.9 21.8 1.9 1.9 0 0 0 -1 2.6 391.1 391.1 0 0 0 30 48.8 1.9 1.9 0 0 0 2.1 .7A486 486 0 0 0 610.7 405.7a1.9 1.9 0 0 0 .8-1.4C623.7 277.6 590.9 167.5 524.5 69.8zM222.5 337.6c-29 0-52.8-26.6-52.8-59.2S193.1 219.1 222.5 219.1c29.7 0 53.3 26.8 52.8 59.2C275.3 311 251.9 337.6 222.5 337.6zm195.4 0c-29 0-52.8-26.6-52.8-59.2S388.4 219.1 417.9 219.1c29.7 0 53.3 26.8 52.8 59.2C470.7 311 447.5 337.6 417.9 337.6z" />
          </svg>`,
          alt: 'Discord'
        }
      ]
    }
  },
  computed: {
    isCodeCombat () {
      return isCodeCombat
    },

    isOzaria () {
      return isOzaria
    }
  },
  created () {
    // Bind the global values to the vue component.
    this.me = me
    this.document = window.document
    this.COCO_CHINA_CONST = COCO_CHINA_CONST
  }
})
</script>

<template lang="pug">
  #final-footer(dir="ltr")
    img(v-if="isOzaria" src="/images/ozaria/home/ozaria-wordmark-500px.png" alt="Ozaria logo")
    picture(v-else)
      source(srcset="/images/pages/base/logo.webp" type="image/webp")
      img(src="/images/pages/base/logo.png" alt="CodeCombat logo")
    .social-links
      a(v-for="socialLink in socialLinks" :href="socialLink.href" :alt="socialLink.alt" :key="socialLink.href" target="_blank")
        div.img(v-html="socialLink.img")
    .copyright
      if me.showChinaResourceInfo()
        span.contact= "商务合作："+COCO_CHINA_CONST.CONTACT_EMAIL
      span {{ $t("nav.copyright_prefix") }}
      span= ' ©2024 CodeCombat Inc. '
      span {{ $t("nav.copyright_suffix") }}
      if me.showChinaResourceInfo()
        if me.showChinaHomeVersion()
          a.small(href="http://beian.miit.gov.cn/") 京ICP备19012263号-20
        else
          a.small(href="http://beian.miit.gov.cn/") 京ICP备19012263号
        if !me.showChinaHomeVersion()
          a.small(href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=11010802031936")
            img#mps(src="/images/pages/base/the_ministry_of_public_security_of_china.png")
            span='京公网安备 11010802031936号'
        else
          a.small(href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=11010802038619")
            img#mps(src="/images/pages/base/the_ministry_of_public_security_of_china.png")
            span='京公网安备 11010802038619号'
</template>

<style lang="sass" scoped>
@import "app/styles/bootstrap/variables"
@import "app/styles/mixins"
@import "app/styles/style-flat-variables"
@import "app/styles/component_variables"

#final-footer
  padding: 20px 70px 14px
  color: rgba($light-grey, 0.5)
  font-size: 14px

  display: flex
  flex-direction: column
  justify-content: center
  gap: 20px
  text-align: center

  @media (max-width: $screen-md-min)
    position: inherit
    height: auto

  img
    height: 40px
    margin-right: 20px

  img#mps
    height: 1em
    margin-right: 0

  .contact
    margin-right: 20px

  .social-links
    .img
      height: 24px
      display: inline-block
      margin-right: 20px
      ::v-deep
        svg
          height: 100%
          path
            fill: var(--color-primary)
</style>
