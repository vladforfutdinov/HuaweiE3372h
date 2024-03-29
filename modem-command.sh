#!/bin/bash

BASE_URL=http://192.168.8.1
TOKEN_PATH=/api/webserver/SesTokInfo
CONTROL_PATH=/api/device/control
SIGNAL_PATH=/api/device/signal

REBOOT_CONTROL='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><request><Control>1</Control></request>'

TOKEN_OUTPUT=
SESINFO_DATA=
TOKEN_DATA=

DO_REBOOT=
DO_SIGNAL=
INTERVAL=0

getToken()
{
  TOKEN_OUTPUT=$(curl --silent ${BASE_URL}${TOKEN_PATH})
  SESINFO_DATA=$(sed -n 's:.*<SesInfo>\(.*\)</SesInfo>.*:\1:p' <<< $TOKEN_OUTPUT)
  TOKEN_DATA=$(sed -n 's:.*<TokInfo>\(.*\)</TokInfo>.*:\1:p' <<< $TOKEN_OUTPUT)
}

getSignal()
{
  getToken

  local REQUEST_STRING="curl --silent ${BASE_URL}${SIGNAL_PATH} --header 'Cookie: ${SESINFO_DATA}'"
  local OUTPUT=`eval "$REQUEST_STRING"`

  # local RSSI=`sed -n 's:.*<rssi>\(.*\)</rssi>.*:\1:p' <<< $OUTPUT`
  local RSRP=`sed -n 's:.*<rsrp>\(.*\)</rsrp>.*:\1:p' <<< $OUTPUT`
  local RSRQ=`sed -n 's:.*<rsrq>\(.*\)</rsrq>.*:\1:p' <<< $OUTPUT`
  local SINR=`sed -n 's:.*<sinr>\(.*\)</sinr>.*:\1:p' <<< $OUTPUT`

  # local RSSI_SATITIZED=$(sanitize ${RSSI})
  local RSRP_SATITIZED=$(sanitize ${RSRP})
  local RSRQ_SATITIZED=$(sanitize ${RSRQ})
  local SINR_SATITIZED=$(sanitize ${SINR})

  # echo "RSSI:${RSSI_SATITIZED} | RSRP:${RSRP_SATITIZED} | RSRQ:${RSRQ_SATITIZED} | SINR:${SINR_SATITIZED}"
  echo "RSRP:${RSRP_SATITIZED} | RSRQ:${RSRQ_SATITIZED} | SINR:${SINR_SATITIZED}"
}

sanitize()
{
  echo `sed 's/&gt;/>/g;s/&lt;/</g' <<< $1`
}

reboot()
{
  echo -ne "Reboot: "

  getToken

  local REQUEST_STRING="curl --silent ${BASE_URL}${CONTROL_PATH} --header 'Cookie: ${SESINFO_DATA}' --header '__RequestVerificationToken: $TOKEN_DATA' --data-raw '${REBOOT_CONTROL}'"
  local OUTPUT=`eval "$REQUEST_STRING"`
  local OUTPUT_MESSAGE=`sed -n 's:.*<response>\(.*\)</response>.*:\1:p' <<< $OUTPUT`

  echo "${OUTPUT_MESSAGE}"
}

while getopts 'rsi:' OPTION; do
  case $OPTION in
      r) DO_REBOOT=1;;
      s) DO_SIGNAL=1;;
      i) INTERVAL=${OPTARG};;
  esac
done

if [[ -n "$DO_REBOOT" ]]; then
  if [[ "$INTERVAL" != 0 ]]; then
    echo "Reboot cannot be started with interval"
    exit 0
  fi

 reboot
fi

if [[ -n "$DO_SIGNAL" ]]; then
  echo "Signal"
  
  if [[ "$INTERVAL" != 0 ]]; then
    while true
    do
      CURRENT_TIME=$(date +"%T")
      RESULT=$(getSignal)

      echo "${CURRENT_TIME} - ${RESULT}"
      sleep $INTERVAL;
    done
  fi

  getSignal
fi
