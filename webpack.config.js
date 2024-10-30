const path = require('path'); // Import path module for absolute paths

var config = {
  mode: 'development', // Set mode to development or production
  entry: './src/index.js', // Entry point for the application

  // Output configuration (output.path must be absolute)
  output: {
    path: path.resolve(__dirname, 'public'), // Using an absolute path for the output directory
    filename: 'bundle.js', // Change this to a JavaScript file
  },
  
  // DevServer configuration
  devServer: {
    client: {
      logging: 'info', // Can be 'none', 'error', 'warn', or 'info'
      overlay: true // Shows error messages in the browser overlay
    },
    port: 8888, // Specify the port
    liveReload: true, // Enable live reloading
    static: {
      directory: path.resolve(__dirname, 'public'), // Serve files from the public directory
    },
  },

  // Module configuration with rules (previously loaders)
  module: {
    rules: [
      {
        test: /\.jsx?$/, // Regex to match .js or .jsx files
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader', // Use the correct loader name
          options: {
            presets: ['@babel/preset-env', '@babel/preset-react'], // Updated Babel presets
          },
        },
      },
    ],
  },

  // Specify the devtool for better debugging
  devtool: 'cheap-module-source-map', // Use a more appropriate devtool setting
};

module.exports = config;
