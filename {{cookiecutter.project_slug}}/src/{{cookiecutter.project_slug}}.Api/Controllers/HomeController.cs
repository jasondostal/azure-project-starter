using Microsoft.AspNetCore.Mvc;

namespace {{cookiecutter.project_slug}}.Controllers;

/// <summary>
/// Placeholder controller — demonstrates the pattern.
/// Replace with your actual API endpoints.
/// </summary>
[ApiController]
[Route("[controller]")]
public class HomeController : ControllerBase
{
    private readonly Services.DatabaseService _db;

    public HomeController(Services.DatabaseService db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var healthy = await _db.IsHealthyAsync();
        return Ok(new
        {
            app = "{{cookiecutter.project_name}}",
            environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown",
            database = healthy ? "connected" : "unreachable"
        });
    }
}
