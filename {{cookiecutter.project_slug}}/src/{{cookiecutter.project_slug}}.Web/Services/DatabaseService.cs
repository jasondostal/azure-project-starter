namespace {{cookiecutter.project_slug}}.Services;

/// <summary>
/// Database service — placeholder. Replace with your actual data access layer.
/// Uses managed identity (DefaultAzureCredential) to obtain tokens for Azure SQL.
/// </summary>
public class DatabaseService
{
    private readonly IConfiguration _config;
    private readonly ILogger<DatabaseService> _logger;

    public DatabaseService(IConfiguration config, ILogger<DatabaseService> logger)
    {
        _config = config;
        _logger = logger;
    }

    /// <summary>
    /// Returns a health status. Replace with actual DB operations.
    /// </summary>
    public Task<bool> IsHealthyAsync()
    {
        // TODO: Replace with actual connection test
        _logger.LogInformation("Database health check — not yet wired");
        return Task.FromResult(true);
    }
}
