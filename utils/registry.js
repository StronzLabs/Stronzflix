export class Registry
{
    items = {};
    
    register(instance, name)
    {
        this.items[name] = instance;
    }
    
    get(name)
    {
        return this.items[name];
    }
}

