#r "System.Text.Json"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.RegularExpressions;


public class Parameter
{
    public string name { get; set; }
    public string type { get; set; }
    public string value { get; set; }
}

var json = "customcontrolparametersexample";

string fixedJson = Regex.Replace(json, @"(\w+):\s*([\w.]+)", "\"$1\": \"$2\"");

var entries = JsonSerializer.Deserialize<List<Parameter>>(fixedJson, new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true
});

var merged = new Parameter();
foreach (var entry in entries)
{
    if (!string.IsNullOrEmpty(entry.name)) merged.name = entry.name;
    if (!string.IsNullOrEmpty(entry.type)) merged.type = entry.type;
    if (!string.IsNullOrEmpty(entry.value)) merged.value = entry.value;
}

var filePath = ".\\.template.temp\\customcontrolparameters.xml";

var directoryPath = Path.GetDirectoryName(filePath);

if (!Directory.Exists(directoryPath))
{
    Directory.CreateDirectory(directoryPath);
}
using (var writer = new StreamWriter(filePath))
{
    writer.WriteLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
    writer.WriteLine("<parameters>");
    writer.WriteLine($"  <{merged.name} type=\"{merged.type}\">{merged.value}</{merged.name}>");
    writer.WriteLine("</parameters>");
}
