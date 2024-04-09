<template>
  <div class="header">
    <div class="overlap-group">
      <div class="content">
        <div class="header-text">
          <slot name="header-text" />
        </div>
        <div class="header-image">
          <img
            class="cubes"
            alt="Cubes"
            src="/images/components/cubes.webp"
          >

          <div class="image">
            <slot name="image" />
          </div>
          <img
            class="overlap-cubes overlap-cubes-2"
            alt="Overlap cubes"
            src="/images/components/cube001_4.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-3"
            alt="Overlap cubes"
            src="/images/components/cube001_2.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-4"
            alt="Overlap cubes"
            src="/images/components/cube001_1.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-5"
            alt="Overlap cubes"
            src="/images/components/cube001_3.webp"
          >
        </div>
      </div>
    </div>
  </div>
</template>

<script>

export default {
  name: 'HeaderComponent',
  components: {
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.header {
    background-color: #ffffff;
    position: relative;
    padding-top: 170px;

    .overlap-group {
        position: relative;
    }

    .content {
        align-items: flex-start;
        display: flex;
        gap: 30px;

        @media (max-width: $screen-md-max) {
            flex-direction: column;
            align-items: center;
            gap: 60px;
        }
    }

    .header-text {
        align-items: flex-start;
        display: flex;
        flex-direction: column;
        gap: 40px;
        justify-content: center;
        position: relative;
        flex: 0 0 calc(40% - 15px);
        z-index: 2;
    }

    .header-image {
        flex: 0 0 calc(60% - 15px);
        position: relative;
        aspect-ratio: 5472/3648;
        width: 100%;

        .cubes {
            position: absolute;
            z-index: 1;
            width: 140%;
            top: -60%;
            left: -22%;
            transform: rotate(12deg);
        }

        .image {
            z-index: 2;
            width: 100%;
            box-shadow: 0px 6px 22px 0px rgba(0, 0, 0, 0.10);
            border-radius: 24px;
            position: absolute;
            height: max-content;
            overflow: hidden;

            transition: opacity 1s ease-in-out;

            img {
                width: 100%;
            }
        }

        @media (max-width: $screen-md-max) {
            margin-top: 20%;
        }

        margin-bottom: 10%;
    }

    .overlap-cubes {
        position: absolute;
        width: 18%;
        z-index: 4;
        transform: rotate(12deg);
    }

    .overlap-cubes-2 {
        right: 35%;
        top: -18%;
    }

    .overlap-cubes-3 {
        right: -8%;
        width: 22%;
        top: -17%;
    }

    .overlap-cubes-4 {
        right: -6%;
        width: 19%;
        bottom: -1%
    }

    .overlap-cubes-5 {
        right: 42%;
        width: 23%;
        bottom: -22%;
    }
}
</style>
