<template>
    <span class="fit"><slot></slot></span>
</template>

<script>
  import fitty from 'fitty';

  export default {
    props: {
      options: {
        type: Object,
        required: false,
        default() {
          return {
            minSize: 16,
            maxSize: 512,
            multiLine: true
          };
        }
      }
    },

    data() {
      return {
        _fitty: undefined
      };
    },

    destroyed() {
      this._fitty.unsubscribe();
    },
    mounted() {
      this._fitty = fitty(this.$el, this.options);
    }
  };
</script>

<style scoped>
    .fit {
        display: inline-block;
        /* Override the fitty style that breaks titles on smaller screens */
        white-space: normal !important;
    }
</style>
