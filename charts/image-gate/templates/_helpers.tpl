{{- define "image-gate.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "image-gate.fullname" -}}
{{- printf "%s-image-gate" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "image-gate.labels" -}}
app.kubernetes.io/name: {{ include "image-gate.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: image-gate
{{- end -}}
