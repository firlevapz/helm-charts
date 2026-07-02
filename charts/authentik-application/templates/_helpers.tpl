{{/*
Name / fullname / labels
*/}}
{{- define "authentik-application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "authentik-application.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "authentik-application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "authentik-application.labels" -}}
helm.sh/chart: {{ include "authentik-application.chart" . }}
app.kubernetes.io/name: {{ include "authentik-application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Common env (API URL, token, and the application fields) shared by both Jobs.
*/}}
{{- define "authentik-application.env" -}}
- name: AUTHENTIK_URL
  value: {{ .Values.authentik.url | quote }}
- name: AUTHENTIK_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.authentik.tokenSecret.name | quote }}
      key: {{ .Values.authentik.tokenSecret.key | quote }}
- name: APP_SLUG
  value: {{ required "application.slug is required" .Values.application.slug | quote }}
- name: APP_NAME
  value: {{ required "application.name is required" .Values.application.name | quote }}
- name: APP_LAUNCH_URL
  value: {{ required "application.launchUrl is required" .Values.application.launchUrl | quote }}
- name: APP_GROUP
  value: {{ .Values.application.group | quote }}
- name: APP_DESCRIPTION
  value: {{ .Values.application.metaDescription | quote }}
- name: APP_PUBLISHER
  value: {{ .Values.application.metaPublisher | quote }}
- name: APP_OPEN_IN_NEW_TAB
  value: {{ ternary "true" "false" .Values.application.openInNewTab | quote }}
- name: APP_POLICY_ENGINE_MODE
  value: {{ .Values.application.policyEngineMode | quote }}
{{- end }}

{{/*
Upsert script — idempotent create-or-update of the Application by slug. POSIX sh +
curl; writes only under /tmp (mounted emptyDir) so the root FS stays read-only.
*/}}
{{- define "authentik-application.upsertScript" -}}
set -eu
API="${AUTHENTIK_URL%/}/api/v3/core/applications"
AUTH="Authorization: Bearer ${AUTHENTIK_TOKEN}"

# JSON body for create/update. Inputs are controlled (slug/name/url), no escaping needed.
body() {
  cat <<JSON
{
  "slug": "${APP_SLUG}",
  "name": "${APP_NAME}",
  "provider": null,
  "meta_launch_url": "${APP_LAUNCH_URL}",
  "meta_description": "${APP_DESCRIPTION}",
  "meta_publisher": "${APP_PUBLISHER}",
  "group": "${APP_GROUP}",
  "open_in_new_tab": ${APP_OPEN_IN_NEW_TAB},
  "policy_engine_mode": "${APP_POLICY_ENGINE_MODE}"
}
JSON
}

code=$(curl -sS -o /tmp/get.json -w '%{http_code}' -H "$AUTH" "$API/${APP_SLUG}/")
if [ "$code" = "200" ]; then
  echo "Application ${APP_SLUG} exists - updating."
  out=$(curl -sS -o /tmp/out.json -w '%{http_code}' -X PATCH -H "$AUTH" -H 'Content-Type: application/json' -d "$(body)" "$API/${APP_SLUG}/")
elif [ "$code" = "404" ]; then
  echo "Application ${APP_SLUG} not found - creating."
  out=$(curl -sS -o /tmp/out.json -w '%{http_code}' -X POST -H "$AUTH" -H 'Content-Type: application/json' -d "$(body)" "$API/")
else
  echo "Unexpected status ${code} reading application:"; cat /tmp/get.json; exit 1
fi
case "$out" in
  2*) echo "OK (${out}): ${APP_SLUG} -> ${APP_LAUNCH_URL}" ;;
  *)  echo "FAILED (${out}):"; cat /tmp/out.json; exit 1 ;;
esac
{{- end }}

{{/*
Delete script — remove the Application; treat 404 as already gone.
*/}}
{{- define "authentik-application.deleteScript" -}}
set -eu
API="${AUTHENTIK_URL%/}/api/v3/core/applications"
AUTH="Authorization: Bearer ${AUTHENTIK_TOKEN}"
code=$(curl -sS -o /tmp/out.json -w '%{http_code}' -X DELETE -H "$AUTH" "$API/${APP_SLUG}/")
case "$code" in
  204|404) echo "Application ${APP_SLUG} deleted (status ${code})." ;;
  *)       echo "FAILED (${code}):"; cat /tmp/out.json; exit 1 ;;
esac
{{- end }}
