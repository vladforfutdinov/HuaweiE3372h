const fetch = require('node-fetch');
const { Request } = fetch;
const xml2js = require('xml2js');
const xmlBuilder = new xml2js.Builder();

const BASE_URL = 'http://192.168.8.1';
const TOKEN_PATH = '/api/webserver/SesTokInfo';

async function getOptions() {
  const { response } = await getXmlData(BASE_URL + TOKEN_PATH, false);
  const { SesInfo, TokInfo } = response;
  const [cookie] = SesInfo;
  const [token] = TokInfo;

  return {
    headers: {
      cookie,
      __RequestVerificationToken: token,
      'Content-Type': 'application/xml',
    },
  };
}

async function getXmlData(url, requestOptions = true) {
  const opts = requestOptions ? await getOptions() : {};
  const request = new Request(url, opts, opts);

  const resp = await fetch(request)
    .then((res) => res.text())
    .catch(showError);

  return xml2js
    .parseStringPromise(resp)
    .then((result) => result)
    .catch(showError);
}

async function sendXmlData(url, body) {
  const opts = await getOptions();

  const xmlString = xmlBuilder.buildObject(body);
  const request = new Request(url, {
    method: 'POST',
    body: xmlString,
    ...opts,
  });

  const resp = await fetch(request)
    .then((res) => res.text())
    .catch(showError);

  return xml2js
    .parseStringPromise(resp)
    .then((result) => result)
    .catch(showError);
}

function showError(e) {
  console.log('error', e);
}

module.exports = { getXmlData, sendXmlData };
