import { storiesOf } from '@storybook/vue'
import { action } from '@storybook/addon-actions'
import { linkTo } from '@storybook/addon-links'

import ModalInteractive from '../ozaria/site/components/interactive/PageInteractive/common/ModalInteractive.vue'
import BaseButton from '../ozaria/site/components/interactive/PageInteractive/common/BaseButton.vue'

storiesOf('ModalInteractive', module).add('pure vue modal', () => ({
  components: { ModalInteractive },
  template: '<modal-interactive />'
}))

storiesOf('BaseButton', module).add('pure vue button', () => ({
  components: { BaseButton },
  template: '<base-button text="Hello, World!" />'
}))
