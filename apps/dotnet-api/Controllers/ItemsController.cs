using Microsoft.AspNetCore.Mvc;
using NomadDotnetApi.Data;
using NomadDotnetApi.Models;

namespace NomadDotnetApi.Controllers;

[ApiController]
[Route("api/items")]
public class ItemsController : ControllerBase
{
    private readonly ItemRepository _repository;

    public ItemsController(ItemRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<Item>), StatusCodes.Status200OK)]
    public IActionResult GetAllItems()
    {
        return Ok(_repository.GetAll());
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(Item), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult GetItemById(int id)
    {
        var item = _repository.GetById(id);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost]
    [ProducesResponseType(typeof(Item), StatusCodes.Status201Created)]
    public IActionResult CreateItem([FromBody] Item item)
    {
        _repository.Add(item);
        return Created($"/api/items/{item.Id}", item);
    }

    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult UpdateItem(int id, [FromBody] Item item)
    {
        if (id != item.Id)
            return BadRequest();

        var existingItem = _repository.GetById(id);
        if (existingItem is null)
            return NotFound();

        _repository.Update(item);
        return NoContent();
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult DeleteItem(int id)
    {
        var existingItem = _repository.GetById(id);
        if (existingItem is null)
            return NotFound();

        _repository.Delete(id);
        return NoContent();
    }
}
