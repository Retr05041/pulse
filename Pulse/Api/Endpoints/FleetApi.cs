using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Pulse.Api.Abstractions;

namespace Pulse.Api.Endpoints;

public class FleetApi
{
    private readonly IApiExecutor _api; // Gives access to the ApiExecutor functions init in Abstractions/ApiExecutor and defined in SpaceTradersClient

    internal FleetApi(IApiExecutor api) => _api = api;

    public Task<List<Ship>> GetShipsAsync(RequestPriority p = RequestPriority.Interactive)
        => _api.GetAllPagesAsync<Ship>("my/ships", p);

}
