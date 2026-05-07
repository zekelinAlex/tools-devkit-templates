using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization.Metadata;
using System.Text.RegularExpressions;


var json = "jsonarraystringwhithPrivilegeTypeandandLevel";

string fixedJson = Regex.Replace(json, @"(\w+):\s*(\w+)", "\"$1\": \"$2\"");

// `dotnet run --file` (single-file C# scripts) in .NET 10 SDK disables
// reflection-based JSON serialization by default to keep AOT-friendly defaults.
// Re-enable it explicitly so this script keeps working with `JsonSerializer.Deserialize<T>`.
var permissions = JsonSerializer.Deserialize<List<Privilege>>(fixedJson, new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true,
    TypeInfoResolver = new DefaultJsonTypeInfoResolver()
});

var filePath = Path.Combine(".", ".template.scripts", "privileges.xml");

using (var writer = new StreamWriter(filePath))
{
    foreach (var permission in permissions)
    {
        writer.WriteLine($"<RolePrivilege name=\"prv{permission.PrivilegeType}__entity-logical-name__\" level=\"{permission.Level}\" />");
    }
}

public class Privilege
{
    public string PrivilegeType { get; set; }
    public string Level { get; set; }
}
