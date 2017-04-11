const CopyWebpackPlugin = require('copy-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const webpack = require('webpack')
const path = require('path')

console.log( 'WEBPACK GO!');

module.exports = {
  devtool: 'source-map',
  entry: [
    './elm/Stylesheets.elm',
    './elm/Tasker.elm',
    './js/app.js'
  ],
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
    new ExtractTextPlugin({ filename: 'app.css', allChunks: true }),
  ],
  module: {
    rules: [
      {
        test: /\.elm$/,
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
        test:    /\.js$/,
        exclude: [/node_modules/],
        loader:  'babel-loader',
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({ use: 'css-loader' }),
      },
      {
        test: /\.(png|jpg|gif)$/,
        loader: 'url-loader',
        options: {
          limit: 10000
        },
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader',
        options: {
          limit: 10000,
          mimetype: 'application/font-woff'
        },
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: "file-loader"
      },
    ],
  }
}
