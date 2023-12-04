<?xml version="1.0" ?>
<testsuites name="trivy">
{{- range . -}}
{{- $failures := len .Vulnerabilities }}
    <testsuite tests="{{ $failures }}" failures="{{ $failures }}" name="{{  .Target }}" errors="0" skipped="0" time="">
    {{- if not (eq .Type "") }}
        <properties>
            <property name="type" value="{{ .Type }}"></property>
        </properties>
        {{- end -}}
        {{ range .Vulnerabilities }}
        <testcase classname="{{ .PkgName }}-{{ .InstalledVersion }}" file="{{ if .FixedVersion -}} Upgrade to {{ .FixedVersion }} {{- else -}} No solution provided  {{- end }}" name="[{{ .Vulnerability.Severity }}] {{ .VulnerabilityID }}" time="">
            <{{ if not .FixedVersion -}}passed{{- else if (eq .Vulnerability.Severity "CRITICAL") -}}failure{{- else if (eq .Vulnerability.Severity "HIGH") -}}error{{- else -}}skipped{{- end }}  message="{{ escapeXML .Title }}" type="description">Upgrade {{ .PkgName }} to {{ .FixedVersion }} - {{ escapeXML .Description }}</{{ if not .FixedVersion -}}passed{{- else if (eq .Vulnerability.Severity "CRITICAL") -}}failure{{- else if (eq .Vulnerability.Severity "HIGH") -}}error{{- else -}}skipped{{- end }}>
        </testcase>
    {{- end }}
    </testsuite>
{{- $failures := len .Misconfigurations }}
    <testsuite tests="{{ $failures }}" failures="{{ $failures }}" name="{{  .Target }}" errors="0" skipped="0" time="">
    {{- if not (eq .Type "") }}
        <properties>
            <property name="type" value="{{ .Type }}"></property>
        </properties>
        {{- end -}}
        {{ range .Misconfigurations }}
        <testcase classname="{{ .Type }}" name="[{{ .Severity }}] {{ .ID }}" time="">
            <error message="{{ escapeXML .Title }}" type="description">{{ escapeXML .Description }}</error>
        </testcase>
    {{- end }}
    </testsuite>
{{- end }}
</testsuites>