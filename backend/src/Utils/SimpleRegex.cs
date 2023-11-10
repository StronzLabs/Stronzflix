using System.Text.RegularExpressions;

namespace Stronzflix.Utils
{
    public static class SimpleRegex
    {
        public static string Search(string pattern, string input)
        {
            Match match = Regex.Match(input, pattern);
            if (match.Success)
                return match.Groups[1].Value;
            return null;
        }
    }
}
