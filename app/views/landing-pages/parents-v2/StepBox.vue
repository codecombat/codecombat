<template>
  <div class="tab">
    <header class="header">
      <div class="frame">
        <slot name="icon" />
        <div class="div">
          <div class="title">
            {{ title }}
          </div>
          <div class="text-wrapper">
            {{ subtitle }}
          </div>
        </div>
      </div>
    </header>
    <img
      class="image"
      :alt="imageAlt"
      :src="imageSrc"
    >
    <footer class="footer">
      <p class="p">
        {{ footerText }}
      </p>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'StepBox',
  props: {
    title: {
      type: String,
      required: true
    },
    subtitle: {
      type: String,
      required: true
    },
    imageAlt: {
      type: String,
      required: true
    },
    imageSrc: {
      type: String,
      required: true
    },
    footerText: {
      type: String,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.tab {
    align-items: normal;
    display: inline-flex;
    flex-direction: column;
    position: relative;

    .header {}

    .header,
    .footer {
        align-items: center;
        display: flex;
        flex-direction: column;
        gap: 8px;
        justify-content: center;
        padding: 16px;
        position: relative;
        border-radius: 24px 24px 0px 0px;
        background-color: var(--color-primary-2);
        flex:1;

        &.footer {
            border-radius: 0px 0px 24px 24px;
            background-color: var(--color-dark-grey);
        }
    }

    .image {
        aspect-ratio: 10 / 4;
        object-fit: cover;
        width: 100%;
    }

    .frame {
        gap: min(40px, 5vw);
        svg {
          max-width: 70px;
          width: 100%;
          min-width: 40px;
        }
        @media screen and (max-width: 768px){
          flex-direction: column ;
          svg {
            width: 40px;
          }
        }
    }

    .frame,
    .div {
        align-items: center;
        display: inline-flex;
        flex: 0 0 auto;
        position: relative;

        &.div {
            align-items: flex-start;
            flex-direction: column;
            justify-content: center;
        }
    }

    .title,
    .text-wrapper {
        position: relative;
        white-space: nowrap;
        width: fit-content;

        &.title {
            @extend %font-18-24;
            color: var(--color-dark-grey);
        }

        &.text-wrapper {
            @extend %font-36;
            font-weight: 500;
            color: var(--color-dark-grey);
        }
    }

    .p {
        align-self: stretch;
        color: #ffffff;
        @extend %font-28;
        position: relative;
        text-align: center;
    }
}
</style>
