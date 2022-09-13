
<script>
  import NProgress from 'nprogress'
  import 'nprogress/nprogress.css'
  import 'ozaria/site/styles/loading-bar/nprogressOverride.css'

  NProgress.configure({ showSpinner: false, parent: '#loading-bar' })

  // TODO This component is used with `loading` as the key, which can be true or false
  // change it to be a unique value (number) so that it updates every time something is done loading
  export default {
    props: {
      loading: {
        type: Boolean,
        default: false
      }
    },

    mounted () {
      if (this.loading === false) {
        this.endLoading()
      } else {
        this.incLoading()
      }
    },

    methods: {
      endLoading () {
        NProgress.done()
      },
      incLoading () {
        NProgress.start()
        NProgress.set(0.2) // TODO calc percentage to increment loading bar
      }
    }
  }
</script>

<template>
  <div id="loading-bar" />
</template>

<style scoped>
#loading-bar {
  position: absolute;
  width: 100%;
  height: 5px;
}
</style>
