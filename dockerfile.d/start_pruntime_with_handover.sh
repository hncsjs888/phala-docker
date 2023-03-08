#!/usr/bin/env bash

set -e

if [ "$SGX" -eq 1 ] && [ "$SKIP_AESMD" -eq 0 ]; then
  echo "Starting AESMD"

  /bin/mkdir -p /var/run/aesmd/
  /bin/chown -R aesmd:aesmd /var/run/aesmd/
  /bin/chmod 0755 /var/run/aesmd/
  /bin/chown -R aesmd:aesmd /var/opt/aesmd/
  /bin/chmod 0750 /var/opt/aesmd/

  LD_LIBRARY_PATH=/opt/intel/sgx-aesm-service/aesm /opt/intel/sgx-aesm-service/aesm/aesm_service --no-daemon &

  if [ ! "${SLEEP_BEFORE_START:=0}" -eq 0 ]
  then
    echo "Waiting for device. Sleep ${SLEEP_BEFORE_START}s"

    sleep "${SLEEP_BEFORE_START}"
  fi
fi

GRAMINE_SGX_GET_TOKEN_BIN=${GRAMINE_SGX_GET_TOKEN_BIN:-"/usr/bin/gramine-sgx-get-token"}
if [[ ! -f "/opt/pruntime/releases/current/pruntime.token" ]]; then
  echo "Generating token"
  $GRAMINE_SGX_GET_TOKEN_BIN --sig "/opt/pruntime/releases/current/pruntime.sig" --output "/opt/pruntime/releases/current/pruntime.token"
fi

cd /opt/pruntime && deno run --allow-all pruntime_handover.ts
if [ $? -eq 0 ]
then
  cd /opt/pruntime/releases/current && SKIP_AESMD=1 ./start_pruntime.sh
else
  exit 1
fi
