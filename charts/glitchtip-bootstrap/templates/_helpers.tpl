{{- define "glitchtip-bootstrap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "glitchtip-bootstrap.fullname" -}}
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

{{- define "glitchtip-bootstrap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "glitchtip-bootstrap.labels" -}}
helm.sh/chart: {{ include "glitchtip-bootstrap.chart" . }}
app.kubernetes.io/name: {{ include "glitchtip-bootstrap.name" . }}
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
GlitchTip runtime config — the minimum env for Django to start (used by both the migrate
hook and the bootstrap hook). REDIS_URL is a literal pointing at the valkey Service: the
migrate hook runs at wave -1, before the GlitchTip chart's REDIS_URL secret (wave 0)
exists, and migrations don't touch Redis anyway.
*/}}
{{- define "glitchtip-bootstrap.runtimeEnv" -}}
- name: DEBUG
  value: "False"
- name: DJANGO_SETTINGS_MODULE
  value: {{ .Values.djangoSettingsModule | quote }}
- name: GLITCHTIP_DOMAIN
  value: {{ required "glitchtipDomain is required" .Values.glitchtipDomain | quote }}
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secretKeyRef.name | quote }}
      key: {{ .Values.secretKeyRef.key | quote }}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.databaseSecret.name | quote }}
      key: {{ .Values.databaseSecret.key | quote }}
- name: REDIS_URL
  value: {{ .Values.redisUrl | quote }}
{{- end }}

{{/*
Environment for the bootstrap Job: runtime config plus the script's own inputs.
*/}}
{{- define "glitchtip-bootstrap.env" -}}
{{- include "glitchtip-bootstrap.runtimeEnv" . }}
# ── OIDC SocialApp inputs ──
- name: OIDC_PROVIDER
  value: {{ .Values.oidc.provider | quote }}
- name: OIDC_PROVIDER_ID
  value: {{ .Values.oidc.providerId | quote }}
- name: OIDC_NAME
  value: {{ .Values.oidc.name | quote }}
- name: OIDC_CLIENT_ID
  value: {{ .Values.oidc.clientId | quote }}
- name: OIDC_SERVER_URL
  value: {{ .Values.oidc.serverUrl | quote }}
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.oidc.secretRef.name | quote }}
      key: {{ .Values.oidc.secretRef.key | quote }}
# ── Shared project / DSN inputs ──
- name: ORG_NAME
  value: {{ .Values.org.name | quote }}
- name: PROJECT_NAME
  value: {{ .Values.project.name | quote }}
- name: DSN_SECRET_NAME
  value: {{ .Values.dsnSecret.name | quote }}
- name: DSN_SECRET_KEY
  value: {{ .Values.dsnSecret.key | quote }}
- name: RETRY_ATTEMPTS
  value: {{ .Values.retries.attempts | quote }}
- name: RETRY_DELAY_SECONDS
  value: {{ .Values.retries.delaySeconds | quote }}
{{- end }}
