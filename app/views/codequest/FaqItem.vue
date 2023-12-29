<template>
  <div class="faq">
    <div
      class="text collapsed"
      data-toggle="collapse"
      :data-parent="parent"
      :href="href"
    >
      <div class="q">
        {{ question }}
      </div>
      <img
        class="vector"
        alt="Vector"
        src="/images/pages/codequest/chevron-down.svg"
      >
      <img
        class="vector up"
        alt="Vector"
        src="/images/pages/codequest/chevron-up.svg"
      >
    </div>
    <div
      :id="id"
      class="text-wrapper panel-collapse collapse"
    >
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  name: 'FaqItem',
  props: {
    question: {
      type: String,
      required: true
    },
    id: {
      type: String,
      required: true
    },
    href: {
      type: String,
      required: true
    },
    parent: {
      type: String,
      default: '#accordion'
    }
  }
}
</script>

<style scoped lang="scss">
.faq {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 0;
    justify-content: center;
    position: relative;
    border-bottom: 1px solid rgba(233, 232, 253, 1);
    width: 100%;
    margin-bottom: 24px;
}

.text {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    justify-content: flex-start;
    position: relative;
    cursor: pointer;
    padding-bottom: 24px;
    width: 100%;

    &.collapsed {

        .q {
            color: #6B7280;
        }
    }

    .vector {
        display: none;

        &.up {
            display: block;
        }
    }

    &.collapsed {
        .vector {
            display: block;

            &.up {
                display: none;
            }
        }
    }
}

.q {
    color: #000;
    font-family: "Plus Jakarta Sans-SemiBold", Helvetica;
    font-size: 18px;
    font-style: normal;
    font-weight: 500;
    line-height: 18px;
    /* 100% */
}

.vector {
    height: 7px;
    margin-right: -1px;
    position: absolute;
    width: 12px;
    right: 0;
    top: 0;

}

.q-wrapper {
    align-items: center;
    display: flex;
    flex: 0 0 auto;
    justify-content: center;
    position: relative;
}

.text-wrapper {
    color: #6b7280;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 14px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 22px;
    position: relative;
    padding: 0 0 24px 0;
}
</style>
