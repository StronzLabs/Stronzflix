namespace Stronzflix.Utils
{
    public abstract class Registry<T>
    {
        private readonly Dictionary<string, T> items = new Dictionary<string, T>();

        public void Register(T reg, string name) => this.items.Add(name, reg);
        public T Get(string name) => this.items[name];
    }
}
