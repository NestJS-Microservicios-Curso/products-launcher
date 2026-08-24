#!/usr/bin/env bash

set -eu

readonly mongo_host="auth-db:27017"
readonly mongo_user="${MONGO_INITDB_ROOT_USERNAME:?MONGO_INITDB_ROOT_USERNAME is required}"
readonly mongo_password="${MONGO_INITDB_ROOT_PASSWORD:?MONGO_INITDB_ROOT_PASSWORD is required}"
readonly mongo_args=(
  --quiet
  --host "$mongo_host"
  --username "$mongo_user"
  --password "$mongo_password"
  --authenticationDatabase admin
)

replica_set_status() {
  mongosh "${mongo_args[@]}" --eval '
    try {
      const status = rs.status();
      quit(status.ok === 1 ? 0 : 1);
    } catch (error) {
      quit(2);
    }
  '
}

if replica_set_status; then
  :
else
  status=$?
  if [ "$status" -ne 2 ]; then
    exit "$status"
  fi

  mongosh "${mongo_args[@]}" --eval \
    'rs.initiate({_id: "rs0", members: [{_id: 0, host: "auth-db:27017"}]})'
fi

for attempt in $(seq 1 60); do
  if mongosh "${mongo_args[@]}" --eval \
    'quit(db.hello().isWritablePrimary === true ? 0 : 1)' >/dev/null; then
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for auth-db to become PRIMARY" >&2
exit 1
