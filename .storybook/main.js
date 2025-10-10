/** @type { import('@storybook/vue-webpack5').StorybookConfig } */
import * as path from 'path';

const config = {
  stories: [
    "../**/*.stories.@(js|jsx|mjs|ts|tsx|mdx)",
  ],
  addons: [
    '@storybook/addon-actions',
    "@storybook/addon-links",
    {
      name: '@storybook/addon-docs',
      options: {
        configureJSX: true,
        vueDocgenOptions: {
          alias: {
            '@': path.resolve(__dirname, '../'),
          },
        },
      },
    },
    '@storybook/addon-controls',
    "@storybook/addon-essentials",
    "@storybook/addon-interactions"
  ],
  framework: {
    name: '@storybook/vue3-webpack5',
    options: {}
  },
  docs: {
    autodocs: true
  },
  middleware: require('./middleware'),
};

export default config;



