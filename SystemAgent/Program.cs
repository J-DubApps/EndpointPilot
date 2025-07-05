using EndpointPilot.SystemAgent;
using Serilog;

// Configure the logger
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    // Write to a rolling file in a secure, system-wide location
    .WriteTo.File(
        path: @"C:\ProgramData\EndpointPilot\Agent.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 7,
        shared: true,
        flushToDiskInterval: TimeSpan.FromSeconds(1))
    // Write to the Windows Event Log
    .WriteTo.EventLog(
        source: "EndpointPilot System Agent",
        manageEventSource: true)
    .CreateLogger();

try
{
    Log.Information("Starting EndpointPilot System Agent host.");

    IHost host = Host.CreateDefaultBuilder(args)
        .UseWindowsService(options =>
        {
            options.ServiceName = "EndpointPilot System Agent";
        })
        .ConfigureServices(services =>
        {
            services.AddHostedService<AgentWorker>();
        })
        .UseSerilog()
        .Build();

    await host.RunAsync();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Host terminated unexpectedly.");
}
finally
{
    Log.CloseAndFlush();
}