<template>
  <div
    v-if="bannerHtml"
    class="banner-component no-gap-banner"
  >
    <!-- eslint-disable vue/no-v-html -->
    <div
      class="content"
      v-html="bannerHtml"
    />
  </div>
</template>

<script>
const fetchJson = require('core/api/fetch-json')
const utils = require('core/utils')

export default {
  name: 'BannerComponent',
  data () {
    return {
      bannerHtml: '',
    }
  },
  mounted () {
    this.fetchBanner()
  },
  methods: {
    async fetchBanner () {
      try {
        const data = await fetchJson('/db/banner', { data: { cacheEdge: true } })
        if (!data) return
        const content = utils.i18n(data, 'content')
        // Use window.marked and window.DOMPurify
        if (window.marked && window.DOMPurify) {
          this.bannerHtml = window.DOMPurify.sanitize(window.marked(content || ''))
        } else if (window.marked) {
          this.bannerHtml = window.marked(content || '')
        } else {
          this.bannerHtml = content || ''
        }
      } catch (e) {
        this.bannerHtml = ''
      }
    },
  },
}
</script>

<!-- not scoped because of v-html -->
<style lang="scss">
@import "app/styles/component_variables.scss";

.banner-component {
  background-color: var(--color-primary-1, $purple);
  color: white;
  padding: 10px 0;
  text-align: center;
  font-size: 18px;
  line-height: 1.4;
  box-shadow: 0 2px 8px rgba(30, 80, 110, 0.06);
  width: 100%;
  max-width: 100vw;
  z-index: 10;

  .content {
    display: inline-block;
    max-width: 900px;
    margin: 0 auto;
    text-align: left;
    font-size: 18px;
    line-height: 1.5;
    word-break: break-word;
    a {
      color: white;
      font-weight: 700;
      margin-left: 8px;
      text-decoration: underline;
    }
    p {
      margin: 0;
      font-size: inherit;
      display: inline;
      color: inherit;
    }
  }
}

.no-gap-banner {
  margin-bottom: -80px !important;
}
</style>