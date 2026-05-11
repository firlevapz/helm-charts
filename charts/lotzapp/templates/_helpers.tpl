{{- define "lotzapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "lotzapp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "lotzapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "lotzapp.labels" -}}
helm.sh/chart: {{ include "lotzapp.chart" . }}
app.kubernetes.io/name: {{ include "lotzapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "lotzapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lotzapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "lotzapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "lotzapp.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
  Effective database host.
  Returns the in-cluster service name when the built-in DB is enabled,
  or the user-supplied external host otherwise.
*/}}
{{- define "lotzapp.databaseHost" -}}
{{- if .Values.database.enabled -}}
{{- printf "%s-lotzapp-database" .Release.Name -}}
{{- else -}}
{{- required "database.external.host is required when database.enabled is false" .Values.database.external.host -}}
{{- end -}}
{{- end -}}

{{/*
  Effective database port.
*/}}
{{- define "lotzapp.databasePort" -}}
{{- if .Values.database.enabled -}}
3306
{{- else -}}
{{- .Values.database.external.port | default "3306" -}}
{{- end -}}
{{- end -}}

{{/*
  Effective database user for migrations.
  Prefers migration.mariadbUser override, then database.external.user / root.
*/}}
{{- define "lotzapp.databaseUser" -}}
{{- if .Values.migration.mariadbUser -}}
{{- .Values.migration.mariadbUser -}}
{{- else if .Values.database.enabled -}}
root
{{- else -}}
{{- .Values.database.external.user | default "root" -}}
{{- end -}}
{{- end -}}

{{/*
  Effective database password for migrations.
  Prefers migration.mariadbPassword override, then database.rootPassword / database.external.password.
*/}}
{{- define "lotzapp.databasePassword" -}}
{{- if .Values.migration.mariadbPassword -}}
{{- .Values.migration.mariadbPassword -}}
{{- else if .Values.database.enabled -}}
{{- .Values.database.rootPassword -}}
{{- else -}}
{{- required "database.external.password is required when database.enabled is false" .Values.database.external.password -}}
{{- end -}}
{{- end -}}
