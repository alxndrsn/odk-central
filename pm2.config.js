module.exports = {
  apps:  [{
    script: './demo-double-logging.js',
    out_file: '/proc/1/fd/1',
    error_file: '/proc/1/fd/2',
  }]
};

