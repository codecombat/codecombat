<style scoped>
    .breadcrumbs > a {
         color: #065e73;
     }
</style>

<template>
    <div class="breadcrumbs rtl-allowed">
        Current state of links: {{ links }}
        <br>
<!--        TODO: Try a loop checking against length further than current length instead -->
        <a v-if="links.length > 0" :href="links[0].href">{{ links[0].i18n ? $t(links[0].i18n) : links[0].text }}</a>
        <span v-if="links.length > 1">
            <span v-if="links[1].href" class="spl spr">></span>
            <span v-else class="spl spr">>{{ links[1].i18n ? $t(links[1].i18n) : links[1].text }}</span>
            <a v-if="links[1].href" :href="links[1].href">{{ links[1].i18n ? $t(links[1].i18n) : links[1].text }}</a>
        </span>
        <span v-if="links.length > 2">
            <span v-if="links[2].href" class="spl spr">></span>
            <span v-else class="spl spr">>{{ links[2].i18n ? $t(links[2].i18n) : links[2].text }}</span>
            <a v-if="links[2].href" :href="links[2].href">{{ links[2].i18n ? $t(links[2].i18n) : links[2].text }}</a>
        </span>
    </div>
</template>

<script>
  export default {
    props: {
      /*
      Each item in the array needs at least one of the following:
      [Optional String] href: the location for the breadcrumb. Skip this to render the link as text and not a href.
      [Optional String] i18n: the lookup value to use i18n as the display text
      [Optional String] text: raw display text
      */
      links: Array,
    },
  }
</script>
