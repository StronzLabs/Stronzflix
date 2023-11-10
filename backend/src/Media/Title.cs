namespace Stronzflix.Media
{
    public class Title
    {
        public enum Kind
        {
            Movie,
            Series
        }

        public string Name { get; private set; }
        public Kind Type { get; private set; }

        public Title(string name, Kind type)
        {
            this.Name = name;
            this.Type = type;
        }
    }
}
