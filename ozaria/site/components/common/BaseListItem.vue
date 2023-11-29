<template>
  <div class="row list-item">
    <div class="col-xs-4">
      <a @click="clickHandler">{{ text }}</a>
    </div>
    <div
      v-if="slug"
      class="col-xs-4"
    >
      <span class="slug">{{ slug }}</span>
    </div>
    <div
      v-if="id"
      class="col-xs-4"
    >
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
  }
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
