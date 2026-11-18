{{- define "star.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "star.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{- define "star.podLabels" -}}
{{ include "star.selectorLabels" . }}
{{- with .component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
app.kubernetes.io/part-of: star
{{- end }}

{{- define "star.labels" -}}
{{ include "star.podLabels" . }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
helm.sh/chart: {{ include "star.chart" .root }}
{{- end }}

{{- define "star.string" -}}
{{- if and (kindIs "float64" .) (eq . (float64 (int64 .))) }}
{{- int64 . | toString }}
{{- else }}
{{- toString . }}
{{- end }}
{{- end }}

{{- define "star.origin" -}}
{{- $v := .Values }}
{{- if $v.publicOrigin }}
{{- trimSuffix "/" $v.publicOrigin }}
{{- else }}
{{- $default := ternary 443 80 (eq $v.scheme "https") }}
{{- if eq (int $v.port) $default }}
{{- printf "%s://%s" $v.scheme $v.domain }}
{{- else }}
{{- printf "%s://%s:%d" $v.scheme $v.domain (int $v.port) }}
{{- end }}
{{- end }}
{{- end }}

{{- define "star.hostOrigin" -}}
{{- $v := .Values }}
{{- if $v.publicOrigin }}
{{- trimSuffix "/" $v.publicOrigin }}
{{- else }}
{{- printf "%s://%s:%d" $v.scheme $v.domain (int $v.port) }}
{{- end }}
{{- end }}

{{- define "star.secretName" -}}
{{- .Values.secrets.existingSecret | default "star-env" }}
{{- end }}

{{- define "star.thirdPartyImage" -}}
{{- $ref := printf "%s:%s" .repository (include "star.string" .tag) }}
{{- with .digest }}
{{- $ref = printf "%s@%s" $ref . }}
{{- end }}
{{- $ref | quote }}
{{- end }}

{{- define "star.image" -}}
{{- $v := .root.Values.image }}
{{- $img := (.w | default dict).image | default dict }}
{{- $registry := $img.registry | default $v.registry }}
{{- $tag := $img.tag | default (get ($v.tags | default dict) .image) | default $v.tag }}
{{- $ref := printf "%s/%s:%s" $registry .image (include "star.string" $tag) }}
{{- with $img.digest | default (get ($v.digests | default dict) .image) }}
{{- $ref = printf "%s@%s" $ref . }}
{{- end }}
{{- $ref | quote }}
{{- end }}

{{- define "star.pullPolicy" -}}
{{- (((.w | default dict).image | default dict).pullPolicy) | default .root.Values.image.pullPolicy }}
{{- end }}

{{- define "star.pullSecrets" -}}
{{- with .Values.image.pullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "star.podSecurityContext" -}}
runAsNonRoot: true
{{- with .uid }}
runAsUser: {{ . }}
runAsGroup: {{ $.gid | default . }}
fsGroup: {{ $.gid | default . }}
fsGroupChangePolicy: OnRootMismatch
{{- end }}
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "star.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- end }}

{{- define "star.scheduling" -}}
{{- $w := .w | default dict }}
{{- with $w.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $w.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $w.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- $spread := list }}
{{- range $w.topologySpreadConstraints }}
{{- $c := deepCopy . }}
{{- if not (hasKey $c "labelSelector") }}
{{- $_ := set $c "labelSelector" (dict "matchLabels" (include "star.selectorLabels" $ | fromYaml)) }}
{{- end }}
{{- $spread = append $spread $c }}
{{- end }}
{{- with $spread }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "star.pvc" -}}
- metadata:
    name: data
  spec:
    accessModes:
      - ReadWriteOnce
    {{- with .storageClassName }}
    storageClassName: {{ . }}
    {{- end }}
    resources:
      requests:
        storage: {{ .size }}
{{- end }}

{{- define "star.vapidPair" -}}
{{- $der := genPrivateKey "ecdsa" | replace "-----BEGIN EC PRIVATE KEY-----" "" | replace "-----END EC PRIVATE KEY-----" "" | nospace | b64dec -}}
private: {{ substr 7 39 $der | b64enc | replace "+" "-" | replace "/" "_" | trimAll "=" }}
public: {{ substr 56 121 $der | b64enc | replace "+" "-" | replace "/" "_" | trimAll "=" }}
{{- end }}

{{- define "star.livekitMode" -}}
{{- if .Values.livekit.enabled }}bundled{{ else if .Values.livekit.external.url }}external{{ else if .Values.livekit.joined }}joined{{ else }}off{{ end }}
{{- end }}

{{- define "star.noGenerateKeys" -}}
{{- $keys := list }}
{{- $extra := .Values.secrets.extra | default dict }}
{{- if and (not .Values.postgres.enabled) (not (get $extra "STAR_POSTGRES_URL")) }}
{{- $keys = append $keys "STAR_POSTGRES_PASSWORD" }}
{{- end }}
{{- if not .Values.meilisearch.enabled }}
{{- $keys = append $keys "STAR_SEARCH_API_KEY" }}
{{- end }}
{{- if not .Values.seaweedfs.enabled }}
{{- $keys = append $keys "STAR_S3_SECRET_ACCESS_KEY" }}
{{- end }}
{{- if eq (include "star.livekitMode" .) "external" }}
{{- $keys = append $keys "STAR_LIVEKIT_API_SECRET" }}
{{- end }}
{{- toJson $keys }}
{{- end }}

{{- define "star.requiredSecretKeys" -}}
{{- $keys := list }}
{{- $extra := .Values.secrets.extra | default dict }}
{{- range $k, $_ := .Values.secrets.values }}
{{- if and (eq $k "STAR_POSTGRES_PASSWORD") (get $extra "STAR_POSTGRES_URL") }}
{{- else if and (hasPrefix "STAR_LIVEKIT_" $k) (has (include "star.livekitMode" $) (list "off" "joined")) }}
{{- else if and (eq $k "STAR_VALKEY_PASSWORD") (not $.Values.valkey.enabled) }}
{{- else if and (eq $k "STAR_NATS_AUTH_TOKEN") (not $.Values.nats.enabled) }}
{{- else if and (has $k (list "STAR_SETUP_TOKEN" "STAR_ACTIVITYPUB_SIGNING_KEY_BASE64")) (or $.Values.secrets.existingSecret (and (not $.Values.secrets.generate) (not (include "star.string" (get $.Values.secrets.values $k | default ""))))) }}
{{- else }}
{{- $keys = append $keys $k }}
{{- end }}
{{- end }}
{{- toJson $keys }}
{{- end }}

{{- define "star.resolveSecrets" -}}
{{- $v := .Values }}
{{- $existing := dict }}
{{- $found := lookup "v1" "Secret" .Release.Namespace (include "star.secretName" .) }}
{{- range $k, $val := ($found.data | default dict) }}
{{- $_ := set $existing $k (b64dec $val) }}
{{- end }}
{{- $out := dict }}
{{- if $v.secrets.existingSecret }}
{{- $out = $existing }}
{{- else }}
{{- $unfurlFound := lookup "v1" "Secret" .Release.Namespace "star-unfurl-env" }}
{{- range $k, $val := ($unfurlFound.data | default dict) }}
{{- $_ := set $existing $k (b64dec $val) }}
{{- end }}
{{- $noGenerate := include "star.noGenerateKeys" . | fromJsonArray }}
{{- $explicit := $v.secrets.values | default dict }}
{{- $vapidPublic := include "star.string" (get $explicit "STAR_VAPID_PUBLIC_KEY" | default "") }}
{{- $vapidPrivate := include "star.string" (get $explicit "STAR_VAPID_PRIVATE_KEY" | default "") }}
{{- if and $vapidPublic $vapidPrivate }}
{{- else if or $vapidPublic $vapidPrivate }}
{{- fail "secrets.values.STAR_VAPID_PUBLIC_KEY and secrets.values.STAR_VAPID_PRIVATE_KEY must be set together, or both left empty to generate a pair" }}
{{- else if and (get $existing "STAR_VAPID_PUBLIC_KEY") (get $existing "STAR_VAPID_PRIVATE_KEY") }}
{{- $vapidPublic = get $existing "STAR_VAPID_PUBLIC_KEY" }}
{{- $vapidPrivate = get $existing "STAR_VAPID_PRIVATE_KEY" }}
{{- else if $v.secrets.generate }}
{{- $pair := include "star.vapidPair" . | fromYaml }}
{{- $vapidPublic = $pair.public }}
{{- $vapidPrivate = $pair.private }}
{{- else }}
{{- fail "secrets.values.STAR_VAPID_PUBLIC_KEY and secrets.values.STAR_VAPID_PRIVATE_KEY are empty and secrets.generate is false" }}
{{- end }}
{{- $_ := set $out "STAR_VAPID_PUBLIC_KEY" $vapidPublic }}
{{- $_ := set $out "STAR_VAPID_PRIVATE_KEY" $vapidPrivate }}
{{- $required := include "star.requiredSecretKeys" . | fromJsonArray }}
{{- $outsideToken := include "star.string" (get $explicit "STAR_NATS_AUTH_TOKEN" | default "") }}
{{- if and $outsideToken (not $v.nats.enabled) }}
{{- $_ := set $out "STAR_NATS_AUTH_TOKEN" $outsideToken }}
{{- end }}
{{- range $k := $required }}
{{- if not (hasPrefix "STAR_VAPID_" $k) }}
{{- $given := include "star.string" (get $explicit $k | default "") }}
{{- if $given }}
{{- $_ := set $out $k $given }}
{{- else if has $k $noGenerate }}
{{- fail (printf "secrets.values.%s is required when the matching service is not bundled" $k) }}
{{- else if get $existing $k }}
{{- $_ := set $out $k (get $existing $k) }}
{{- else if $v.secrets.generate }}
{{- if eq $k "STAR_MEDIA_PROXY_UPLOAD_RELAY_SECRET_BASE64" }}
{{- $_ := set $out $k (randBytes 32) }}
{{- else if eq $k "STAR_ACTIVITYPUB_SIGNING_KEY_BASE64" }}
{{- $_ := set $out $k (genPrivateKey "rsa" | replace "-----BEGIN RSA PRIVATE KEY-----" "" | replace "-----END RSA PRIVATE KEY-----" "" | nospace) }}
{{- else }}
{{- $_ := set $out $k (randAlphaNum 64) }}
{{- end }}
{{- else }}
{{- fail (printf "secrets.values.%s is empty and secrets.generate is false" $k) }}
{{- end }}
{{- end }}
{{- end }}
{{- range $k, $val := $v.secrets.extra | default dict }}
{{- $s := include "star.string" ($val | default "") }}
{{- if $s }}
{{- $_ := set $out $k $s }}
{{- end }}
{{- end }}
{{- end }}
{{- toJson $out }}
{{- end }}

{{- define "star.secretData" -}}
{{- if not (hasKey .Values "starResolvedSecrets") }}
{{- $_ := set .Values "starResolvedSecrets" (include "star.resolveSecrets" . | fromJson) }}
{{- end }}
{{- toJson (get .Values "starResolvedSecrets") }}
{{- end }}

{{- define "star.secretEnv" -}}
- name: {{ .name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "star.secretName" .root }}
      key: {{ .key }}
{{- end }}

{{- define "star.instanceChecksum" -}}
{{- $parts := list (include "star.configData" .) (include "star.appProxyConfigData" .) (toJson .Values.secrets.values) (toJson (.Values.secrets.extra | default dict)) (include "star.string" .Values.image.revision) (include "star.secretData" .) }}
{{- join "\n" $parts | sha256sum }}
{{- end }}

{{- define "star.envList" -}}
{{- $w := .w | default dict }}
{{- $own := $w.env | default dict }}
{{- $base := .env | default list }}
{{- $names := list }}
{{- range $base }}
{{- $names = append $names .name }}
{{- end }}
{{- $out := list }}
{{- range $base }}
{{- if hasKey $own .name }}
{{- $val := get $own .name }}
{{- if not (kindIs "invalid" $val) }}
{{- $out = append $out (dict "name" .name "value" (include "star.string" $val)) }}
{{- end }}
{{- else }}
{{- $out = append $out . }}
{{- end }}
{{- end }}
{{- range $k := keys $own | sortAlpha }}
{{- $val := get $own $k }}
{{- if and (not (has $k $names)) (not (kindIs "invalid" $val)) }}
{{- $out = append $out (dict "name" $k "value" (include "star.string" $val)) }}
{{- end }}
{{- end }}
{{- $out = concat $out ($w.extraEnv | default list) }}
{{- with $out }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{- define "star.probes" -}}
{{- $own := (.w | default dict).probes | default dict }}
{{- range $probe := list "startup" "liveness" "readiness" }}
{{- $p := get ($.probes | default dict) $probe }}
{{- if hasKey $own $probe }}
{{- $p = get $own $probe }}
{{- end }}
{{- with $p }}
{{ $probe }}Probe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "star.waitFor" -}}
{{- with .waitFor }}
initContainers:
  - name: wait-for-dependencies
    image: {{ include "star.thirdPartyImage" $.root.Values.initImage }}
    imagePullPolicy: {{ $.root.Values.initImage.pullPolicy }}
    command:
      - sh
      - -c
      - {{ printf "for t in %s; do until nc -z -w 2 ${t%%:*} ${t##*:}; do echo waiting for $t; sleep 2; done; done" (join " " .) | quote }}
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
      limits:
        memory: 32Mi
    securityContext:
      runAsUser: 65532
      runAsGroup: 65532
      {{- include "star.containerSecurityContext" . | nindent 6 }}
{{- end }}
{{- end }}

{{- define "star.appWaitFor" -}}
{{- $out := list }}
{{- if and .usesNats .root.Values.nats.enabled }}
{{- $out = append $out "nats:4222" }}
{{- end }}
{{- if and .usesPostgres .root.Values.postgres.enabled }}
{{- $out = append $out "postgres:5432" }}
{{- end }}
{{- if and .usesS3 .root.Values.seaweedfs.enabled }}
{{- $out = append $out "seaweedfs:8333" }}
{{- end }}
{{- if and .usesKv .root.Values.valkey.enabled }}
{{- $out = append $out "valkey:6379" }}
{{- end }}
{{- if .usesSvc }}
{{- range $name := list "gifs" "messages" "snowflakes" "unfurl" "users" }}
{{- $svc := get $.root.Values.svc $name | default dict }}
{{- if gt (int (include "star.replicas" (dict "w" ($svc.router | default dict)))) 0 }}
{{- $out = append $out (printf "%s:8090" $name) }}
{{- end }}
{{- if gt (int (include "star.replicas" (dict "w" ($svc.shard | default dict)))) 0 }}
{{- $out = append $out (printf "%s-shard:8090" $name) }}
{{- end }}
{{- end }}
{{- end }}
{{- toJson $out }}
{{- end }}
