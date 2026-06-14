"""{{cookiecutter.project_name}} — Azure Functions v4 entry point (decorator model)."""
import json
import os

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint."""
    return func.HttpResponse(
        body=json.dumps({
            "status": "healthy",
            "app": "{{cookiecutter.project_name}}",
            "environment": os.getenv("FUNCTIONS_ENVIRONMENT", "local"),
        }),
        status_code=200,
        mimetype="application/json",
    )
