const HtmlWebpackPlugin = require('html-webpack-plugin');

// Existing config...

plugins: [
  new HtmlWebpackPlugin({
    template: './public/index.html', // Path to your HTML template
    filename: 'index.html', // Output file name
  }),
]

// Existing config...
