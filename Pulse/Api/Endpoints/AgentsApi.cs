using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Pulse.Api.Abstractions;

namespace Pulse.Api.Endpoints;

public class AgentsApi
{
    private readonly IApiExecutor _api; // Gives access to the ApiExecutor functions init in Abstractions/ApiExecutor and defined in SpaceTradersClient

    internal AgentsApi(IApiExecutor api) => _api = api;

    public Task<Agent> GetAgentAsync(RequestPriority p = RequestPriority.Interactive)
        => _api.GetAsync<Agent>("my/agent", p); // Wraps the data in the Agent Model, which will make an object and directly map the json to the arguments
}
