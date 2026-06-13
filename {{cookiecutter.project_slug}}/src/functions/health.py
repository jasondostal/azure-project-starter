"""{{cookiecutter.project_name}} — Health check endpoint."""
import json
import os
import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        body=json.dumps({
            "status": "healthy",
            "app": "{{cookiecutter.project_name}}",
            "environment": os.getenv("FUNCTIONS_ENVIRONMENT", "local"),
        }),
        status_code=200,
        mimetype="application/json",
    )
