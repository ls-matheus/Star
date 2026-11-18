#!/usr/bin/env sh

# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

is_positive_int() {
	case "${1:-}" in
	'' | 0* | *[!0-9]*) return 1 ;;
	*) [ "$1" -gt 0 ] ;;
	esac
}

cpu_quota_count() {
	cpu_quota=""
	cpu_period=""
	if [ -r /sys/fs/cgroup/cpu.max ]; then
		read -r cpu_quota cpu_period </sys/fs/cgroup/cpu.max || true
	else
		for cgroup_dir in /sys/fs/cgroup/cpu /sys/fs/cgroup/cpu,cpuacct; do
			if [ -r "$cgroup_dir/cpu.cfs_quota_us" ] && [ -r "$cgroup_dir/cpu.cfs_period_us" ]; then
				read -r cpu_quota <"$cgroup_dir/cpu.cfs_quota_us" || true
				read -r cpu_period <"$cgroup_dir/cpu.cfs_period_us" || true
				break
			fi
		done
	fi
	if is_positive_int "$cpu_quota" && is_positive_int "$cpu_period"; then
		echo "$(((cpu_quota + cpu_period - 1) / cpu_period))"
	fi
}

available_cpu_count() {
	cpu_count="$(nproc 2>/dev/null || echo 1)"
	is_positive_int "$cpu_count" || cpu_count=1
	quota_count="$(cpu_quota_count)"
	if is_positive_int "$quota_count" && [ "$quota_count" -lt "$cpu_count" ]; then
		cpu_count="$quota_count"
	fi
	echo "$cpu_count"
}

clamp_int() {
	value="$1"
	min="$2"
	max="$3"
	if [ "$value" -lt "$min" ]; then
		value="$min"
	fi
	if [ "$value" -gt "$max" ]; then
		value="$max"
	fi
	echo "$value"
}

is_positive_int "${STAR_ERLANG_SCHEDULERS_MIN:-}" || STAR_ERLANG_SCHEDULERS_MIN=2
is_positive_int "${STAR_ERLANG_SCHEDULERS_MAX:-}" || STAR_ERLANG_SCHEDULERS_MAX=16
: "${STAR_ERLANG_NODE_NAME:=star_gateway@127.0.0.1}"
: "${STAR_ERLANG_DIST_PORT:=8081}"
node_name_file=/opt/star_gateway/node_name

if [ -n "${STAR_ERLANG_NODE_NAME_PREFIX:-}" ]; then
	case "$STAR_ERLANG_NODE_NAME_PREFIX" in
	*[!A-Za-z0-9_]*)
		echo 'STAR_ERLANG_NODE_NAME_PREFIX may only contain letters, digits and underscores.' >&2
		exit 1
		;;
	esac
	node_nonce="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
	STAR_ERLANG_NODE_NAME="${STAR_ERLANG_NODE_NAME_PREFIX}_${node_nonce}@${STAR_ERLANG_NODE_NAME#*@}"
	printf '%s\n' "$STAR_ERLANG_NODE_NAME" >"$node_name_file"
else
	rm -f "$node_name_file"
fi

case "${STAR_ERLANG_COOKIE_FILE:-}" in
*[![:space:]]*)
	case "${STAR_ERLANG_COOKIE:-}" in
	*[![:space:]]*)
		echo 'STAR_ERLANG_COOKIE and STAR_ERLANG_COOKIE_FILE are both set, set only one.' >&2
		exit 1
		;;
	esac
	if ! STAR_ERLANG_COOKIE="$(cat -- "$STAR_ERLANG_COOKIE_FILE")"; then
		echo "STAR_ERLANG_COOKIE_FILE could not read $STAR_ERLANG_COOKIE_FILE." >&2
		exit 1
	fi
	;;
esac

if [ -z "${STAR_ERLANG_COOKIE:-}" ]; then
	echo 'STAR_ERLANG_COOKIE is required.' >&2
	exit 1
fi

if ! is_positive_int "${STAR_ERLANG_SCHEDULERS:-}"; then
	STAR_ERLANG_SCHEDULERS="$(clamp_int "$(available_cpu_count)" "$STAR_ERLANG_SCHEDULERS_MIN" "$STAR_ERLANG_SCHEDULERS_MAX")"
fi

if ! is_positive_int "${STAR_ERLANG_DIRTY_CPU_SCHEDULERS:-}"; then
	STAR_ERLANG_DIRTY_CPU_SCHEDULERS="$(clamp_int "$((STAR_ERLANG_SCHEDULERS / 2))" 1 "$STAR_ERLANG_SCHEDULERS")"
fi

if ! is_positive_int "${STAR_ERLANG_DIRTY_IO_SCHEDULERS:-}"; then
	STAR_ERLANG_DIRTY_IO_SCHEDULERS="$(clamp_int "$STAR_ERLANG_SCHEDULERS" 2 4)"
fi

export STAR_ERLANG_NODE_NAME
export STAR_ERLANG_COOKIE
export STAR_ERLANG_DIST_PORT
export STAR_ERLANG_SCHEDULERS
export STAR_ERLANG_DIRTY_CPU_SCHEDULERS
export STAR_ERLANG_DIRTY_IO_SCHEDULERS
export RELX_REPLACE_OS_VARS="${RELX_REPLACE_OS_VARS:-true}"

exec /opt/star_gateway/bin/star_gateway foreground
