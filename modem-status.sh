source ~/.profile

NODE_MODULES_DIR=node_modules
BASE_DIR=$(dirname "$0")

cd "$BASE_DIR"

nvm use 12
if [ ! -d "$NODE_MODULES_DIR" ]; then
  npm i
fi

node index.js --status