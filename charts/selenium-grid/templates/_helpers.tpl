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
Chromium node fullname
*/}}
{{- define "seleniumGrid.chromiumNode.fullname" -}}
{{- default "selenium-chromium-node" .Values.chromiumNode.nameOverride | trunc 63 | trimSuffix "-" -}}
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

{{- define "seleniumGrid.ingress.nginx.annotations.default" -}}
{{- with .Values.ingress.nginx }}
  {{- with .proxyTimeout }}
nginx.ingress.kubernetes.io/proxy-connect-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-send-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-read-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-next-upstream-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/auth-keepalive-timeout: {{ . | quote }}
  {{- end }}
  {{- with .proxyBuffer }}
nginx.ingress.kubernetes.io/proxy-request-buffering: "on"
nginx.ingress.kubernetes.io/proxy-buffering: "on"
    {{- with .size }}
nginx.ingress.kubernetes.io/proxy-buffer-size: {{ . | quote }}
nginx.ingress.kubernetes.io/client-body-buffer-size: {{ . | quote }}
    {{- end }}
    {{- with .number }}
nginx.ingress.kubernetes.io/proxy-buffers-number: {{ . | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Service Account fullname
*/}}
{{- define "seleniumGrid.serviceAccount.fullname" -}}
{{- .Values.serviceAccount.name | default "selenium-serviceaccount" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Video ConfigMap fullname
*/}}
{{- define "seleniumGrid.video.fullname" -}}
{{- default "selenium-video" .Values.videoRecorder.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Is autoscaling using KEDA enabled
*/}}
{{- define "seleniumGrid.useKEDA" -}}
{{- or .Values.autoscaling.enabled .Values.autoscaling.enableWithExistingKEDA | ternary "true" "" -}}
{{- end -}}

{{/*
Common autoscaling spec template
*/}}
{{- define "seleniumGrid.autoscalingTemplate" -}}
{{- $spec := toYaml (dict) -}}
{{/* Merge with precedence from right to left */}}
{{- with .Values.autoscaling.scaledOptions -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
{{- end -}}
{{- with .node.scaledOptions -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
{{- end -}}
{{- if eq .Values.autoscaling.scalingType "deployment" -}}
  {{- with .Values.autoscaling.scaledObjectOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- with .node.scaledObjectOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) (dict "scaleTargetRef" (dict "name" .name)) | toYaml -}}
{{- else if eq .Values.autoscaling.scalingType "job" -}}
  {{- with .Values.autoscaling.scaledJobOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- with .node.scaledJobOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) (dict "jobTargetRef" .podTemplate) | toYaml -}}
{{- end -}}
{{- if and $spec (ne $spec "{}") -}}
  {{ tpl $spec $ }}
{{- end -}}
{{- if not .Values.autoscaling.scaledOptions.triggers }}
triggers:
  - type: selenium-grid
  {{- with .node.hpa }}
    metadata: {{- tpl (toYaml .) $ | nindent 6 }}
  {{- end }}
{{- end }}
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
    serviceAccountName: {{ template "seleniumGrid.serviceAccount.fullname" . }}
    serviceAccount: {{ template  "seleniumGrid.serviceAccount.fullname" . }}
    restartPolicy: {{ and (eq (include "seleniumGrid.useKEDA" .) "true") (eq .Values.autoscaling.scalingType "job") | ternary "Never" "Always" }}
  {{- with .node.hostAliases }}
    hostAliases: {{ toYaml . | nindent 6 }}
  {{- end }}
    containers:
      - name: {{.name}}
        {{- $imageTag := default .Values.global.seleniumGrid.nodesImageTag .node.imageTag }}
        {{- $imageRegistry := default .Values.global.seleniumGrid.imageRegistry .node.imageRegistry }}
        image: {{ printf "%s/%s:%s" $imageRegistry .node.imageName $imageTag }}
        imagePullPolicy: {{ .node.imagePullPolicy }}
      {{- with .node.extraEnvironmentVariables }}
        env: {{- tpl (toYaml .) $ | nindent 10 }}
      {{- end }}
        envFrom:
          - configMapRef:
              name: {{ .Values.busConfigMap.name }}
          - configMapRef:
              name: {{ .Values.nodeConfigMap.name }}
          {{- with .node.extraEnvFrom }}
            {{- tpl (toYaml .) $ | nindent 10 }}
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
          {{- tpl (toYaml .node.extraVolumeMounts) $ | nindent 10 }}
        {{- end }}
      {{- with .node.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .node.securityContext }}
        securityContext: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- include "seleniumGrid.lifecycle" . | nindent 8 -}}
      {{- with .node.startupProbe }}
        startupProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .node.livenessProbe }}
        livenessProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
    {{- if .node.sidecars }}
      {{- toYaml .node.sidecars | nindent 6 }}
    {{- end }}
    {{- if .Values.videoRecorder.enabled }}
      - name: video
        {{- $imageTag := default .Values.global.seleniumGrid.videoImageTag .Values.videoRecorder.imageTag }}
        {{- $imageRegistry := default .Values.global.seleniumGrid.imageRegistry .Values.videoRecorder.imageRegistry }}
        image: {{ printf "%s/%s:%s" $imageRegistry .Values.videoRecorder.imageName $imageTag }}
        imagePullPolicy: {{ .Values.videoRecorder.imagePullPolicy }}
        env:
        - name: UPLOAD_DESTINATION_PREFIX
          value: {{ .Values.videoRecorder.uploadDestinationPrefix | quote }}
      {{- with .Values.videoRecorder.extraEnvironmentVariables }}
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
        envFrom:
        - configMapRef:
            name: {{ .Values.busConfigMap.name }}
      {{- with .Values.videoRecorder.extraEnvFrom }}
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- if gt (len .Values.videoRecorder.ports) 0 }}
        ports:
      {{- range .Values.videoRecorder.ports }}
        - containerPort: {{ . }}
          protocol: TCP
      {{- end }}
      {{- end }}
        volumeMounts:
        - name: dshm
          mountPath: /dev/shm
      {{- tpl (include "seleniumGrid.video.volumeMounts" .) $ | nindent 8 }}
      {{- with .Values.videoRecorder.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .Values.videoRecorder.startupProbe }}
        startupProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .Values.videoRecorder.livenessProbe }}
        livenessProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
    {{- if .uploader }}
      - name: uploader
        image: {{ printf "%s:%s" .uploader.imageName .uploader.imageTag }}
        imagePullPolicy: {{ .uploader.imagePullPolicy }}
      {{- with .uploader.command }}
        command: {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- with .uploader.args }}
        args: {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- with .uploader.extraEnvironmentVariables }}
        env: {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
        {{- with .uploader.extraEnvFrom }}
        envFrom:
          {{- tpl (toYaml .) $ | nindent 10 }}
        {{- end }}
        volumeMounts:
        {{- tpl (include "seleniumGrid.video.uploader.volumeMounts" .) $ | nindent 8 }}
      {{- with .uploader.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .uploader.securityContext }}
        securityContext: {{- toYaml . | nindent 10 }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- if or .Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
    imagePullSecrets:
      - name: {{ default .Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
  {{- end }}
  {{- with .node.nodeSelector }}
    nodeSelector: {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- with .node.affinity }}
    affinity: {{- toYaml . | nindent 6 }}
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
      {{ tpl (toYaml .node.extraVolumes) $ | nindent 6 }}
    {{- end }}
    {{- if .Values.videoRecorder.enabled }}
      {{- tpl (include "seleniumGrid.video.volumes" .) $ | nindent 6 }}
    {{- end }}
{{- end -}}

{{/*
Get the url of the grid. If the external url can be figured out from the ingress use that, otherwise the cluster internal url
*/}}
{{- define "seleniumGrid.url" -}}
{{- if and .Values.ingress.enabled .Values.ingress.hostname (ne .Values.ingress.hostname "selenium-grid.local") -}}
http{{if .Values.ingress.tls}}s{{end}}://{{- if eq .Values.basicAuth.enabled true}}{{ .Values.basicAuth.username}}:{{ .Values.basicAuth.password}}@{{- end}}{{.Values.ingress.hostname}}
{{- else -}}
http://{{- if eq .Values.basicAuth.enabled true}}{{ .Values.basicAuth.username}}:{{ .Values.basicAuth.password}}@{{- end}}{{ include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ }}.{{ .Release.Namespace }}:{{ $.Values.components.router.port }}
{{- end }}
{{- end -}}

{{- define "seleniumGrid.url.subPath" -}}
{{- $subPath := "/" -}}
{{ if $.Values.isolateComponents }}
  {{- $subPath = default $subPath $.Values.components.subPath -}}
{{- else -}}
  {{- $subPath = default $subPath $.Values.hub.subPath -}}
{{- end -}}
{{ $subPath }}
{{- end -}}

{{/*
Graphql Url of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL" -}}
http://{{- if eq .Values.basicAuth.enabled true}}{{ .Values.basicAuth.username}}:{{ .Values.basicAuth.password}}@{{- end}}{{ include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ }}.{{ .Release.Namespace }}:{{ $.Values.components.router.port }}/graphql
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

{{/*
Default specs of VolumeMounts and Volumes for video recorder
*/}}
{{- define "seleniumGrid.video.volume.name.folder" -}}
{{- $name := default "video" (((.Values.videoRecorder).volume).name).folder -}}
{{- $name -}}
{{- end -}}

{{- define "seleniumGrid.video.volume.name.scripts" -}}
{{- $name := default "video-scripts" (((.Values.videoRecorder).volume).name).scripts -}}
{{- $name -}}
{{- end -}}

{{- define "seleniumGrid.video.volumeMounts.default" -}}
- name: {{ include "seleniumGrid.video.volume.name.scripts" . }}
  mountPath: /opt/bin/video.sh
  subPath: video.sh
- name: {{ include "seleniumGrid.video.volume.name.folder" . }}
  mountPath: /videos
{{- end -}}

{{- define "seleniumGrid.video.volumes.default" -}}
- name: {{ include "seleniumGrid.video.volume.name.scripts" . }}
  configMap:
    name: {{ template "seleniumGrid.video.fullname" . }}
    defaultMode: 0500
- name: {{ include "seleniumGrid.video.volume.name.folder" . }}
  emptyDir: {}
{{- end -}}

{{- define "seleniumGrid.video.uploader.volumeMounts.default" -}}
- name: {{ include "seleniumGrid.video.volume.name.folder" . }}
  mountPath: /videos
{{- end -}}

{{/* Combine videoRecorder.extraVolumeMounts with the default ones for container video recorder */}}
{{- define "seleniumGrid.video.volumeMounts" -}}
{{- $videoVolumeMounts := list -}}
{{- if .Values.videoRecorder.extraVolumeMounts -}}
  {{- range .Values.videoRecorder.extraVolumeMounts -}}
    {{- $videoVolumeMounts = append $videoVolumeMounts . -}}
  {{- end -}}
{{- end -}}
{{- $defaultVolumeMounts := (include "seleniumGrid.video.volumeMounts.default" . | toString | fromYamlArray ) -}}
{{- $videoVolumeMounts = include "utils.appendDefaultIfNotExist" (dict "currentArray" $videoVolumeMounts "defaultArray" $defaultVolumeMounts "uniqueKey" "mountPath") -}}
{{- not (empty $videoVolumeMounts) | ternary $videoVolumeMounts "" -}}
{{- end -}}

{{/* Combine videoRecorder.uploader.extraVolumeMounts with the default ones for container video uploader */}}
{{- define "seleniumGrid.video.uploader.volumeMounts" -}}
{{- $videoUploaderVolumeMounts := list -}}
{{- if .uploader.extraVolumeMounts -}}
  {{- range .uploader.extraVolumeMounts -}}
    {{- $videoUploaderVolumeMounts = append $videoUploaderVolumeMounts . -}}
  {{- end -}}
{{- end }}
{{- $defaultVolumeMounts := (include "seleniumGrid.video.uploader.volumeMounts.default" . | toString | fromYamlArray ) -}}
{{- $videoUploaderVolumeMounts = include "utils.appendDefaultIfNotExist" (dict "currentArray" $videoUploaderVolumeMounts "defaultArray" $defaultVolumeMounts "uniqueKey" "mountPath") -}}
{{- not (empty $videoUploaderVolumeMounts) | ternary $videoUploaderVolumeMounts "" -}}
{{- end -}}

{{/* Combine videoRecorder.extraVolumes with the default ones for the node pod */}}
{{- define "seleniumGrid.video.volumes" -}}
{{- $videoVolumes := list -}}
{{- if .Values.videoRecorder.extraVolumes -}}
  {{- range .Values.videoRecorder.extraVolumes -}}
    {{- $videoVolumes = append $videoVolumes . -}}
  {{- end -}}
{{- end -}}
{{- $defaultVolumes := (include "seleniumGrid.video.volumes.default" . | toString | fromYamlArray ) -}}
{{- $videoVolumes = include "utils.appendDefaultIfNotExist" (dict "currentArray" $videoVolumes "defaultArray" $defaultVolumes "uniqueKey" "name") -}}
{{- not (empty $videoVolumes) | ternary $videoVolumes "" -}}
{{- end -}}

{{/*
Is used to append default items needed to an array if they are not already present. Args: currentArray, defaultArray, uniqueKey
Usage: {{- $thisArray = include "utils.appendDefaultIfNotExist" (dict "currentArray" $thisArray "defaultArray" $defaultArray "uniqueKey" $uniqueKey }}
*/}}
{{- define "utils.appendDefaultIfNotExist" -}}
  {{- $currentArray := index . "currentArray" -}}
  {{- $defaultArray := index . "defaultArray" -}}
  {{- $uniqueKey := index . "uniqueKey" -}}
  {{- range $default := $defaultArray -}}
    {{- if eq (len $currentArray) 0 -}}
      {{- $currentArray = append $currentArray $default -}}
    {{- end -}}
    {{- $isExisting := false -}}
    {{- range $current := $currentArray -}}
      {{- if eq (index $default $uniqueKey | toString) (index $current $uniqueKey | toString) -}}
        {{- $isExisting = true -}}
      {{- end -}}
    {{- end -}}
    {{- if not $isExisting -}}
      {{- $currentArray = append $currentArray $default -}}
    {{- end -}}
  {{- end -}}
  {{- $currentArray | toYaml -}}
{{- end -}}
