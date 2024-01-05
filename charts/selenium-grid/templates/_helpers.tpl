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
Protocol of server components
*/}}
{{- define "seleniumGrid.server.protocol" -}}
{{- .Values.tls.enabled | ternary "https" "http" -}}
{{- end -}}

{{/*
Probe httpGet schema
*/}}
{{- define "seleniumGrid.probe.httpGet.schema" -}}
{{- .Values.tls.enabled | ternary "HTTPS" "HTTP" -}}
{{- end -}}

{{/*
Check user define custom probe method
*/}}
{{- define "seleniumGrid.probe.fromUserDefine" -}}
{{- $overrideProbe := dict -}}
{{- with .exec -}}
{{- $overrideProbe = dict "exec" . -}}
{{- end }}
{{- with .httpGet -}}
{{- $overrideProbe = dict "httpGet" . -}}
{{- end }}
{{- with .tcpSocket -}}
{{- $overrideProbe = dict "tcpSocket" . -}}
{{- end }}
{{- with .grpc -}}
{{- $overrideProbe = dict "grpc" . -}}
{{- end -}}
{{- $overrideProbe | toYaml -}}
{{- end -}}

{{/*
Get probe settings
*/}}
{{- define "seleniumGrid.probe.settings" -}}
{{- $settings := dict -}}
{{- with .initialDelaySeconds -}}
  {{- $settings = set $settings "initialDelaySeconds" . -}}
{{- end }}
{{- with .periodSeconds -}}
  {{- $settings = set $settings "periodSeconds" . -}}
{{- end }}
{{- with .timeoutSeconds -}}
  {{- $settings = set $settings "timeoutSeconds" . -}}
{{- end }}
{{- with .successThreshold -}}
  {{- $settings = set $settings "successThreshold" . -}}
{{- end }}
{{- with .failureThreshold -}}
  {{- $settings = set $settings "failureThreshold" . -}}
{{- end -}}
{{- $settings | toYaml -}}
{{- end -}}

{{/*
Secret TLS fullname
*/}}
{{- define "seleniumGrid.tls.fullname" -}}
{{- default "selenium-tls-secret" .Values.tls.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Is registration secret enabled
*/}}
{{- define "seleniumGrid.tls.registrationSecret.enabled" -}}
{{- and .Values.tls.enabled .Values.tls.registrationSecret.enabled | ternary "true" "" -}}
{{- end -}}

{{/*
Get default certificate file name in chart
*/}}
{{- define "seleniumGrid.tls.getDefaultFile" -}}
{{- $value := index . 0 -}}
{{- $global := index . 1 -}}
{{- $content := $global.Files.Get $value -}}
{{- if (contains "base64" (lower $value)) -}}
  {{- $content = $content | b64dec -}}
{{- end -}}
{{- $content -}}
{{- end -}}

{{/*
Common secrets cross components
*/}}
{{- define "seleniumGrid.common.secrets" -}}
{{- default "selenium-secrets" .Values.secrets.nameOverride | trunc 63 | trimSuffix "-" -}}
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
{{- if .Values.tls.enabled }}
nginx.ingress.kubernetes.io/ssl-passthrough: "true"
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
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
        env:
          - name: SE_NODE_PORT
            value: {{ .node.port | quote }}
        {{- with .node.extraEnvironmentVariables }}
          {{- tpl (toYaml .) $ | nindent 10 }}
        {{- end }}
        envFrom:
          - configMapRef:
              name: {{ .Values.busConfigMap.name }}
          - configMapRef:
              name: {{ .Values.nodeConfigMap.name }}
          - configMapRef:
              name: {{ .Values.loggingConfigMap.name }}
          - configMapRef:
              name: {{ .Values.serverConfigMap.name }}
          - secretRef:
              name: {{ include "seleniumGrid.common.secrets" $ | quote }}
          {{- with .node.extraEnvFrom }}
            {{- tpl (toYaml .) $ | nindent 10 }}
          {{- end }}
        ports:
          - containerPort: {{ .node.port }}
            protocol: TCP
      {{- if gt (len .node.ports) 0 }}
        {{- $ports := .node.ports -}}
        {{- if (regexMatch "[0-9]+$" (index $ports 0 | toString)) -}}
          {{- range .node.ports }}
          - containerPort: {{ . | int }}
            protocol: TCP
          {{- end }}
        {{- else -}}
          {{- tpl (toYaml .node.ports) $ | nindent 10 }}
        {{- end }}
      {{- end }}
        volumeMounts:
          - name: dshm
            mountPath: /dev/shm
          - name: {{ .Values.nodeConfigMap.scriptVolumeMountName }}
            mountPath: /opt/selenium/{{ .Values.nodeConfigMap.preStopScript }}
            subPath: {{ .Values.nodeConfigMap.preStopScript }}
        {{- if .Values.tls.enabled }}
          - name: {{ include "seleniumGrid.tls.fullname" $ | quote }}
            mountPath: {{ .Values.serverConfigMap.certVolumeMountPath }}
            readOnly: true
        {{- end }}
        {{- if .node.extraVolumeMounts }}
          {{- tpl (toYaml .node.extraVolumeMounts) $ | nindent 10 }}
        {{- end }}
      {{- with .node.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .node.securityContext }}
        securityContext: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- include "seleniumGrid.node.lifecycle" . | nindent 8 -}}
      {{- if .node.startupProbe.enabled }}
      {{- with .node.startupProbe }}
        startupProbe:
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" .) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" . | nindent 10 }}
        {{- else }}
          httpGet:
            scheme: {{ default (include "seleniumGrid.probe.httpGet.schema" $) .schema }}
            path: {{ .path }}
            port: {{ default ($.node.port) .port }}
        {{- end }}
        {{- if (ne (include "seleniumGrid.probe.settings" .) "{}") }}
          {{- include "seleniumGrid.probe.settings" . | nindent 10 }}
        {{- end }}
      {{- end }}
      {{- end }}
      {{- if .node.readinessProbe.enabled }}
      {{- with .node.readinessProbe }}
        readinessProbe:
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" .) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" . | nindent 12 }}
        {{- else }}
          httpGet:
            scheme: {{ default (include "seleniumGrid.probe.httpGet.schema" $) .schema }}
            path: {{ .path }}
            port: {{ default ($.node.port) .port }}
        {{- end }}
        {{- if (ne (include "seleniumGrid.probe.settings" .) "{}") }}
          {{- include "seleniumGrid.probe.settings" . | nindent 10 }}
        {{- end }}
      {{- end }}
      {{- end }}
      {{- if .node.livenessProbe.enabled }}
      {{- with .node.livenessProbe }}
        livenessProbe:
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" .) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" . | nindent 10 }}
        {{- else }}
          httpGet:
            scheme: {{ default (include "seleniumGrid.probe.httpGet.schema" $) .schema }}
            path: {{ .path }}
            port: {{ default ($.node.port) .port }}
        {{- end }}
        {{- if (ne (include "seleniumGrid.probe.settings" .) "{}") }}
          {{- include "seleniumGrid.probe.settings" . | nindent 10 }}
        {{- end }}
      {{- end }}
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
      - name: {{ .Values.nodeConfigMap.scriptVolumeMountName }}
        configMap:
          name: {{ .Values.nodeConfigMap.name }}
          defaultMode: {{ .Values.nodeConfigMap.defaultMode }}
      - name: dshm
        emptyDir:
          medium: Memory
          sizeLimit: {{ default "1Gi" .node.dshmVolumeSizeLimit }}
    {{- if .Values.tls.enabled }}
      - name: {{ include "seleniumGrid.tls.fullname" $ | quote }}
        secret:
          secretName: {{ include "seleniumGrid.tls.fullname" $ | quote }}
    {{- end }}
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
{{- $url := printf "%s://%s%s%s%s" (include "seleniumGrid.url.schema" .) (include "seleniumGrid.url.basicAuth" .) (include "seleniumGrid.url.host" .) (include "seleniumGrid.url.port" .) (include "seleniumGrid.url.subPath" .) -}}
{{- $url }}
{{- end -}}

{{- define "seleniumGrid.url.schema" -}}
{{- $schema := "http" -}}
{{- if .Values.tls.enabled -}}
  {{- $schema = "https" -}}
{{- else if .Values.ingress.enabled -}}
  {{- if .Values.ingress.tls -}}
    {{- $schema = "https" -}}
  {{- end -}}
{{- end -}}
{{- $schema }}
{{- end -}}

{{- define "seleniumGrid.url.basicAuth" -}}
{{- $basicAuth := "" -}}
{{- if eq .Values.basicAuth.enabled true -}}
  {{- $basicAuth = printf "%s:%s@" .Values.basicAuth.username (.Values.basicAuth.password | toString) -}}
{{- end -}}
{{- $basicAuth }}
{{- end -}}

{{- define "seleniumGrid.url.host" -}}
{{- $host := printf "%s.%s" (include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ ) (.Release.Namespace) -}}
{{- if .Values.ingress.enabled -}}
  {{- if and ( empty .Values.ingress.hostname) (not (empty .Values.global.K8S_PUBLIC_IP)) -}}
    {{- $host = .Values.global.K8S_PUBLIC_IP -}}
  {{- else if and .Values.ingress.hostname (ne .Values.ingress.hostname "selenium-grid.local") -}}
    {{- $host = .Values.ingress.hostname -}}
  {{- end -}}
{{- else if not (empty .Values.global.K8S_PUBLIC_IP) -}}
  {{- $host = .Values.global.K8S_PUBLIC_IP -}}
{{- end -}}
{{- $host }}
{{- end -}}

{{- define "seleniumGrid.url.port" -}}
{{- $port := ":4444" -}}
{{- if .Values.ingress.enabled -}}
  {{- if or (ne (.Values.ingress.ports.http | toString) "80") (ne (.Values.ingress.ports.https | toString) "443") -}}
    {{- $port = printf ":%s" (ternary (.Values.ingress.ports.http | toString) (.Values.ingress.ports.https | toString) (eq (include "seleniumGrid.url.schema" .) "http")) -}}
  {{- else -}}
    {{- $port = "" -}}
  {{- end -}}
{{- else -}}
  {{- if .Values.isolateComponents -}}
    {{- if and (eq .Values.components.router.serviceType "NodePort") .Values.components.router.nodePort -}}
      {{- $port = printf ":%s" (.Values.components.router.nodePort | toString) -}}
    {{- end -}}
  {{- else -}}
    {{- if and (eq .Values.hub.serviceType "NodePort") .Values.hub.nodePort -}}
      {{- $port = printf ":%s" (.Values.hub.nodePort | toString) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $port }}
{{- end -}}

{{- define "seleniumGrid.url.subPath" -}}
{{- $subPath := "" -}}
{{- if $.Values.isolateComponents -}}
  {{- $subPath = default $subPath $.Values.components.subPath -}}
{{- else -}}
  {{- $subPath = default $subPath $.Values.hub.subPath -}}
{{- end -}}
{{- $subPath }}
{{- end -}}

{{/*
Graphql Url of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL" -}}
{{- printf "%s://%s%s%s/graphql" (include "seleniumGrid.server.protocol" .) (include "seleniumGrid.url.basicAuth" .) (printf "%s.%s" (include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $) (.Release.Namespace)) (printf ":%s" ($.Values.isolateComponents | ternary ($.Values.components.router.port | toString) ($.Values.hub.port | toString))) -}}
{{- end -}}

{{/*
Graphql unsafeSsl of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL.unsafeSsl" -}}
{{- $unsafeSsl := printf "%s" (ternary "true" "false" .Values.serverConfigMap.disableHostnameVerification) -}}
{{- $unsafeSsl }}
{{- end -}}

{{/*
Define preStop hook for the node pod. Node preStop script is stored in a ConfigMap and mounted as a volume.
*/}}
{{- define "seleniumGrid.node.deregisterLifecycle" -}}
preStop:
  exec:
    command: ["bash", "-c", "/opt/selenium/{{ .Values.nodeConfigMap.preStopScript }}"]
{{- end -}}

{{/*
Get the lifecycle of the pod is used for a Node to deregister from the Hub/Router.
1. IF KEDA is activated, scalingType is "deployment", and individual node deregisterLifecycle is not set, use autoscaling.deregisterLifecycle
2. ELSE (KEDA is not activated and node deregisterLifecycle is set), use .deregisterLifecycle in individual node
3. IF individual node with .lifecycle is set, it takes highest precedence to override the preStop in above use cases
*/}}
{{- define "seleniumGrid.node.lifecycle" }}
{{- $defaultDeregisterLifecycle := tpl (include "seleniumGrid.node.deregisterLifecycle" .) $ -}}
{{- $lifecycle := toYaml (dict) -}}
{{- if and (and (eq .Values.autoscaling.scalingType "deployment") (eq (include "seleniumGrid.useKEDA" .) "true")) (empty .node.deregisterLifecycle) -}}
  {{- $lifecycle = merge ($lifecycle | fromYaml) (tpl (toYaml (default ($defaultDeregisterLifecycle | fromYaml) .Values.autoscaling.deregisterLifecycle)) $ | fromYaml) | toYaml -}}
{{- else -}}
  {{- if eq (.node.deregisterLifecycle | toString | lower) "false" -}}
    {{- $lifecycle = toYaml (dict) -}}
  {{- else -}}
    {{- $lifecycle = (tpl (toYaml (default ($defaultDeregisterLifecycle | fromYaml) .node.deregisterLifecycle) ) $ | fromYaml) | toYaml -}}
  {{- end -}}
{{- end -}}
{{- if not (empty .node.lifecycle) -}}
  {{- $lifecycle = mergeOverwrite ($lifecycle | fromYaml) (tpl (toYaml .node.lifecycle) $ | fromYaml) | toYaml -}}
{{- end -}}
{{ if and $lifecycle (ne $lifecycle "{}") -}}
lifecycle: {{ $lifecycle | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Define terminationGracePeriodSeconds of the node pod.
1. IF KEDA is activated, scalingType is "deployment", use autoscaling.terminationGracePeriodSeconds
2. IF node.terminationGracePeriodSeconds is greater than autoscaling.terminationGracePeriodSeconds, use node.terminationGracePeriodSeconds
*/}}
{{- define "seleniumGrid.node.terminationGracePeriodSeconds" -}}
{{- $autoscalingPeriod := default 0 .Values.autoscaling.terminationGracePeriodSeconds -}}
{{- $nodePeriod := default 0 .node.terminationGracePeriodSeconds -}}
{{- $period := $nodePeriod -}}
{{- if and (eq .Values.autoscaling.scalingType "deployment") (eq (include "seleniumGrid.useKEDA" .) "true") -}}
  {{- $period = ternary $nodePeriod $autoscalingPeriod (gt $nodePeriod $autoscalingPeriod) -}}
{{- end -}}
{{- $period -}}
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
