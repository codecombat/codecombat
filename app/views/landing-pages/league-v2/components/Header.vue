<template>
  <header-component :show-cubes-image="false" class="container__header">
    <template #header-text>
      <h1 class="text-h1">
        <mixed-color-label :text="$t('league_v2.headline')" />
      </h1>
      <p class="text-24">
        {{ $t('league_v2.subhead') }}
      </p>
      <CTAButton
        v-if="me.isAnonymous()"
        class="contact-solution signup-button"
        data-start-on-path="teacher"
      >
        {{ $t('league_v2.join_cta') }}
      </CTAButton>
      <CTAButton
        v-else
        class="contact-solution"
        @clickedCTA="showContactModal = true"
      >
        {{ $t('league_v2.create_cta') }}
      </CTAButton>
    </template>
    <template #image>
      <content-box :main-image-bg="false">
        <template #image>
          <video-box
            video-id="d0ea8486d87f3d998564fd48445bc965"
          />
        </template>
      </content-box>
    </template>
  </header-component>

</template>