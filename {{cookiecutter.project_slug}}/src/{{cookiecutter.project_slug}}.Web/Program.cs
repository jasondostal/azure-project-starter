using {{cookiecutter.project_slug}}.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(new Azure.Identity.DefaultAzureCredential());
builder.Services.AddScoped<DatabaseService>();
builder.Services.AddRazorPages();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.Run();
