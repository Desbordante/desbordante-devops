{{- define "helpers.list-env-variables" }}
{{- range $key, $val := .Values.env }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end }}
{{- range $k, $v := .Values.secrets }}

{{- range $key, $val := $v }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $k }}
      key: {{ $val }}
{{- end }}
{{- end }}
{{- end }}
