{% if cookiecutter.project_type == 'go-web' %}
package main

import (
	"log"
	"net/http"
	"os"

	"{{cookiecutter.go_module_path}}/internal/handler"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "{{cookiecutter.app_port}}"
	}

	mux := handler.New()

	log.Printf("{{cookiecutter.project_name}} listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
{% endif %}

{% if cookiecutter.project_type == 'go-desktop' %}
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Printf("{{cookiecutter.project_name}} (%s/%s)\n", runtime.GOOS, runtime.GOARCH)
	fmt.Printf("Version: %s\n", Version)
	fmt.Println()
	fmt.Println("{{cookiecutter.project_description}}")
}
{% endif %}
