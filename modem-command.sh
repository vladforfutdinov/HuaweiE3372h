source ~/.profile

BASE_DIR=$(dirname "$0")
cd "$BASE_DIR"

BASE_URL=http://192.168.8.1
TOKEN_PATH=/api/webserver/SesTokInfo
CONTROL_PATH=/api/device/control
SIGNAL_PATH=/api/device/signal

REBOOT_CONTROL='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><request><Control>1</Control></request>'

TOKEN_OUTPUT=$(curl --silent ${BASE_URL}${TOKEN_PATH})
SESINFO_DATA=$(sed -n 's:.*<SesInfo>\(.*\)</SesInfo>.*:\1:p' <<< $TOKEN_OUTPUT)
TOKEN_DATA=$(sed -n 's:.*<TokInfo>\(.*\)</TokInfo>.*:\1:p' <<< $TOKEN_OUTPUT)

for i in "$@"
do
key="$1"

case $key in
    -r|--reboot)
      REQUEST_STRING="curl --silent ${BASE_URL}${CONTROL_PATH} --header 'Cookie: ${SESINFO_DATA}' --header '__RequestVerificationToken: $TOKEN_DATA' --data-raw '${REBOOT_CONTROL}'"
      
      eval "$REQUEST_STRING"
    ;;
    -s|--signal)
      REQUEST_STRING="curl --silent ${BASE_URL}${SIGNAL_PATH} --header 'Cookie: ${SESINFO_DATA}'"
      SIGNAL_RESULT=`eval "$REQUEST_STRING"`

      RSSI=`sed -n 's:.*<rssi>\(.*\)</rssi>.*:\1:p' <<< $SIGNAL_RESULT`
      RSRP=`sed -n 's:.*<rsrp>\(.*\)</rsrp>.*:\1:p' <<< $SIGNAL_RESULT`
      RSRQ=`sed -n 's:.*<rsrq>\(.*\)</rsrq>.*:\1:p' <<< $SIGNAL_RESULT`
      SINR=`sed -n 's:.*<sinr>\(.*\)</sinr>.*:\1:p' <<< $SIGNAL_RESULT`

      echo "RSRQ: ${RSRQ}\nRSRP: ${RSRP}\nRSSI: ${RSSI}\nSINR: ${SINR}"
    ;;
esac
done
