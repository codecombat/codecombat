<style scoped>
    * {
        color: #065e73;
    }
    li {
        display: inline;
    }
    li:not(:first-child):before {
        color: #000;
        content: " > ";
    }
</style>

<template>
    <div class="breadcrumbs rtl-allowed">
        <li v-for="link in links">
            <a v-if="link.href" :href="link.href">{{ link.i18n ? $t(link.i18n) : link.text }}</a>
            <span v-else-if="link.i18n">{{ $t(link.i18n) }}</span>
            <span v-else>{{ link.text }}</span>
        </li>
    </div>
</template>

<script>
  export default {
    props: {
      /**
      * Each item represents a link with optional href, i18n translated description or just plain text
      * {Array} links
      * {?string} links.href: the location for the breadcrumb. Skip this to render the link as text and not a href.
      * {?string} links.i18n: the lookup value to use i18n as the display text
      * {?string} links.text: plain text to display instead of i18n
      */
      links: Array,
    },
  }
</script>
