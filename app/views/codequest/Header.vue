<template>
  <div class="header">
    <div class="overlap-group">
      <div class="content">
        <div class="header-text">
          <p class="title">
            <span class="text-wrapper">CodeQuest </span>
            <span class="span">2024 </span>
          </p>
          <p class="supporting-text">
            Join us for an immersive educational experience like no other, designed to inspire and empower the
            next
            generation of computer science innovators through coding and AI. Students aged 13-17 are welcome.
          </p>
          <div class="CTA">
            <ButtonA
              class="button-a-instance"
              href="https://docs.google.com/forms/d/e/1FAIpQLSf-Hq5e5COINPxh5soG0XIF0UNH9HjnAjXKz4EBinLmcmp2sw/viewform"
              property1="default"
              text="Apply Now"
            />
            <p class="div">
              An insightful real-world learning experience!
            </p>
          </div>
          <div class="partners">
            <img
              class="UC-berkeley-symbol"
              alt="Uc berkeley symbol"
              src="/images/pages/codequest/google.webp"
            >
            <img
              class="UC-berkeley-symbol"
              alt="Uc berkeley symbol"
              src="/images/pages/codequest/xcompany.webp"
            >
            <img
              class="UC-berkeley-symbol"
              alt="Uc berkeley symbol"
              src="/images/pages/codequest/apple.webp"
            >
            <img
              class="element"
              alt="Element"
              src="/images/pages/codequest/stanford.webp"
            >
            <img
              class="img"
              alt="Uc berkeley symbol"
              src="/images/pages/codequest/berkeley.webp"
            >
          </div>
        </div>
        <div class="header-image">
          <img
            class="cubes"
            alt="Cubes"
            src="/images/pages/codequest/cubes01.webp"
          >

          <div
            v-for="(image, index) in images"
            :key="index"
            class="image"
            :class="{ 'is-visible': currentImage === index }"
          >
            <img
              :src="image.src"
              :alt="image.alt"
            >
          </div>
          <img
            class="overlap-cubes overlap-cubes-2"
            alt="Overlap cubes"
            src="/images/pages/codequest/overlap_cubes_04.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-3"
            alt="Overlap cubes"
            src="/images/pages/codequest/overlap_cubes_02.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-4"
            alt="Overlap cubes"
            src="/images/pages/codequest/overlap_cubes_01.webp"
          >
          <img
            class="overlap-cubes overlap-cubes-5"
            alt="Overlap cubes"
            src="/images/pages/codequest/overlap_cubes_03.webp"
          >
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ButtonA from './ButtonA'

export default {
  name: 'HeaderComponent',
  components: {
    ButtonA
  },
  data () {
    return {
      currentImage: 0
    }
  },
  computed: {
    images () {
      return [
        { src: '/images/pages/codequest/coding/coding_1.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_2.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_3.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_4.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_5.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_6.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_7.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_8.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_9.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_10.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_11.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_12.jpg', alt: 'Header image' },
        { src: '/images/pages/codequest/coding/coding_13.jpg', alt: 'Header image' }
      ]
    }
  },
  created () {
    setTimeout(() => {
      this.currentImage = 0
    }, 0)
    setInterval(() => {
      this.currentImage = (this.currentImage + 1) % this.images.length
    }, 3000)
  }
}
</script>

<style scoped lang="scss">
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

        @media (max-width: 991px) {
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
            aspect-ratio: 5472 / 3648;
            overflow: hidden;

            transition: opacity 1s ease-in-out;
            opacity: 0;

            &.is-visible {
                opacity: 1;
            }

            img {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
        }

        @media (max-width: 991px) {
            margin-top: 20%;
        }

        margin-bottom: 20%;
    }

    .title {
        align-self: stretch;
        color: transparent;
        font-family: "Plus Jakarta Sans-Medium", Helvetica;
        font-size: 44px;
        font-weight: 500;
        letter-spacing: 0;
        line-height: 55px;
        margin-top: -1px;
        position: relative;
    }

    .text-wrapper {
        color: #4799A9;
    }

    .span {
        color: #0a2239;
    }

    .supporting-text {
        align-self: stretch;
        color: #6B7280;
        font-family: "Plus Jakarta Sans-Regular", Helvetica;
        font-size: 24px;
        font-style: normal;
        font-weight: 400;
        line-height: 30px;
        /* 125% */
    }

    .CTA {
        align-items: flex-start;
        display: inline-flex;
        flex: 0 0 auto;
        flex-direction: column;
        gap: 8px;
        justify-content: center;
        position: relative;
    }

    .button-a-instance {
        flex: 0 0 auto !important;
        width: 258px !important;
    }

    .div {
        color: #4799A9;
        font-family: "Plus Jakarta Sans-Bold", Helvetica;
        font-size: 14px;
        font-weight: 700;
        letter-spacing: 0;
        line-height: 32px;
        position: relative;
        white-space: nowrap;
        width: fit-content;
    }

    .partners {
        align-items: center;
        justify-content: space-around;
        width: 100%;
        display: flex;
        flex: 0 0 auto;
        flex-wrap: wrap;
        gap: 20px 0px;
        margin-right: -2px;
        position: relative;
    }

    .UC-berkeley-symbol {
        height: 40px;
        position: relative;
        width: 71.11px;
    }

    .element {
        height: 40px;
        object-fit: cover;
        position: relative;
        width: 91.25px;
    }

    .img {
        height: 40px;
        object-fit: cover;
        position: relative;
        width: 71.11px;
    }

    .overlap-cubes {
        position: absolute;
        width: 18%;
        z-index: 4;
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
