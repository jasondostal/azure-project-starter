{% if cookiecutter.project_type == 'go-web' %}
package handler

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

// New returns a configured HTTP router.
func New() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RealIP)

	// Health check
	r.Get("/health", healthHandler)

	// Serve the embedded SPA (static/ directory)
	spa := spaHandler{root: http.Dir("static")}
	r.Get("/*", spa.ServeHTTP)

	return r
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "healthy",
		"app":         "{{cookiecutter.project_name}}",
		"environment": os.Getenv("ASPNETCORE_ENVIRONMENT"),
	})
}

// spaHandler serves static files, falling back to index.html for SPA routing.
type spaHandler struct {
	root http.FileSystem
}

func (s *spaHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	// Try static file first
	f, err := s.root.Open(path)
	if err == nil {
		f.Close()
		http.FileServer(s.root).ServeHTTP(w, r)
		return
	}

	// Fall back to index.html (client-side routing)
	http.ServeFile(w, r, "static/index.html")
}
{% endif %}

{% if cookiecutter.project_type == 'go-desktop' %}
package handler

// Empty — desktop binaries don't serve HTTP.
// Command-line entrypoint is in cmd/app/main.go.
{% endif %}
