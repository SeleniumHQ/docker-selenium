{{/*
Expand the name of the chart.
*/}}
{{- define "seleniumGrid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "seleniumGrid.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "seleniumGrid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "seleniumGrid.commonLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service | lower }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/component: {{ printf "selenium-grid-%s" .Chart.AppVersion }}
helm.sh/chart: {{ include "seleniumGrid.chart" . }}
{{- end -}}

{{/*
Selenium Hub fullname
*/}}
{{- define "seleniumGrid.hub.fullname" -}}
{{- tpl (default (printf "%s-selenium-hub" .Release.Name) .Values.hub.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Event bus fullname
*/}}
{{- define "seleniumGrid.eventBus.fullname" -}}
{{- tpl (default (printf "%s-selenium-event-bus" .Release.Name) .Values.components.eventBus.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Event bus ConfigMap fullname
*/}}
{{- define "seleniumGrid.eventBus.configmap.fullname" -}}
{{- tpl (default (include "seleniumGrid.eventBus.fullname" $) .Values.busConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Router fullname
*/}}
{{- define "seleniumGrid.router.fullname" -}}
{{- tpl (default (printf "%s-selenium-router" .Release.Name) .Values.components.router.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Distributor fullname
*/}}
{{- define "seleniumGrid.distributor.fullname" -}}
{{- tpl (default (printf "%s-selenium-distributor" .Release.Name) .Values.components.distributor.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
SessionMap fullname
*/}}
{{- define "seleniumGrid.sessionMap.fullname" -}}
{{- tpl (default (printf "%s-selenium-session-map" .Release.Name) .Values.components.sessionMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
SessionQueue fullname
*/}}
{{- define "seleniumGrid.sessionQueue.fullname" -}}
{{- tpl (default (printf "%s-selenium-session-queue" .Release.Name) .Values.components.sessionQueue.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Chrome node fullname
*/}}
{{- define "seleniumGrid.chromeNode.fullname" -}}
{{- tpl (default (printf "%s-selenium-chrome-node" .Release.Name) .Values.chromeNode.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Firefox node fullname
*/}}
{{- define "seleniumGrid.firefoxNode.fullname" -}}
{{- tpl (default (printf "%s-selenium-firefox-node" .Release.Name) .Values.firefoxNode.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Edge node fullname
*/}}
{{- define "seleniumGrid.edgeNode.fullname" -}}
{{- tpl (default (printf "%s-selenium-edge-node" .Release.Name) .Values.edgeNode.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Ingress fullname
*/}}
{{- define "seleniumGrid.ingress.fullname" -}}
{{- tpl (default (printf "%s-selenium-ingress" .Release.Name) .Values.ingress.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common secrets cross components
*/}}
{{- define "seleniumGrid.common.secrets.fullname" -}}
{{- tpl (default (printf "%s-selenium-secrets" .Release.Name) .Values.secrets.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Secret TLS fullname
*/}}
{{- define "seleniumGrid.tls.fullname" -}}
{{- tpl (default (printf "%s-selenium-tls-secret" .Release.Name) .Values.tls.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Service Account fullname
*/}}
{{- define "seleniumGrid.serviceAccount.fullname" -}}
{{- tpl (default (printf "%s-selenium-serviceaccount" .Release.Name) .Values.serviceAccount.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Recorder ConfigMap fullname
*/}}
{{- define "seleniumGrid.recorder.configmap.fullname" -}}
{{- tpl (default (printf "%s-selenium-recorder-config" .Release.Name) .Values.recorderConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Uploader ConfigMap fullname
*/}}
{{- define "seleniumGrid.uploader.configmap.fullname" -}}
{{- tpl (default (printf "%s-selenium-uploader-config" .Release.Name) .Values.uploaderConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Logging ConfigMap fullname
*/}}
{{- define "seleniumGrid.logging.configmap.fullname" -}}
{{- tpl (default (printf "%s-selenium-logging-config" .Release.Name) .Values.loggingConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Node ConfigMap fullname
*/}}
{{- define "seleniumGrid.node.configmap.fullname" -}}
{{- tpl (default (printf "%s-selenium-node-config" .Release.Name) .Values.nodeConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Server ConfigMap fullname
*/}}
{{- define "seleniumGrid.server.configmap.fullname" -}}
{{- tpl (default (printf "%s-selenium-server-config" .Release.Name) .Values.serverConfigMap.nameOverride) $ | trunc 63 | trimSuffix "-" -}}
{{- end -}}
