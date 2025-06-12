#!/bin/bash

URL="http://kambaniru.iixcp.rumahweb.net:19999/api/v1/data?chart=user.mysql_cpu_utilization"

curl -s "$URL" | jq -r '
  # Ambil posisi index label
  .labels as $labels |
  ($labels | index("time")) as $t |
  ($labels | index("user")) as $u |
  ($labels | index("system")) as $s |

  # Proses data
  .data[] |
  .[$t] as $ts |
  .[$u] as $user |
  .[$s] as $system |
  ($ts | tonumber | strftime("%Y-%m-%d %H:%M:%S")) + "\tUser: \($user)\tSystem: \($system)"
'
