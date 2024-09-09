{{/*
Server secure connection
*/}}
{{- define "seleniumGrid.server.secureConnection" -}}
{{- $.Values.tls.enabled | ternary "true" "" -}}
{{- end -}}

{{/*
Ingress proxy forward secure connection
*/}}
{{- define "seleniumGrid.ingress.secureConnection" -}}
{{- or $.Values.tls.enabled $.Values.tls.ingress.enabled $.Values.tls.ingress.generateTLS (not (empty $.Values.ingress.tls)) | ternary "true" "" -}}
{{- end -}}

{{/*
Protocol of server components
*/}}
{{- define "seleniumGrid.server.protocol" -}}
{{- (eq (include "seleniumGrid.server.secureConnection" $) "true") | ternary "https" "http" -}}
{{- end -}}

{{/*
Probe httpGet schema
*/}}
{{- define "seleniumGrid.probe.httpGet.schema" -}}
{{- (eq (include "seleniumGrid.server.secureConnection" $) "true") | ternary "HTTPS" "HTTP" -}}
{{- end -}}

{{/*
Check user define custom probe method
*/}}
{{- define "seleniumGrid.probe.fromUserDefine" -}}
{{- $values := index . "values" -}}
{{- $root := index . "root" -}}
{{- $overrideProbe := dict -}}
{{- with $values.exec -}}
{{- $overrideProbe = dict "exec" (tpl (toYaml .) $root | fromYaml) -}}
{{- end }}
{{- with $values.httpGet -}}
{{- $overrideProbe = dict "httpGet" (tpl (toYaml .) $root | fromYaml) -}}
{{- end }}
{{- with $values.tcpSocket -}}
{{- $overrideProbe = dict "tcpSocket" (tpl (toYaml .) $root | fromYaml) -}}
{{- end }}
{{- with $values.grpc -}}
{{- $overrideProbe = dict "grpc" (tpl (toYaml .) $root | fromYaml) -}}
{{- end -}}
{{- $overrideProbe | toYaml -}}
{{- end -}}

{{- define "seleniumGrid.probe.stdout" -}}
{{- $stdout := "" -}}
{{- if .Values.global.seleniumGrid.stdoutProbeLog -}}
  {{- $stdout = ">> /proc/1/fd/1" -}}
{{- end -}}
{{- $stdout -}}
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
Is registration secret enabled
*/}}
{{- define "seleniumGrid.registrationSecret.enabled" -}}
{{- .Values.registrationSecret.enabled | ternary "true" "" -}}
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

{{- define "seleniumGrid.ingress.nginx.annotations.default" -}}
{{- with .Values.ingress.nginx }}
  {{- with .proxyTimeout }}
nginx.ingress.kubernetes.io/proxy-connect-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-send-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-read-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/proxy-stream-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/upstream-keepalive-timeout: {{ . | quote }}
nginx.ingress.kubernetes.io/ssl-session-timeout: {{ . | quote }}
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
  {{- if .websocket }}
nginx.org/websocket-services: {{ include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ | quote }}
  {{- end }}
  {{- if eq (include "seleniumGrid.server.secureConnection" $) "true" }}
    {{- if .sslPassthrough }}
nginx.ingress.kubernetes.io/ssl-passthrough: "true"
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    {{- end }}
  {{- end }}
  {{- if eq (include "seleniumGrid.ingress.secureConnection" $) "true" }}
nginx.ingress.kubernetes.io/use-http2: {{ .useHttp2 | quote }}
    {{- if not (empty .sslSecret) }}
nginx.ingress.kubernetes.io/proxy-ssl-secret: {{ tpl .sslSecret $ | quote }}
    {{- else if (empty $.Values.ingress.tls) }}
nginx.ingress.kubernetes.io/proxy-ssl-secret: {{ tpl (printf "%s/%s" $.Release.Namespace (include "seleniumGrid.tls.fullname" $)) $ | quote }}
    {{- else }}
nginx.ingress.kubernetes.io/proxy-ssl-secret: {{ tpl (printf "%s/%s" $.Release.Namespace (index $.Values.ingress.tls 0).secretName) $ | quote }}
    {{- end }}
  {{- end }}
  {{- with .upstreamKeepalive }}
    {{- with .connections }}
nginx.ingress.kubernetes.io/upstream-keepalive-connections: {{ . | quote }}
    {{- end }}
    {{- with .requests }}
nginx.ingress.kubernetes.io/upstream-keepalive-request: {{ . | quote }}
    {{- end }}
    {{- with .time }}
nginx.ingress.kubernetes.io/upstream-keepalive-time: {{ . | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Is autoscaling using KEDA enabled
*/}}
{{- define "seleniumGrid.useKEDA" -}}
{{- or .Values.autoscaling.enabled .Values.autoscaling.enableWithExistingKEDA | ternary "true" "" -}}
{{- end -}}

{{/*
Is ingress enabled
*/}}
{{- define "seleniumGrid.ingress.enabled" -}}
{{- or .Values.ingress.enabled .Values.ingress.enableWithController | ternary "true" "" -}}
{{- end -}}

{{/*
Is ingress enabled
*/}}
{{- define "seleniumGrid.monitoring.enabled" -}}
{{- or .Values.monitoring.enabled .Values.monitoring.enabledWithExistingAgent | ternary "true" "" -}}
{{- end -}}

{{/*
Is tracing enabled
*/}}
{{- define "seleniumGrid.enableTracing" -}}
{{- or .Values.tracing.enabled .Values.tracing.enabledWithExistingEndpoint | ternary "true" "" -}}
{{- end -}}

{{/*
Configure fixed-sized thread pool for the Distributor to create new sessions
based on sum of maxReplicaCount of all enabled Nodes in autoscaling
*/}}
{{- define "seleniumGrid.autoscaling.distributor.threadPoolSize" -}}
{{- $threadPoolSize := 1 -}}
{{- if .Values.chromeNode.enabled -}}
{{- $maxReplicaCount := default .Values.autoscaling.scaledOptions.maxReplicaCount (.Values.chromeNode.scaledOptions).maxReplicaCount -}}
{{- $threadPoolSize = add $threadPoolSize $maxReplicaCount -}}
{{- end -}}
{{- if $.Values.firefoxNode.enabled -}}
{{- $maxReplicaCount := default .Values.autoscaling.scaledOptions.maxReplicaCount (.Values.firefoxNode.scaledOptions).maxReplicaCount -}}
{{- $threadPoolSize = add $threadPoolSize $maxReplicaCount -}}
{{- end -}}
{{- if $.Values.edgeNode.enabled -}}
{{- $maxReplicaCount := default .Values.autoscaling.scaledOptions.maxReplicaCount (.Values.edgeNode.scaledOptions).maxReplicaCount -}}
{{- $threadPoolSize = add $threadPoolSize $maxReplicaCount -}}
{{- end -}}
{{- $threadPoolSize -}}
{{- end -}}

{{/*
Common autoscaling spec template
*/}}
{{- define "seleniumGrid.autoscalingTemplate" -}}
{{- $spec := toYaml (dict) -}}
{{/* Merge with precedence from right to left */}}
{{- with $.Values.autoscaling.scaledOptions -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
{{- end -}}
{{- with .node.scaledOptions -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
{{- end -}}
{{- if eq $.Values.autoscaling.scalingType "deployment" -}}
  {{- with $.Values.autoscaling.scaledObjectOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- with .node.scaledObjectOptions -}}
    {{- $spec = mergeOverwrite ($spec | fromYaml) . | toYaml -}}
  {{- end -}}
  {{- $advanced := (dict "scaleTargetRef" (dict "name" .name) "advanced" (dict "horizontalPodAutoscalerConfig" (dict "name" .name) "restoreToOriginalReplicaCount" true)) -}}
  {{- $spec = mergeOverwrite ($spec | fromYaml) $advanced | toYaml -}}
{{- else if eq $.Values.autoscaling.scalingType "job" -}}
  {{- with $.Values.autoscaling.scaledJobOptions -}}
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
{{- if not $.Values.autoscaling.scaledOptions.triggers }}
triggers:
  - type: selenium-grid
    metadata:
      triggerIndex: '{{ default $.Values.autoscaling.scaledOptions.minReplicaCount (.node.scaledOptions).minReplicaCount }}'
  {{- with .node.hpa }}
    {{- tpl (toYaml .) $ | nindent 6 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Component update strategy template
*/}}
{{- define "seleniumGrid.updateStrategy" -}}
{{- $value := index . 0 -}}
{{- $global := index . 1 -}}
{{- $spec := toYaml (dict) -}}
{{- if not (empty $global.updateStrategy) -}}
{{- $spec = merge $global.updateStrategy ($spec | fromYaml) | toYaml -}}
{{- end -}}
{{- if not (empty $value.updateStrategy) -}}
{{- $spec = merge $value.updateStrategy ($spec | fromYaml) | toYaml -}}
{{- end -}}
{{/* If final result is Recreate, update a clean object */}}
{{- if eq ($spec | fromYaml).type "Recreate" }}
{{- $spec = toYaml (dict "type" "Recreate") -}}
{{- end -}}
{{ $spec | nindent 4 }}
{{- end -}}

{{/*
Common pod template
*/}}
{{- define "seleniumGrid.podTemplate" -}}
{{- $nodeImageRegistry := default $.Values.global.seleniumGrid.imageRegistry .node.imageRegistry -}}
{{- $nodeImageTag := default $.Values.global.seleniumGrid.nodesImageTag .node.imageTag -}}
{{- $videoImageRegistry := default $.Values.global.seleniumGrid.imageRegistry $.Values.videoRecorder.imageRegistry -}}
{{- $videoImageTag := default $.Values.global.seleniumGrid.videoImageTag $.Values.videoRecorder.imageTag -}}
template:
  metadata:
    labels:
      app: {{ .name }}
      app.kubernetes.io/name: {{ .name }}
      {{- include "seleniumGrid.commonLabels" . | nindent 6 }}
      {{- with .node.labels }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- with $.Values.customLabels }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
    annotations:
      checksum/event-bus-configmap: {{ include (print $.Template.BasePath "/event-bus-configmap.yaml") . | sha256sum }}
      checksum/node-configmap: {{ include (print $.Template.BasePath "/node-configmap.yaml") . | sha256sum }}
      checksum/logging-configmap: {{ include (print $.Template.BasePath "/logging-configmap.yaml") . | sha256sum }}
      checksum/server-configmap: {{ include (print $.Template.BasePath "/server-configmap.yaml") . | sha256sum }}
      {{- with .node.annotations }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
  spec:
    shareProcessNamespace: {{ $.Values.global.seleniumGrid.stdoutProbeLog | ternary "false" .node.shareProcessNamespace }}
    serviceAccountName: {{ template "seleniumGrid.serviceAccount.fullname" . }}
    serviceAccount: {{ template  "seleniumGrid.serviceAccount.fullname" . }}
    restartPolicy: {{ template "seleniumGrid.node.restartPolicy" . }}
  {{- with .node.hostAliases }}
    hostAliases: {{ toYaml . | nindent 6 }}
  {{- end }}
    initContainers:
      - name: "pre-puller-{{ .name }}"
        image: {{ printf "%s/%s:%s" $nodeImageRegistry .node.imageName $nodeImageTag }}
        command: ["bash", "-c", "'true'"]
    {{- if $.Values.videoRecorder.enabled }}
      - name: "pre-puller-{{ $.Values.videoRecorder.name }}"
        image: {{ printf "%s/%s:%s" $videoImageRegistry $.Values.videoRecorder.imageName $videoImageTag }}
        command: ["bash", "-c", "'true'"]
    {{- end }}
    {{- with .node.initContainers }}
      {{- toYaml . | nindent 6 }}
    {{- end }}
    containers:
      - name: {{ .name }}
        image: {{ printf "%s/%s:%s" $nodeImageRegistry .node.imageName $nodeImageTag }}
        imagePullPolicy: {{ .node.imagePullPolicy }}
        env:
          - name: SE_NODE_CONTAINER_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
        {{- if empty .node.dshmVolumeSizeLimit }}
          - name: SE_BROWSER_ARGS_DISABLE_DSHM
            value: "--disable-dev-shm-usage"
        {{- end }}
          - name: SE_OTEL_SERVICE_NAME
            value: {{ .name | quote }}
          - name: SE_NODE_PORT
            value: {{ .node.port | quote }}
        {{- with .node.startupProbe.timeoutSeconds }}
          - name: SE_NODE_REGISTER_PERIOD
            value: {{ . | quote }}
        {{- end }}
        {{- with .node.startupProbe.periodSeconds }}
          - name: SE_NODE_REGISTER_CYCLE
            value: {{ . | quote }}
        {{- end }}
        {{- with .node.extraEnvironmentVariables }}
          {{- tpl (toYaml .) $ | nindent 10 }}
        {{- end }}
        envFrom:
          - configMapRef:
              name: {{ template "seleniumGrid.eventBus.configmap.fullname" $ }}
          - configMapRef:
              name: {{ template "seleniumGrid.node.configmap.fullname" $ }}
          - configMapRef:
              name: {{ template "seleniumGrid.logging.configmap.fullname" $ }}
          - configMapRef:
              name: {{ template "seleniumGrid.server.configmap.fullname" $ }}
          - secretRef:
              name: {{ include "seleniumGrid.common.secrets.fullname" $ }}
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
        {{- if not (empty .node.dshmVolumeSizeLimit) }}
          - name: dshm
            mountPath: /dev/shm
        {{- end }}
        {{- range $fileName, $value := $.Values.nodeConfigMap.extraScripts }}
          - name: {{ tpl (default (include "seleniumGrid.node.configmap.fullname" $) $.Values.nodeConfigMap.scriptVolumeMountName) $ }}
            mountPath: {{ $.Values.nodeConfigMap.extraScriptsDirectory }}/{{ $fileName }}
            subPath: {{ $fileName }}
        {{- end }}
        {{- if eq (include "seleniumGrid.server.secureConnection" $) "true" }}
          - name: {{ include "seleniumGrid.tls.fullname" $ | quote }}
            mountPath: {{ $.Values.tls.certVolumeMountPath }}
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
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $)) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $) | nindent 10 }}
        {{- else if eq $.Values.global.seleniumGrid.defaultNodeStartupProbe "exec" }}
          exec:
            command: ["bash", "-c", "{{ $.Values.nodeConfigMap.extraScriptsDirectory }}/nodeProbe.sh Startup {{ include "seleniumGrid.probe.stdout" $ }}"]
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
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $)) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $) | nindent 12 }}
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
        {{- if (ne (include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $)) "{}") }}
          {{- include "seleniumGrid.probe.fromUserDefine" (dict "values" . "root" $) | nindent 10 }}
        {{- else if eq $.Values.global.seleniumGrid.defaultNodeLivenessProbe "exec" }}
          exec:
            command: ["bash", "-c", "{{ $.Values.nodeConfigMap.extraScriptsDirectory }}/nodeProbe.sh Liveness {{ include "seleniumGrid.probe.stdout" $ }}"]
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
    {{- if $.Values.videoRecorder.enabled }}
      - name: {{ $.Values.videoRecorder.name }}
        image: {{ printf "%s/%s:%s" $videoImageRegistry $.Values.videoRecorder.imageName $videoImageTag }}
        imagePullPolicy: {{ $.Values.videoRecorder.imagePullPolicy }}
        env:
        - name: SE_NODE_PORT
          value: {{ .node.port | quote }}
        - name: DISPLAY_CONTAINER_NAME
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
      {{- with $.Values.videoRecorder.extraEnvironmentVariables }}
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
        envFrom:
        - configMapRef:
            name: {{ template "seleniumGrid.eventBus.configmap.fullname" $ }}
        - configMapRef:
            name: {{ template "seleniumGrid.node.configmap.fullname" $ }}
        - configMapRef:
            name: {{ template "seleniumGrid.recorder.configmap.fullname" $ }}
        - configMapRef:
            name: {{ template "seleniumGrid.server.configmap.fullname" $ }}
        {{- if and $.Values.videoRecorder.uploader.enabled (empty $.Values.videoRecorder.uploader.name) }}
        - secretRef:
            name: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
        {{- end }}
      {{- with $.Values.videoRecorder.extraEnvFrom }}
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- if gt (len $.Values.videoRecorder.ports) 0 }}
        ports:
      {{- range $.Values.videoRecorder.ports }}
        - containerPort: {{ . }}
          protocol: TCP
      {{- end }}
      {{- end }}
        volumeMounts:
      {{- if not (empty .node.dshmVolumeSizeLimit) }}
        - name: dshm
          mountPath: /dev/shm
      {{- end }}
      {{- tpl (include "seleniumGrid.video.volumeMounts" .) $ | nindent 8 }}
      {{- with $.Values.videoRecorder.resources }}
        resources: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with $.Values.videoRecorder.securityContext }}
        securityContext: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with $.Values.videoRecorder.startupProbe }}
        startupProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with $.Values.videoRecorder.livenessProbe }}
        livenessProbe: {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with $.Values.videoRecorder.lifecycle }}
        lifecycle: {{- toYaml . | nindent 10 }}
      {{- end }}
    {{- if and $.Values.videoRecorder.uploader.enabled (not (empty $.Values.videoRecorder.uploader.name)) }}
      - name: {{ default "uploader" $.Values.videoRecorder.uploader.name }}
        {{- $imageTag := .uploader.imageTag }}
        {{- $imageRegistry := .uploader.imageRegistry }}
        image: {{ printf "%s/%s:%s" $imageRegistry .uploader.imageName $imageTag }}
        imagePullPolicy: {{ .uploader.imagePullPolicy }}
      {{- if .uploader.command }}
        command: {{- tpl (toYaml .uploader.command) $ | nindent 8 }}
      {{- else }}
        command: ["/bin/sh"]
      {{- end }}
      {{- if .uploader.args }}
        args: {{- tpl (toYaml .uploader.args) $ | nindent 8 }}
      {{- else }}
        args: ["-c", "{{ $.Values.recorderConfigMap.extraScriptsDirectory }}/{{ $.Values.videoRecorder.uploader.entryPointFileName }}"]
      {{- end }}
      {{- with .uploader.extraEnvironmentVariables }}
        env: {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
        envFrom:
          - configMapRef:
              name: {{ template "seleniumGrid.uploader.configmap.fullname" $ }}
          - secretRef:
              name: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
        {{- with .uploader.extraEnvFrom }}
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
  {{- if or $.Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
    imagePullSecrets:
      - name: {{ default $.Values.global.seleniumGrid.imagePullSecret .node.imagePullSecret }}
  {{- end }}
  {{- with .node.nodeSelector }}
    nodeSelector: {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- if or $.Values.global.seleniumGrid.affinity .node.affinity }}
    {{- $affinityYaml := default $.Values.global.seleniumGrid.affinity .node.affinity }}
    affinity: {{- toYaml $affinityYaml | nindent 6 }}
  {{- end }}
  {{- if or $.Values.global.seleniumGrid.topologySpreadConstraints .node.topologySpreadConstraints }}
    {{- $topologySpreadConstraints := default $.Values.global.seleniumGrid.topologySpreadConstraints .node.topologySpreadConstraints }}
    {{- $appName := .name }}
    topologySpreadConstraints:
    {{- range $constraint := $topologySpreadConstraints }}
      - {{ toYaml $constraint | nindent 8 | trim }}
      {{- if not $constraint.labelSelector }}
        labelSelector:
          matchLabels:
            app: {{ $appName }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- with .node.tolerations }}
    tolerations:
      {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .node.priorityClassName }}
    priorityClassName: {{ . }}
  {{- end }}
    terminationGracePeriodSeconds: {{ template "seleniumGrid.node.terminationGracePeriodSeconds" $ }}
    volumes:
      - name: {{ tpl (default (include "seleniumGrid.node.configmap.fullname" $) $.Values.nodeConfigMap.scriptVolumeMountName) $ }}
        configMap:
          name: {{ template "seleniumGrid.node.configmap.fullname" $ }}
          defaultMode: {{ $.Values.nodeConfigMap.defaultMode }}
      {{- if not (empty .node.dshmVolumeSizeLimit) }}
      - name: dshm
        emptyDir:
          medium: Memory
          sizeLimit: {{ .node.dshmVolumeSizeLimit }}
      {{- end }}
    {{- if eq (include "seleniumGrid.server.secureConnection" $) "true" }}
      - name: {{ include "seleniumGrid.tls.fullname" $ | quote }}
        secret:
          secretName: {{ include "seleniumGrid.tls.fullname" $ | quote }}
    {{- end }}
    {{- if .node.extraVolumes }}
      {{ tpl (toYaml .node.extraVolumes) $ | nindent 6 }}
    {{- end }}
    {{- if $.Values.videoRecorder.enabled }}
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

{{/*
Get the url of the grid server in the cluster
*/}}
{{- define "seleniumGrid.server.url" -}}
{{- $url := printf "%s://%s%s%s%s" (include "seleniumGrid.server.url.schema" .) (include "seleniumGrid.url.basicAuth" .) (include "seleniumGrid.server.url.host" .) (include "seleniumGrid.server.url.port" .) (include "seleniumGrid.url.subPath" .) -}}
{{- $url }}
{{- end -}}

{{/*
Graphql Url of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL" -}}
{{- printf "%s/graphql" (include "seleniumGrid.server.url" $) -}}
{{- end -}}

{{- define "seleniumGrid.url.schema" -}}
{{- $schema := "http" -}}
{{- if or (eq (include "seleniumGrid.server.secureConnection" $) "true") (eq (include "seleniumGrid.ingress.secureConnection" $) "true") -}}
  {{- $schema = "https" -}}
{{- end -}}
{{- $schema }}
{{- end -}}

{{- define "seleniumGrid.server.url.schema" -}}
{{- $schema := "http" -}}
{{- if eq (include "seleniumGrid.server.secureConnection" $) "true" -}}
  {{- $schema = "https" -}}
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
{{- if eq (include "seleniumGrid.ingress.enabled" $) "true" -}}
  {{- if and (not .Values.ingress.hostname) .Values.global.K8S_PUBLIC_IP -}}
    {{- $host = .Values.global.K8S_PUBLIC_IP -}}
  {{- else if and .Values.ingress.hostname (ne (tpl .Values.ingress.hostname $) "selenium-grid.local") -}}
    {{- $host = (tpl .Values.ingress.hostname $) -}}
  {{- end -}}
{{- else if .Values.global.K8S_PUBLIC_IP -}}
  {{- $host = .Values.global.K8S_PUBLIC_IP -}}
{{- end -}}
{{- $host }}
{{- end -}}

{{- define "seleniumGrid.server.url.host" -}}
{{- $host := printf "%s.%s" (include ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ ) (.Release.Namespace) -}}
{{- $host }}
{{- end -}}

{{- define "seleniumGrid.url.port" -}}
{{- $port := ":4444" -}}
{{- if eq (include "seleniumGrid.ingress.enabled" $) "true" -}}
  {{- if or (ne (.Values.ingress.ports.http | toString) "80") (ne (.Values.ingress.ports.https | toString) "443") -}}
    {{- $port = printf ":%s" (ternary (.Values.ingress.ports.http | toString) (.Values.ingress.ports.https | toString) (eq (include "seleniumGrid.url.schema" .) "http")) -}}
  {{- else if and .Values.ingress.hostname (eq (tpl .Values.ingress.hostname $) "selenium-grid.local") }}
    {{- $port = $port -}}
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

{{- define "seleniumGrid.server.url.port" -}}
{{- $port := ":4444" -}}
{{- if .Values.isolateComponents -}}
  {{- $port = printf ":%s" (.Values.components.router.port | toString) -}}
{{- else -}}
  {{- $port = printf ":%s" (.Values.hub.port | toString) -}}
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
{{- $subPath = include "utils.trimTrailingSlash" $subPath -}}
{{- $subPath }}
{{- end -}}

{{/*
Graphql unsafeSsl of the hub or the router
*/}}
{{- define "seleniumGrid.graphqlURL.unsafeSsl" -}}
{{- $unsafeSsl := printf "%s" (ternary "true" "false" .Values.tls.disableHostnameVerification) -}}
{{- $unsafeSsl }}
{{- end -}}

{{/*
Define preStop hook for the node pod. Node preStop script is stored in a ConfigMap and mounted as a volume.
*/}}
{{- define "seleniumGrid.node.deregisterLifecycle" -}}
preStop:
  exec:
    command: ["bash", "-c", "{{ $.Values.nodeConfigMap.extraScriptsDirectory }}/nodePreStop.sh {{ include "seleniumGrid.probe.stdout" $ }}"]
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
{{- if and (and (eq .Values.autoscaling.scalingType "deployment") (eq (include "seleniumGrid.useKEDA" .) "true")) (not .node.deregisterLifecycle) -}}
  {{- $lifecycle = merge ($lifecycle | fromYaml) (tpl (toYaml (default ($defaultDeregisterLifecycle | fromYaml) .Values.autoscaling.deregisterLifecycle)) $ | fromYaml) | toYaml -}}
{{- else -}}
  {{- if eq (.node.deregisterLifecycle | toString | lower) "false" -}}
    {{- $lifecycle = toYaml (dict) -}}
  {{- else -}}
    {{- $lifecycle = (tpl (toYaml (default ($defaultDeregisterLifecycle | fromYaml) .node.deregisterLifecycle) ) $ | fromYaml) | toYaml -}}
  {{- end -}}
{{- end -}}
{{- if not .node.lifecycle -}}
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
{{- if and (eq .Values.autoscaling.scalingType "deployment") (eq (include "seleniumGrid.useKEDA" $) "true") -}}
  {{- $period = ternary $nodePeriod $autoscalingPeriod (gt $nodePeriod $autoscalingPeriod) -}}
{{- else if and (eq .Values.autoscaling.scalingType "job") (eq (include "seleniumGrid.useKEDA" $) "true") }}
  {{- $period = 30 -}}
{{- end -}}
{{- $period -}}
{{- end -}}

{{- define "seleniumGrid.node.restartPolicy" -}}
{{- $restartPolicy := "Always" -}}
{{- if and (eq (include "seleniumGrid.useKEDA" .) "true") (eq .Values.autoscaling.scalingType "job") -}}
  {{- $restartPolicy = "Never" -}}
{{- end -}}
{{- $restartPolicy -}}
{{- end -}}

{{- define "seleniumGrid.video.volumeMounts.default" -}}
{{- range $fileName, $value := .Values.recorderConfigMap.extraScripts }}
- name: {{ tpl (default (include "seleniumGrid.recorder.configmap.fullname" $) $.Values.recorderConfigMap.scriptVolumeMountName) $ }}
  mountPath: {{ $.Values.recorderConfigMap.extraScriptsDirectory }}/{{ $fileName }}
  subPath: {{ $fileName }}
{{- end }}
{{- if and $.Values.videoRecorder.uploader.enabled (empty $.Values.videoRecorder.uploader.name) }}
{{- range $fileName, $value := .Values.uploaderConfigMap.secretFiles }}
- name: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
  mountPath: {{ $.Values.uploaderConfigMap.extraScriptsDirectory }}/{{ $fileName }}
  subPath: {{ $fileName }}
{{- end }}
{{- end }}
- name: {{ tpl (toYaml $.Values.recorderConfigMap.videoVolumeMountName) $ }}
  mountPath: {{ $.Values.videoRecorder.targetFolder }}
{{- end -}}

{{- define "seleniumGrid.video.volumes.default" -}}
- name: {{ tpl (toYaml $.Values.recorderConfigMap.videoVolumeMountName) $ }}
  emptyDir: {}
- name: {{ tpl (default (include "seleniumGrid.recorder.configmap.fullname" $) $.Values.recorderConfigMap.scriptVolumeMountName) $ }}
  configMap:
    name: {{ template "seleniumGrid.recorder.configmap.fullname" $ }}
    defaultMode: {{ $.Values.recorderConfigMap.defaultMode }}
- name: {{ tpl (default (include "seleniumGrid.uploader.configmap.fullname" $) $.Values.uploaderConfigMap.scriptVolumeMountName) $ }}
  configMap:
    name: {{ template "seleniumGrid.uploader.configmap.fullname" $ }}
    defaultMode: {{ $.Values.uploaderConfigMap.defaultMode }}
- name: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
  secret:
    secretName: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
{{- end -}}

{{- define "seleniumGrid.video.uploader.volumeMounts.default" -}}
{{- range $fileName, $value := .Values.uploaderConfigMap.extraScripts }}
- name: {{ tpl (default (include "seleniumGrid.uploader.configmap.fullname" $) $.Values.uploaderConfigMap.scriptVolumeMountName) $ }}
  mountPath: {{ $.Values.uploaderConfigMap.extraScriptsDirectory }}/{{ $fileName }}
  subPath: {{ $fileName }}
{{- end }}
{{- range $fileName, $value := .Values.uploaderConfigMap.secretFiles }}
- name: {{ tpl (default (include "seleniumGrid.common.secrets.fullname" $) $.Values.uploaderConfigMap.secretVolumeMountName) $ }}
  mountPath: {{ $.Values.uploaderConfigMap.extraScriptsDirectory }}/{{ $fileName }}
  subPath: {{ $fileName }}
{{- end }}
- name: {{ tpl (toYaml $.Values.recorderConfigMap.videoVolumeMountName) $ }}
  mountPath: {{ $.Values.videoRecorder.targetFolder }}
{{- end -}}

{{/* Combine videoRecorder.extraVolumeMounts with the default ones for container video recorder */}}
{{- define "seleniumGrid.video.volumeMounts" -}}
{{- $videoVolumeMounts := list -}}
{{- if .Values.videoRecorder.extraVolumeMounts -}}
  {{- range .Values.videoRecorder.extraVolumeMounts -}}
    {{- $videoVolumeMounts = append $videoVolumeMounts . -}}
  {{- end -}}
{{- end -}}
{{- $defaultVolumeMounts := (include "seleniumGrid.video.volumeMounts.default" $ | toString | fromYamlArray ) -}}
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

{{- define "utils.trimTrailingSlash" -}}
{{- $path := . -}}
{{- if hasSuffix "/" $path -}}
  {{- $path = trimSuffix "/" $path -}}
{{- end -}}
{{- $path -}}
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
