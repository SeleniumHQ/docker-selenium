{{/*
Common labels
*/}}
{{- define "seleniumGrid.commonLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service | lower }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/component: {{ printf "selenium-grid-%s" .Chart.AppVersion }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") }}
{{- end -}}

{{/*
Selenium Hub fullname
*/}}
{{- define "seleniumGrid.hub.fullname" -}}
{{- default "selenium-hub" .Values.hub.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Event bus fullname
*/}}
{{- define "seleniumGrid.eventBus.fullname" -}}
{{- default "selenium-event-bus" .Values.components.eventBus.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Router fullname
*/}}
{{- define "seleniumGrid.router.fullname" -}}
{{- default "selenium-router" .Values.components.router.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Distributor fullname
*/}}
{{- define "seleniumGrid.distributor.fullname" -}}
{{- default "selenium-distributor" .Values.components.distributor.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
SessionMap fullname
*/}}
{{- define "seleniumGrid.sessionMap.fullname" -}}
{{- default "selenium-session-map" .Values.components.sessionMap.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
SessionQueue fullname
*/}}
{{- define "seleniumGrid.sessionQueue.fullname" -}}
{{- default "selenium-session-queue" .Values.components.sessionQueue.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Chrome node fullname
*/}}
{{- define "seleniumGrid.chromeNode.fullname" -}}
{{- default "selenium-chrome-node" .Values.chromeNode.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Firefox node fullname
*/}}
{{- define "seleniumGrid.firefoxNode.fullname" -}}
{{- default "selenium-firefox-node" .Values.firefoxNode.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Edge node fullname
*/}}
{{- define "seleniumGrid.edgeNode.fullname" -}}
{{- default "selenium-edge-node" .Values.edgeNode.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
