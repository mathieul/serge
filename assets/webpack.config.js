const CopyWebpackPlugin = require('copy-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const webpack = require('webpack')
const path = require('path')

console.log( 'WEBPACK GO!');

module.exports = {
  devtool: 'source-map',
  entry: ['./elm/Stylesheets.elm', 'bootstrap-loader', './elm/Tasker.elm', './js/app.js'],
  output: {
    path: path.resolve(__dirname, '../priv/static'),
    filename: 'js/app.js',
  },
  resolve: {
    modules: [
      path.resolve(__dirname, './node_modules'),
      path.resolve(__dirname, './js'),
    ],
    extensions: ['.js', '.elm'],
    // alias: {
    //   phoenix: path.resolve(__dirname, '../deps/phoenix/assets/js/phoenix.js'),
    //   phoenix_html: path.resolve(__dirname, '../deps/phoenix_html/web/static/js/phoenix_html.js'),
    // }
  },
  plugins: [
    new CopyWebpackPlugin([{ from: './static/', to: '../static/' }]),
    new ExtractTextPlugin({ filename: 'css/app.css', allChunks: true }),
  ],
  module: {
    // noParse: [/.elm$/],
    loaders: [
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/, /Stylesheets\.elm$/],
        use: [
          'elm-hot-loader',
          'elm-webpack-loader?verbose=true&warn=true&debug=true'
        ]
      },
      {
        test: /Stylesheets\.elm$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: [
            'css-loader',
            'elm-css-webpack-loader'
          ]
        })
      },
      {
        test:     /\.js$/,
        exclude:  [/node_modules/],
        loader:   'babel-loader',
      },
      { test: /bootstrap-loader\/dist\/js\/umd\//, loader: 'imports-loader' },
      { test: /\.(woff2?|svg)$/, loader: 'url-loader?limit=10000' },
      { test: /\.(ttf|eot)$/, loader: 'file-loader' },
    ],
  }
}
