using {{cookiecutter.project_slug}}.Services;

var builder = WebApplication.CreateBuilder(args);

// Managed identity auth — DefaultAzureCredential chains:
//   1. Environment (AZURE_CLIENT_ID + secret/cert)
//   2. Managed Identity (IMDS, works in App Service w/ system-assigned MI)
//   3. Azure CLI (local dev)
builder.Services.AddSingleton(new Azure.Identity.DefaultAzureCredential());

// Database (SQL Server via managed identity or connection string)
builder.Services.AddScoped<DatabaseService>();

// Controllers + OpenAPI
builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi();
app.MapControllers();

// Health check — simple, no DB dependency (k8s/App Service probe)
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.Run();
