<script>
import ButtonScheduleFreeClass from './ButtonScheduleFreeClass'

export default {
  components: {
    ButtonScheduleFreeClass
  },

  methods: {
    onCtaClick () {
      this.$emit('cta-clicked')
    }
  },
  mounted: function () {
    // if (typeof Storage === 'undefined') {
    //   console.error('Cannot load griffin animation without localStorage')
    //   return
    // }

    function loadImage (frameNumber, onload, onerror) {
      // eslint-disable-next-line no-undef
      const img = new Image()
      img.onload = () => {
        onload(frameNumber, img)
        // delete img
      }
      img.onerror = () => {
        // TOD: Release img here?
        onerror(frameNumber)
      }
      img.src = `/images/pages/parents/Griffin_and_Alejandro${frameNumber}.svg`
    }

    const firstFrame = 1 // Assume the initial SVG is rendered ok in the html
    const totalFrames = 20
    const loadedFrames = [firstFrame]
    const maxRetries = 5
    let loadErrors = []

    // Start on frame 2, as the default picture is frame 1
    for (let i = firstFrame + 1; i < totalFrames + 1; i++) {
      const onload = (frameNumber, img) => {
        // const canvas = document.createElement(`canvas-${frameNumber}`)
        // document.body.appendChild(canvas)
        // const context = canvas.getContext('2d')
        // context.drawImage(img, 0, 0)
        // window.localStorage.setItem('image', `${context.getImageData(0, 0, img.width, img.height).data}`)

        // TODO: Is this useful?
        // document.body.removeChild(canvas)

        loadedFrames.push(frameNumber)
        if (loadedFrames.length === totalFrames) {
          startAnimating()
        }
      }
      const onerror = (frameNumber) => {
        // retry?
        if (loadErrors.length < maxRetries) {
          loadErrors.push(frameNumber)
          loadImage(onload, onerror)
        } else {
          // abort the whole thing?
          console.error(`cannot load griffon animation for frames: ${loadErrors}, cancelling`)
        }
      }
      loadImage(i, onload, onerror)
    }

    function startAnimating () {
      const animatingSvg = $('.animated-griffin')
      const animationDuration = 1200
      const timePerFrame = animationDuration / totalFrames
      let timeWhenLastUpdate
      let timeFromLastUpdate
      let frameNumber = 1

      function step (startTime) {
        if (!timeWhenLastUpdate) {
          timeWhenLastUpdate = startTime
        }

        timeFromLastUpdate = startTime - timeWhenLastUpdate

        if (timeFromLastUpdate > timePerFrame) {
          animatingSvg.attr('src', `/images/pages/parents/Griffin_and_Alejandro${frameNumber}.svg`)
          timeWhenLastUpdate = startTime
          frameNumber = (frameNumber >= totalFrames) ? 1 : frameNumber + 1
        }

        window.requestAnimationFrame(step)
      }

      step()
    }
  }
}
</script>

<template>
  <div class="top-jumbotron">
    <img class="animated-griffin"
         src="/images/pages/parents/Griffin_and_Alejandro1.svg"
         alt="flying griffin"/>
    <div class="row">
      <div class="col-lg-12">
        <h1>Live Online Coding Classes</h1>
        <h1>Your Child Will Love</h1>
      </div>
    </div>


    <div class="row">
      <div class="col-lg-12">
        <button-schedule-free-class
          @click="onCtaClick"
        />
      </div>
    </div>
  </div>

</template>

<style scoped>
  .top-jumbotron {
    margin-bottom: 0;
    min-height: 580px;

    padding-top: 155px;

    background-color: unset;

    position: relative;
    z-index: 2;

    text-align: center;
    min-height: 628px;

    background-image: url(/images/pages/parents/parent_hero_image.png),
      url(/images/pages/parents/image_cloud_3.svg),
      url(/images/pages/parents/image_cloud_4.svg),
      url(/images/pages/parents/image_cloud_3.svg),
      url(/images/pages/parents/image_cloud_1.svg);

    background-repeat: no-repeat,
      no-repeat,
      no-repeat,
      no-repeat,
      no-repeat;

    background-position: bottom left 5%,
      top 50px left 30px,
      top 35px right 280px,
      top 360px right 300px,
      bottom 52px right 475px;

    background-size: 500px,
      260px,
      90px,
      260px,
      250px;
  }

  @media (max-width: 1000px) {
    .top-jumbotron {
      /* Moves images out of the way of the heading to keep it legible */
      background-position: bottom -74% left -5%,
        top 50px left 30px,
        top 35px right 280px,
        top 360px right 300px,
        bottom 52px right 475px;
    }
  }

  .top-jumbotron h1 + h1 {
    margin-bottom: 58px;
  }

  .top-jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

  .animated-griffin {
    position: absolute;
    top: 30%;
    right: 6%;
  }

</style>
