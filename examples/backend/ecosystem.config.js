// PM2 process definition. restart.sh uses this file if it's present in the
// release, so PM2 always runs the app the same way.
module.exports = {
  apps: [
    {
      name: "example-backend",
      script: "server.js",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },
    },
  ],
};
