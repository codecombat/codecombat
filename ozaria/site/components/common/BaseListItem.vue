<template>
  <div class="row list-item">
    <div class="col-xs-4">
      <a v-on:click="clickHandler">{{ text }}</a>
    </div>
    <div class="col-xs-4" v-if="slug">
      <span class="slug">{{ slug }}</span>
    </div>
    <div class="col-xs-4" v-if="id">
      <span class="id">{{ id }}</span>
    </div>
  </div>
</template>

<script>
// Simple list component used in the Cinematic/Interactive editor.
export default {
  props: {
    text: {
      type: String,
      required: true
    },
    clickHandler: {
      type: Function,
      required: true
    },
    slug: {
      type: String,
      required: false
    },
    id: {
      type: String,
      required: false
    }
  },
}
</script>

<style scoped>
.slug {
  color: #333333
}
.id {
  font-size: 0.7em
}
</style>
