{{/*
Expand the name of the chart.
*/}}
{{- define "grommunio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grommunio.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "grommunio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grommunio.labels" -}}
helm.sh/chart: {{ include "grommunio.chart" . }}
{{ include "grommunio.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "grommunio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grommunio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "grommunio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "grommunio.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database full names
*/}}
{{- define "grommunio.gromoxDb.fullname" -}}
{{- printf "%s-gromox-db" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.chatDb.fullname" -}}
{{- printf "%s-chat-db" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.filesDb.fullname" -}}
{{- printf "%s-files-db" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.officeDb.fullname" -}}
{{- printf "%s-office-db" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.archiveDb.fullname" -}}
{{- printf "%s-archive-db" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Application full names
*/}}
{{- define "grommunio.core.fullname" -}}
{{- printf "%s-core" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.archive.fullname" -}}
{{- printf "%s-archive" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grommunio.office.fullname" -}}
{{- printf "%s-office" (include "grommunio.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Database labels
*/}}
{{- define "grommunio.gromoxDb.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: gromox-database
{{- end }}

{{- define "grommunio.chatDb.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: chat-database
{{- end }}

{{- define "grommunio.filesDb.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: files-database
{{- end }}

{{- define "grommunio.officeDb.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: office-database
{{- end }}

{{- define "grommunio.archiveDb.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: archive-database
{{- end }}

{{/*
Database selector labels
*/}}
{{- define "grommunio.gromoxDb.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: gromox-database
{{- end }}

{{- define "grommunio.chatDb.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: chat-database
{{- end }}

{{- define "grommunio.filesDb.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: files-database
{{- end }}

{{- define "grommunio.officeDb.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: office-database
{{- end }}

{{- define "grommunio.archiveDb.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: archive-database
{{- end }}

{{/*
Application labels
*/}}
{{- define "grommunio.core.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: core
{{- end }}

{{- define "grommunio.archive.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: archive
{{- end }}

{{- define "grommunio.office.labels" -}}
{{ include "grommunio.labels" . }}
app.kubernetes.io/component: office
{{- end }}

{{/*
Application selector labels
*/}}
{{- define "grommunio.core.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: core
{{- end }}

{{- define "grommunio.archive.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: archive
{{- end }}

{{- define "grommunio.office.selectorLabels" -}}
{{ include "grommunio.selectorLabels" . }}
app.kubernetes.io/component: office
{{- end }}

{{/*
Get the database secret name
*/}}
{{- define "grommunio.gromoxDb.secretName" -}}
{{- if .Values.databases.gromox.existingSecret }}
{{- .Values.databases.gromox.existingSecret }}
{{- else }}
{{- include "grommunio.gromoxDb.fullname" . }}
{{- end }}
{{- end }}

{{- define "grommunio.chatDb.secretName" -}}
{{- if .Values.databases.chat.existingSecret }}
{{- .Values.databases.chat.existingSecret }}
{{- else }}
{{- include "grommunio.chatDb.fullname" . }}
{{- end }}
{{- end }}

{{- define "grommunio.filesDb.secretName" -}}
{{- if .Values.databases.files.existingSecret }}
{{- .Values.databases.files.existingSecret }}
{{- else }}
{{- include "grommunio.filesDb.fullname" . }}
{{- end }}
{{- end }}

{{- define "grommunio.officeDb.secretName" -}}
{{- if .Values.databases.office.existingSecret }}
{{- .Values.databases.office.existingSecret }}
{{- else }}
{{- include "grommunio.officeDb.fullname" . }}
{{- end }}
{{- end }}

{{- define "grommunio.archiveDb.secretName" -}}
{{- if .Values.databases.archive.existingSecret }}
{{- .Values.databases.archive.existingSecret }}
{{- else }}
{{- include "grommunio.archiveDb.fullname" . }}
{{- end }}
{{- end }}

{{/*
Get storage class
*/}}
{{- define "grommunio.storageClass" -}}
{{- $storageClass := .global -}}
{{- if .local -}}
{{- $storageClass = .local -}}
{{- end -}}
{{- if $storageClass -}}
storageClassName: {{ $storageClass | quote }}
{{- end -}}
{{- end }}

{{/*
Return the appropriate apiVersion for PodDisruptionBudget
*/}}
{{- define "grommunio.pdb.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1" }}
{{- print "policy/v1" }}
{{- else }}
{{- print "policy/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Image pull secrets helper
*/}}
{{- define "grommunio.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
