<template>
  <div class="testimonial">
    <p
      v-if="quote"
      class="testimonial__quote"
    >
      {{ quote }}
    </p>
    <profile-card
      :name="name"
      :title="title"
      :image="image"
    />
  </div>
</template>

<script>
import ProfileCard from './ProfileCard.vue'

export default {
  name: 'TestimonialComponent',
  components: {
    ProfileCard
  },
  props: {
    quote: {
      type: String,
      default: null,
      required: false
    },
    name: {
      type: String,
      default: null,
      required: false
    },
    title: {
      type: String,
      default: null,
      required: false
    },
    image: {
      type: String,
      default: null,
      required: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.testimonial {
  &__quote {
    @extend %font-24-34;
    color: $dark-grey-2;
    font-style: italic;
    font-weight: 700;
  }
}
</style>
