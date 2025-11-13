using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHealthChecks();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Nomad .NET CRUD API", Version = "v1" });
});

// Add in-memory data store as a singleton
builder.Services.AddSingleton<ItemRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Nomad .NET CRUD API v1"));

// Define API endpoints
app.MapGet("/", () => "Nomad .NET CRUD API is running!");

app.MapGet("/api/items", (ItemRepository repo) => Results.Ok(repo.GetAll()))
    .WithName("GetAllItems")
    .WithSummary("Get all items")
    .WithDescription("Retrieves a list of all items in the repository")
    .Produces<IEnumerable<Item>>();

app.MapGet(
        "/api/items/{id}",
        (int id, ItemRepository repo) =>
        {
            var item = repo.GetById(id);
            return item is null ? Results.NotFound() : Results.Ok(item);
        }
    )
    .WithName("GetItemById")
    .WithSummary("Get item by ID")
    .WithDescription("Retrieves a specific item by its unique identifier")
    .Produces<Item>()
    .Produces(StatusCodes.Status404NotFound);

app.MapPost(
        "/api/items",
        (Item item, ItemRepository repo) =>
        {
            repo.Add(item);
            return Results.Created($"/api/items/{item.Id}", item);
        }
    )
    .WithName("CreateItem")
    .WithSummary("Create a new item")
    .WithDescription("Creates a new item and adds it to the repository")
    .Accepts<Item>("application/json")
    .Produces<Item>(StatusCodes.Status201Created);

app.MapPut(
        "/api/items/{id}",
        (int id, Item item, ItemRepository repo) =>
        {
            if (id != item.Id)
                return Results.BadRequest();

            var existingItem = repo.GetById(id);
            if (existingItem is null)
                return Results.NotFound();

            repo.Update(item);
            return Results.NoContent();
        }
    )
    .WithName("UpdateItem")
    .WithSummary("Update an existing item")
    .WithDescription("Updates an existing item with new values")
    .Accepts<Item>("application/json")
    .Produces(StatusCodes.Status204NoContent)
    .Produces(StatusCodes.Status400BadRequest)
    .Produces(StatusCodes.Status404NotFound);

app.MapDelete(
        "/api/items/{id}",
        (int id, ItemRepository repo) =>
        {
            var existingItem = repo.GetById(id);
            if (existingItem is null)
                return Results.NotFound();

            repo.Delete(id);
            return Results.NoContent();
        }
    )
    .WithName("DeleteItem")
    .WithSummary("Delete an item")
    .WithDescription("Deletes an item from the repository by its ID")
    .Produces(StatusCodes.Status204NoContent)
    .Produces(StatusCodes.Status404NotFound);

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

// Data model
public class Item
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsComplete { get; set; }
}

// In-memory repository
public class ItemRepository
{
    private readonly List<Item> _items = new();
    private int _nextId = 1;

    public IEnumerable<Item> GetAll() => _items;

    public Item? GetById(int id) => _items.FirstOrDefault(i => i.Id == id);

    public void Add(Item item)
    {
        item.Id = _nextId++;
        _items.Add(item);
    }

    public void Update(Item item)
    {
        var index = _items.FindIndex(i => i.Id == item.Id);
        if (index != -1)
            _items[index] = item;
    }

    public void Delete(int id)
    {
        var index = _items.FindIndex(i => i.Id == id);
        if (index != -1)
            _items.RemoveAt(index);
    }
}
