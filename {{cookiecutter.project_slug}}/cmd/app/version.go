{% if cookiecutter.project_type == 'go-desktop' %}
package main

// Version is set at build time via ldflags.
var Version = "dev"
{% endif %}
