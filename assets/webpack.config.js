const CopyWebpackPlugin = require('copy-webpack-plugin')
const path = require('path')
const ExtractTextPlugin = require('extract-text-webpack-plugin')

const elmSource = path.resolve(__dirname, './elm')

module.exports = {
  entry: ['bootstrap-loader', './elm/Tasker.elm', './js/app.js'],
  output: {
    path: path.resolve(__dirname, '../priv/static'),
    filename: 'js/app.js',
  },
  plugins: [
    new CopyWebpackPlugin([{ from: './static/', to: '../static/' }]),
    new ExtractTextPlugin({ filename: 'css/app.css', allChunks: true }),
  ],
  resolve: {
    extensions: ['.js', '.elm']
  },
  module: {
    noParse: [/.elm$/],
    loaders: [
      {
        test:     /\.js$/,
        exclude:  [/node_modules/],
        loader:   'babel-loader',
        query: { presets: ['env'] },
      },
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader:  'elm-hot!elm-webpack?verbose=true&warn=true&debug=true&cwd=' + elmSource,
      },
      { test: /bootstrap[\/\\]dist[\/\\]js[\/\\]umd[\/\\]/, loader: 'imports-loader' },
      { test: /\.(woff2?|svg)$/, loader: 'url-loader?limit=10000' },
      { test: /\.(ttf|eot)$/, loader: 'file-loader' },
    ],
  }
}
