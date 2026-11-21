// SPDX-License-Identifier: AGPL-3.0-or-later

package stack

import (
	"maps"
	"slices"
	"strconv"
	"strings"
)

type Hardware struct {
	MemoryBytes uint64
	CPUs        int
}

const (
	mib              = 1 << 20
	smallHostBytes   = 7 << 30
	defaultWriterMiB = 7168
)

func Sizing(hw Hardware, memory bool, fixed map[string]string) map[string]string {
	out := map[string]string{}
	if hw.CPUs <= 0 {
		return out
	}
	get := func(k string) string {
		if v := strings.TrimSpace(fixed[k]); v != "" {
			return v
		}
		return out[k]
	}
	num := func(k string, fallback int) int {
		if n, err := strconv.Atoi(get(k)); err == nil && n > 0 {
			return n
		}
		return fallback
	}
	size := func(k string, fallback int) int {
		if n := parseMiB(get(k)); n > 0 {
			return n
		}
		return fallback
	}

	c := hw.CPUs
	small := min(c, clamp((c+3)/4, 2, 4))
	wide := min(c, clamp((c+1)/2, 2, 8))
	setInt(out, "STAR_TOKIO_WORKER_THREADS", small)
	setInt(out, "STAR_MEDIA_PROXY_TOKIO_WORKER_THREADS", wide)
	setInt(out, RustWorkerThreadsVar, wide)
	setInt(out, "STAR_MALLOC_ARENA_MAX", max(2, small))
	embedded := embeddedWorker(hw, fixed)
	kv := kvPostgres(fixed)
	if embedded {
		setInt(out, "STAR_API_POSTGRES_MAX_CONNECTIONS", clamp(3*c, 4, 25))
	} else {
		setInt(out, "STAR_API_POSTGRES_MAX_CONNECTIONS", clamp(2*c, 4, 25))
	}
	if kv {
		setInt(out, KVPoolVar, num("STAR_API_POSTGRES_MAX_CONNECTIONS", 25))
	}
	setInt(out, "STAR_WORKER_POSTGRES_MAX_CONNECTIONS", clamp(c, 2, 25))
	setInt(out, "STAR_USERS_POSTGRES_MAX_CONNECTIONS", clamp(c, 2, 20))
	setInt(out, "STAR_MESSAGES_POSTGRES_MAX_CONNECTIONS", clamp(c, 2, 20))
	clients := num("STAR_API_POSTGRES_MAX_CONNECTIONS", 25) +
		num("STAR_USERS_POSTGRES_MAX_CONNECTIONS", 20) + num("STAR_MESSAGES_POSTGRES_MAX_CONNECTIONS", 20)
	workers := 0
	if !embedded {
		workers = num(WorkerReplicasVar, 1)
		clients += workers * num("STAR_WORKER_POSTGRES_MAX_CONNECTIONS", 25)
	}
	if kv {
		clients += (1 + workers) * (num(KVPoolVar, 25) + 1)
	}
	setInt(out, "STAR_POSTGRES_SERVER_MAX_CONNECTIONS", clients+10)
	setInt(out, "STAR_POSTGRES_AUTOVACUUM_MAX_WORKERS", clamp(c, 1, 3))
	gather := 0
	if c > 2 {
		gather = min(2, c/4)
	}
	setInt(out, "STAR_POSTGRES_MAX_PARALLEL_WORKERS_PER_GATHER", gather)
	setInt(out, "STAR_POSTGRES_MAX_PARALLEL_WORKERS", min(8, c))
	setInt(out, "STAR_MEILISEARCH_MAX_INDEXING_THREADS", clamp(c/4, 1, 4))

	if !memory || hw.MemoryBytes == 0 {
		return out
	}
	total := int(hw.MemoryBytes / mib)
	m := max(1024, (total-max(256, total/10))&^255)
	share := func(k string, percent, lo, hi int) int {
		v := clamp(m*percent/100, lo, hi)
		out[k] = strconv.Itoa(v) + "mb"
		return size(k, v)
	}
	reserve := func(k string, limit int) {
		out[k] = strconv.Itoa(limit*2/5) + "mb"
	}

	reserve("STAR_API_MEMORY_RESERVATION", share("STAR_API_MEMORY_LIMIT", 14, 512, 2560))
	reserve("STAR_WORKER_MEMORY_RESERVATION", share("STAR_WORKER_MEMORY_LIMIT", 12, 448, 2560))
	reserve("STAR_GATEWAY_MEMORY_RESERVATION", share("STAR_GATEWAY_MEMORY_LIMIT", 22, 512, 4096))
	share("STAR_CADDY_MEMORY_LIMIT", 8, 384, 2048)
	if hw.MemoryBytes < smallHostBytes {
		out["STAR_EDGE_PROTOCOLS"] = "h1 h2"
	}

	media := share("STAR_MEDIA_PROXY_MEMORY_LIMIT", 8, 320, 1024)
	setBytes(out, "STAR_MEDIA_PROXY_TRANSFORM_CACHE_BYTES", media/8)
	setBytes(out, "STAR_MEDIA_PROXY_UPLOAD_RELAY_BUFFERED_RETRY_TOTAL_BYTES", media/4)
	gifsCache := min(clamp(m/64, 64, 128), size("STAR_GIFS_MEMORY_LIMIT", 256)/2)
	setBytes(out, "STAR_GIFS_SHARD_CACHE_MAX_BYTES", gifsCache)
	out[RustMemoryLimitVar] = strconv.Itoa(clamp(m*6/100, 384, 1536)+gifsCache) + "mb"

	out["STAR_LIVEKIT_GOMEMLIMIT"] = strconv.Itoa(share("STAR_LIVEKIT_MEMORY_LIMIT", 6, 320, 2048)*85/100) + "MiB"
	out["STAR_NATS_GOMEMLIMIT"] = strconv.Itoa(share("STAR_NATS_MEMORY_LIMIT", 3, 192, 1024)*4/5) + "MiB"
	seaweed := share("STAR_SEAWEEDFS_MEMORY_LIMIT", 8, 768, 2048)
	out["STAR_SEAWEEDFS_GOMEMLIMIT"] = strconv.Itoa(seaweed*85/100) + "MiB"
	setInt(out, "STAR_SEAWEEDFS_S3_CONCURRENT_UPLOADS", clamp(seaweed/384, 2, 8))
	out["STAR_MEILISEARCH_MAX_INDEXING_MEMORY"] = strconv.Itoa(share("STAR_MEILISEARCH_MEMORY_LIMIT", 15, 512, 4096)/3) + "mb"

	out["STAR_VALKEY_MEMORY_LIMIT"] = strconv.Itoa(clamp(m*45/1000+32, 224, 1568)) + "mb"
	valkey := size("STAR_VALKEY_MEMORY_LIMIT", 256)
	maxmemory := (valkey - 32) * 2 / 3
	out["STAR_VALKEY_MAXMEMORY"] = strconv.Itoa(maxmemory) + "mb"

	pg := share("STAR_POSTGRES_MEMORY_LIMIT", 22, 448, 16384)
	if kv {
		out["STAR_POSTGRES_MEMORY_LIMIT"] = strconv.Itoa(clamp(m*22/100, 448, 16384)+valkey) + "mb"
		pg = size("STAR_POSTGRES_MEMORY_LIMIT", pg)
		setBytes(out, KVMaxBytesVar, size("STAR_VALKEY_MAXMEMORY", maxmemory)*kvRowOverhead)
	}
	reserve("STAR_POSTGRES_MEMORY_RESERVATION", pg)
	out["STAR_POSTGRES_SHARED_BUFFERS"] = strconv.Itoa(clamp(pg/4, 64, 4096)&^15) + "MB"
	buffers := size("STAR_POSTGRES_SHARED_BUFFERS", 512)
	out["STAR_POSTGRES_EFFECTIVE_CACHE_SIZE"] = strconv.Itoa(max(128, pg-buffers-64*c)) + "MB"
	work := clamp((pg-buffers)/(3*num("STAR_POSTGRES_SERVER_MAX_CONNECTIONS", 150)), 2, 32)
	out["STAR_POSTGRES_WORK_MEM"] = strconv.Itoa(work) + "MB"
	out["STAR_POSTGRES_MAINTENANCE_WORK_MEM"] = strconv.Itoa(clamp(pg/16, 32, 1024)) + "MB"
	out["STAR_POSTGRES_AUTOVACUUM_WORK_MEM"] = strconv.Itoa(clamp(pg/32, 16, 512)) + "MB"
	maintenance := size("STAR_POSTGRES_MAINTENANCE_WORK_MEM", 256)
	out["STAR_POSTGRES_SHM_SIZE"] = strconv.Itoa(64+maintenance+2*num("STAR_POSTGRES_MAX_PARALLEL_WORKERS_PER_GATHER", 0)*work) + "mb"
	if m < defaultWriterMiB {
		out["STAR_POSTGRES_BGWRITER_DELAY"] = "200ms"
		out["STAR_POSTGRES_BGWRITER_LRU_MAXPAGES"] = "100"
	}
	return out
}

const EmbeddedWorkerVar = "STAR_API_EMBEDDED_WORKER"

const (
	RustWorkerThreadsVar = "STAR_RUST_SERVER_TOKIO_WORKER_THREADS"
	RustMemoryLimitVar   = "STAR_RUST_MEMORY_LIMIT"
	KVPoolVar            = "STAR_KV_POSTGRES_MAX_CONNECTIONS"
	KVMaxBytesVar        = "STAR_KV_POSTGRES_MAX_BYTES"
	kvRowOverhead        = 4
)

func kvPostgres(fixed map[string]string) bool {
	return strings.TrimSpace(fixed[KVModeVar]) == "postgres"
}

const SettingsLoadedVar = "STAR_SETTINGS_LOADED"

func embeddedWorker(hw Hardware, fixed map[string]string) bool {
	return strings.ToLower(strings.TrimSpace(fixed[EmbeddedWorkerVar])) == "true"
}

func FoldWorker(hw Hardware, env, fixed map[string]string) map[string]string {
	if !embeddedWorker(hw, fixed) {
		return nil
	}
	out := map[string]string{EmbeddedWorkerVar: "true", "STAR_WORKER_REPLICAS": "0"}
	size := func(k string) int {
		if n := parseMiB(fixed[k]); n > 0 {
			return n
		}
		return parseMiB(env[k])
	}
	for api, worker := range map[string]string{
		"STAR_API_MEMORY_LIMIT":       "STAR_WORKER_MEMORY_LIMIT",
		"STAR_API_MEMORY_RESERVATION": "STAR_WORKER_MEMORY_RESERVATION",
	} {
		if a, w := size(api), size(worker); a > 0 && w > 0 {
			out[api] = strconv.Itoa(a+w/2) + "mb"
		}
	}
	return out
}

func SizingKeys() []string {
	return slices.Sorted(maps.Keys(Sizing(Hardware{MemoryBytes: 4 << 30, CPUs: 2}, true, map[string]string{KVModeVar: "postgres"})))
}

func clamp(v, lo, hi int) int { return max(lo, min(hi, v)) }

func setInt(out map[string]string, k string, v int) { out[k] = strconv.Itoa(v) }

func setBytes(out map[string]string, k string, mebibytes int) {
	out[k] = strconv.FormatInt(int64(mebibytes)*mib, 10)
}

func parseMiB(s string) int {
	s = strings.ToLower(strings.TrimSpace(s))
	i := strings.IndexFunc(s, func(r rune) bool { return (r < '0' || r > '9') && r != '.' })
	if i == 0 {
		return 0
	}
	digits, unit := s, ""
	if i > 0 {
		digits, unit = s[:i], strings.TrimSpace(s[i:])
	}
	n, err := strconv.ParseFloat(digits, 64)
	if err != nil {
		return 0
	}
	switch strings.TrimSuffix(strings.TrimSuffix(unit, "b"), "i") {
	case "":
		return int(n / mib)
	case "k":
		return int(n / 1024)
	case "m":
		return int(n)
	case "g":
		return int(n * 1024)
	}
	return 0
}
