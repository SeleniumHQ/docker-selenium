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


{{/*
Ingress fullname
*/}}
{{- define "seleniumGrid.ingress.fullname" -}}
{{- default "selenium-ingress" .Values.ingress.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Is autoscaling using KEDA enabled
*/}}
{{- define "seleniumGrid.useKEDA" -}}
{{- or .Values.autoscaling.enabled .Values.autoscaling.enableWithExistingKEDA | ternary "true" "" -}}
{{- end -}}


{{/*
Common pod template
*/}}
{{- define "seleniumGrid.podTemplate" -}}
template:
  metadata:
    labels:
      app: {{.name}}
      app.kubernetes.io/name: {{.name}}
      {{- include "seleniumGrid.commonLabels" . | nindent 6 }}
      {{- with .node.labels }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- with .Values.customLabels }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
    annotations:
      checksum/event-bus-configmap: {{ include (print $.Template.BasePath "/event-bus-configmap.yaml") . | sha256sum }}
      {{- with .node.annotations }}
        {{ toYaml . | nindent 6 }}
      {{- end }}
  spec:
    restartPolicy: {{ and (eq (include "seleniumGrid.useKEDA" .) "true") (eq .Values.autoscaling.scalingType "job") | ternary "Never" "Always" }}
  {{- with .node.hostAliases }}
    hostAliases: {{ toYaml . | nindent 6 }}
  {{- end }}
    containers:
      - name: {{.name}}
        {{- $imageTag := default .Values.global.seleniumGrid.nodesImageTag .node.imageTag }}
        image: {{ printf "%s:%s" .node.imageName $imageTag }}
        imagePullPolicy: {{ .node.imagePullPolicy }}
      {{- with .node.extraEnvironmentVariables }}
        env: {{- tpl (toYaml .) $ | nindent 10 }}
      {{- end }}
        envFrom:
          - configMapRef:
              name: {{ .Values.busConfigMap.name }}
          {{- with .node.extraEnvFrom }}
            {{- toYaml . | nindent 10 }}
          {{- end }}
      {{- if gt (len .node.ports) 0 }}
        ports:
        {{- range .node.ports }}
          - containerPort: {{ . }}
            protocol: TCP
        {{- end }}
      {{- end }}
        volumeMounts:
          - name: dshm
            mountPath: /dev/shm
        {{- if .node.extraVolumeMounts }}
          {{- toYaml .node.extraVolumeMounts | nindent 10 }}
        {{- end }}
      {{- with .node.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- include "seleniumGrid.lifecycle" . | nindent 8 -}}
      {{- with .node.startupProbe }}
        startupProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
  {{- if or .Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
    imagePullSecrets:
      - name: {{ default .Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
  {{- end }}
  {{- with .node.nodeSelector }}
    nodeSelector: {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- with .node.tolerations }}
    tolerations:
      {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .node.priorityClassName }}
    priorityClassName: {{ . }}
  {{- end }}
    terminationGracePeriodSeconds: {{ .node.terminationGracePeriodSeconds }}
    volumes:
      - name: dshm
        emptyDir:
          medium: Memory
          sizeLimit: {{ default "1Gi" .node.dshmVolumeSizeLimit }}
    {{- if .node.extraVolumes }}
      {{ toYaml .node.extraVolumes | nindent 6 }}
    {{- end }}
{{- end -}}

{{/*
Get the url of the grid. If the external url can be figured out from the ingress use that, otherwise the cluster internal url
*/}}
{{- define "seleniumGrid.url" -}}
{{- if and .Values.ingress.enabled .Values.ingress.hostname (ne .Values.ingress.hostname "selenium-grid.local") -}}
http{{if .Values.ingress.tls}}s{{end}}://{{.Values.ingress.hostname}}
{{- else -}}
http://{{ include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ }}.{{ .Release.Namespace }}:{{ $.Values.components.router.port }}
{{- end }}
{{- end -}}

{{/*
Graphql Url of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL" -}}
http://{{ include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ }}.{{ .Release.Namespace }}:{{ $.Values.components.router.port }}/graphql
{{- end -}}

{{/*
Get the lifecycle of the pod. When KEDA is activated and the lifecycle is used for a pod of a
deployment preStop hook to deregister from the selenium hub.
*/}}
{{- define "seleniumGrid.lifecycle" }}
{{ $lifecycle := tpl (toYaml (default (dict) .node.lifecycle)) $ }}
{{- if and (eq .Values.autoscaling.scalingType "deployment") (eq (include "seleniumGrid.useKEDA" .) "true") -}}
{{ $lifecycle = merge ($lifecycle | fromYaml ) .Values.autoscaling.deregisterLifecycle | toYaml }}
{{- end -}}
{{ if and $lifecycle (ne $lifecycle "{}") -}}
lifecycle: {{ $lifecycle | nindent 2 }}
{{- end -}}
{{- end -}}
