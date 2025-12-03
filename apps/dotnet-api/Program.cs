using Microsoft.OpenApi.Models;
using NomadDotnetApi.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHealthChecks();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Nomad .NET CRUD API", Version = "v1" });
});

// Add in-memory data store as a singleton
builder.Services.AddSingleton<NomadDotnetApi.Data.ItemRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Nomad .NET CRUD API v1"));

// Map controller routes
app.MapControllers();

// Define simple endpoints
app.MapGet("/", () => "Nomad .NET CRUD API is running!");

// Add a health check endpoint
app.MapHealthChecks("/health");

// Add system info endpoint
app.MapGet(
    "/info",
    () =>
        Results.Ok(
            new
            {
                hostname = Environment.MachineName,
                os = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
                framework = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                environment = app.Environment.EnvironmentName,
                processId = System.Diagnostics.Process.GetCurrentProcess().Id,
            }
        )
);

// Run the app
var port = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "8080");
app.Run($"http://0.0.0.0:{port}");
