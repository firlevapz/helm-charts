{{/*
Expand the name of the chart.
*/}}
{{- define "vapid-generator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "vapid-generator.fullname" -}}
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
Chart name and version as used by the chart label.
*/}}
{{- define "vapid-generator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vapid-generator.labels" -}}
helm.sh/chart: {{ include "vapid-generator.chart" . }}
{{ include "vapid-generator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vapid-generator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vapid-generator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Namespace the Secret (and the RBAC scoped to it) live in.
*/}}
{{- define "vapid-generator.secretNamespace" -}}
{{- default .Release.Namespace .Values.secret.namespace }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "vapid-generator.serviceAccountName" -}}
{{- default (include "vapid-generator.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Common annotations (sync-wave + user-supplied), for use under metadata.annotations.
*/}}
{{- define "vapid-generator.annotations" -}}
argocd.argoproj.io/sync-wave: {{ .Values.syncWave | quote }}
{{- with .Values.annotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
The generator script. Pure node built-in `crypto` + `https` — no npm packages,
no network beyond the in-cluster API server. Static (all inputs come from env
vars) so its checksum only changes when the logic changes.
*/}}
{{- define "vapid-generator.script" -}}
'use strict';
const https = require('https');
const fs = require('fs');
const crypto = require('crypto');

const SA = '/var/run/secrets/kubernetes.io/serviceaccount';
const token = fs.readFileSync(`${SA}/token`, 'utf8');
const ca = fs.readFileSync(`${SA}/ca.crt`);
const namespace = process.env.TARGET_NAMESPACE;
const name = process.env.SECRET_NAME;
const subject = process.env.VAPID_SUBJECT;
const labelsJson = process.env.SECRET_LABELS || '{}';
const K = {
  subject: process.env.KEY_SUBJECT,
  publicKey: process.env.KEY_PUBLIC,
  privateKey: process.env.KEY_PRIVATE,
  publicKeyAlias: process.env.KEY_PUBLIC_ALIAS || '',
};

function api(method, path, body) {
  const data = body ? JSON.stringify(body) : null;
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        host: 'kubernetes.default.svc',
        port: 443,
        method,
        path,
        ca,
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/json',
          ...(data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {}),
        },
      },
      (res) => {
        let buf = '';
        res.on('data', (c) => (buf += c));
        res.on('end', () => resolve({ status: res.statusCode, body: buf }));
      }
    );
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// base64url per RFC 7515 — the encoding web-push uses for VAPID keys.
const b64url = (b) => b.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

function generate() {
  const ecdh = crypto.createECDH('prime256v1');
  ecdh.generateKeys();
  // Uncompressed point: 0x04 || X || Y (65 bytes).
  const publicKey = b64url(ecdh.getPublicKey());
  // Private scalar, left-padded to a fixed 32 bytes (web-push does the same).
  let priv = ecdh.getPrivateKey();
  if (priv.length < 32) priv = Buffer.concat([Buffer.alloc(32 - priv.length), priv]);
  else if (priv.length > 32) priv = priv.subarray(priv.length - 32);
  return { publicKey, privateKey: b64url(priv) };
}

(async () => {
  const base = `/api/v1/namespaces/${namespace}/secrets`;
  const existing = await api('GET', `${base}/${name}`);

  if (existing.status === 200) {
    const obj = JSON.parse(existing.body);
    if (obj.data && obj.data[K.privateKey]) {
      console.log(`Secret ${namespace}/${name} already holds a VAPID key — leaving untouched (no rotation).`);
      return;
    }
    console.log(`Secret ${namespace}/${name} exists but has no '${K.privateKey}' — not overwriting; delete it to regenerate.`);
    return;
  }
  if (existing.status !== 404) {
    throw new Error(`Unexpected ${existing.status} reading secret: ${existing.body}`);
  }

  const { publicKey, privateKey } = generate();
  const stringData = {
    [K.subject]: subject,
    [K.publicKey]: publicKey,
    [K.privateKey]: privateKey,
  };
  if (K.publicKeyAlias) stringData[K.publicKeyAlias] = publicKey;

  const secret = {
    apiVersion: 'v1',
    kind: 'Secret',
    type: 'Opaque',
    metadata: { name, namespace, labels: JSON.parse(labelsJson) },
    stringData,
  };

  const created = await api('POST', base, secret);
  if (created.status >= 200 && created.status < 300) {
    console.log(`Created VAPID secret ${namespace}/${name}.`);
  } else if (created.status === 409) {
    console.log(`Secret ${namespace}/${name} created concurrently — leaving as-is.`);
  } else {
    throw new Error(`Failed to create secret (${created.status}): ${created.body}`);
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
{{- end }}
