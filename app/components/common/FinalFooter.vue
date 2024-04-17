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
          img: '/images/footer/facebook.svg',
          alt: 'Facebook'
        }, {
          href: 'https://twitter.com/CodeCombat',
          img: '/images/footer/twitter.svg',
          alt: 'Twitter'
        }, {
          href: 'https://www.instagram.com/codecombat/',
          img: '/images/footer/instagram.svg',
          alt: 'Instagram'
        }, {
          href: 'https://www.linkedin.com/company/codecombat',
          img: '/images/footer/linkedin.svg',
          alt: 'LinkedIn'
        }, {
          href: 'https://www.youtube.com/@CodeCombat1',
          img: '/images/footer/youtube.svg',
          alt: 'YouTube'
        }, {
          href: 'https://www.tiktok.com/@codecombat_tiktok',
          img: '/images/footer/tiktok.svg',
          alt: 'TikTok'
        }, {
          href: 'https://discord.gg/vkW2dCYaxe',
          img: '/images/footer/discord.svg',
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
      a(v-for="socialLink in socialLinks" :href="socialLink.href" :key="socialLink.href" target="_blank")
        img(:src="socialLink.img" :alt="socialLink.alt")
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
    img
      height: 24px
</style>
