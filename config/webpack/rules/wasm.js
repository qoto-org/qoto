module.exports = {
  test: /\.wasm$/,
  type: "javascript/auto",
  loader: "file-loader",
  options: {
    name: '[name]-[hash].[ext]'
  }
};
