const { readFileSync } = require('fs');
const { load } = require('js-yaml');
const { basename, join, resolve } = require('path');
const extname = require('path-complete-extname');
const { config, merge, webpackConfig: originalBaseWebpackConfig } = require('shakapacker');
const webpack = require('webpack');
const WebpackAssetsManifest = require('webpack-assets-manifest');
const nodeModulesRule = require('../rules/node_modules');
const tesseractRule = require('../rules/tesseract');
const localePackPaths = require('../generateLocalePacks');

const themePath = resolve('config', 'themes.yml');
const themes = load(readFileSync(themePath), 'utf8');

const baseWebpackConfig = {
  ...originalBaseWebpackConfig,
  plugins:
    originalBaseWebpackConfig.plugins.filter((plugin) => !(plugin instanceof WebpackAssetsManifest)),
};

/** @type {import('webpack').Configuration} */
const options = {
  entry: {
    ...localePackPaths.reduce((map, entry) => ({
      ...map,
      [basename(entry, extname(entry, extname(entry)))]: resolve(entry),
    }), {}),
    ...Object.keys(themes).reduce((themePaths, name) => ({
      ...themePaths,
      [name]: resolve(join(config.source_path, themes[name])),
    }), {}),
  },
  module: {
    rules: [
      nodeModulesRule,
      tesseractRule,
    ],
  },
  optimization: {
    chunkIds: 'total-size',
    moduleIds: 'size',
    runtimeChunk: {
      name: 'common',
    },
    splitChunks: {
      cacheGroups: {
        default: false,
        vendors: false,
        common: {
          name: 'common',
          chunks: 'all',
          minChunks: 2,
          minSize: 0,
          test: /^(?!.*[\\\/]node_modules[\\\/]react-intl[\\\/]).+$/,
        },
      },
    },
  },
  plugins: [
    new WebpackAssetsManifest({
      entrypoints: true,
      entrypointsUseAssets: true,
      integrity: true,
      integrityHashes: ['sha256'],
      output: config.manifestPath,
      publicPath: true,
      writeToDisk: true,
    }),
    new webpack.NormalModuleReplacementPlugin(
      /^history\//, (resource) => {
        // temporary fix for https://github.com/ReactTraining/react-router/issues/5576
        // to reduce bundle size
        resource.request = resource.request.replace(/^history/, 'history/es');
      },
    ),
  ],
};

module.exports = merge({}, baseWebpackConfig, options);
