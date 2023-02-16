<script>
import {
  isCodeCombat,
  isOzaria,
} from 'core/utils'

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
  },
  created () {
    // Bind the global values to the vue component.
    this.me = me
    this.document = window.document
    this.COCO_CHINA_CONST = COCO_CHINA_CONST
  },
})
</script>

<template lang="pug">
  #final-footer(dir="ltr")
    img(v-if="isOzaria" src="/images/ozaria/home/ozaria-wordmark-500px.png" alt="Ozaria logo")
    img(v-else src="/images/pages/base/logo.png" alt="CodeCombat logo")
    .float-right
      if me.showChinaResourceInfo()
        span.contact= "商务合作："+COCO_CHINA_CONST.CONTACT_EMAIL
      span {{ $t("nav.copyright_prefix") }}
      span= ' ©2023 CodeCombat Inc. '
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

      a.small(href="/legal") {{ $t("nav.term_of_service") }}
      a.small(href="/privacy") {{ $t("nav.privacy") }}
</template>

<style lang="sass" scoped>
@import "app/styles/bootstrap/variables"
@import "app/styles/mixins"
@import "app/styles/style-flat-variables"


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
</style>
