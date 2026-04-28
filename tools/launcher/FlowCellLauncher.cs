using System;
using System.Diagnostics;
using System.IO;

internal static class FlowCellLauncher
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            var root = AppDomain.CurrentDomain.BaseDirectory;
            var wrapperPath = Path.Combine(root, "FlowCell", "run_hidden.vbs");
            if (!File.Exists(wrapperPath))
            {
                return 1;
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "System32", "wscript.exe"),
                Arguments = Quote(wrapperPath) + BuildArgumentString(args),
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                WorkingDirectory = root
            };

            Process.Start(startInfo);
            return 0;
        }
        catch
        {
            return 1;
        }
    }

    private static string BuildArgumentString(string[] args)
    {
        if (args == null || args.Length == 0)
        {
            return string.Empty;
        }

        var parts = new string[args.Length];
        for (var i = 0; i < args.Length; i++)
        {
            parts[i] = Quote(args[i] ?? string.Empty);
        }

        return " " + string.Join(" ", parts);
    }

    private static string Quote(string value)
    {
        return "\"" + (value ?? string.Empty).Replace("\"", "\\\"") + "\"";
    }
}
