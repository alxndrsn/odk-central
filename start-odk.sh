echo "starting server."
echo "pm2 version: $(pm2-runtime --version)"
pm2-runtime ./pm2.config.js
