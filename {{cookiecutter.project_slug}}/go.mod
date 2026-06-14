module {{cookiecutter.go_module_path}}

go 1.23

{% if cookiecutter.project_type == 'go-web' %}
require (
	github.com/go-chi/chi/v5 v5.1.0
)
{% endif %}
