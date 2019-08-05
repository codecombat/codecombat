import { storiesOf } from '@storybook/vue'
import { action } from '@storybook/addon-actions'
import { linkTo } from '@storybook/addon-links'

import BaseButton from '../ozaria/site/components/common/BaseButton.vue'

storiesOf('BaseButton', module).add('pure vue button', () => ({
  components: { BaseButton },
  template: '<base-button text="Hello, World!" />'
}))
