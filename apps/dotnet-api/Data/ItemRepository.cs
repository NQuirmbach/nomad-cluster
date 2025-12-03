namespace NomadDotnetApi.Data;

public class ItemRepository
{
    private readonly List<Models.Item> _items = new();
    private int _nextId = 1;

    public IEnumerable<Models.Item> GetAll() => _items;

    public Models.Item? GetById(int id) => _items.FirstOrDefault(i => i.Id == id);

    public void Add(Models.Item item)
    {
        item.Id = _nextId++;
        _items.Add(item);
    }

    public void Update(Models.Item item)
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
