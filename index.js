const argv = require('minimist')(process.argv.slice(2));
const { _, ...args } = argv;
const { reboot, status } = args;

const { getXmlData, sendXmlData } = require('./utils');

const BASE_URL = 'http://192.168.8.1';
const CONTROL_PATH = '/api/device/control';
const STATUS_PATH = '/api/monitoring/status';
const SIGNAL_PATH = '/api/device/signal';

const rebootCommand = { request: { Control: 1 } };

const signalKeys = ['rsrq', 'rsrp', 'rssi', 'sinr'];

(async () => {
  if (reboot) {
    await sendReboot();
  }

  if (status) {
    getStatus();
  }

  async function sendReboot() {
    const { response } = await sendXmlData(
      BASE_URL + CONTROL_PATH,
      rebootCommand
    );

    console.log('Modem response: ', response);
  }

  async function getStatus() {
    const signal = await getInfo(SIGNAL_PATH);
    const status = await getInfo(STATUS_PATH);
    console.log(`Modem status:${JSON.stringify(status, null, 2).replace(/[\"{}\[\]]/g, '')}`);

    const data = Object.keys(signal).reduce(
      (acc, key) => ({
        ...acc,
        ...(signalKeys.includes(key)
          ? { [key.toUpperCase()]: signal[key][0] }
          : {}),
      }),
      {}
    );
    const dataString = JSON.stringify(data, null, 2).replace(/[\"{}]/g, '');

    console.log(`Modem signal:${dataString}`);
  }

  async function getInfo(path) {
    const { response } = await getXmlData(BASE_URL + path);

    return response;
  }
})();
