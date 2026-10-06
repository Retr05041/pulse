using Pulse.Api.Abstractions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pulse.Api.Endpoints;

public class ContractsApi
{
    private readonly IApiExecutor _api;

    internal ContractsApi(IApiExecutor api) => _api = api;

    public Task<List<Contract>> GetContractsAsync(RequestPriority p = RequestPriority.Interactive)
        => _api.GetAllPagesAsync<Contract>("my/contracts", p);

    public Task<Contract> AcceptContractAsync(string contractID, RequestPriority p = RequestPriority.Interactive)
        => _api.PostAsync<Contract>($"my/contracts/{contractID}/accept", p);

    public Task<Contract> FulfillContractAsync(string contractID, RequestPriority p = RequestPriority.Interactive)
        => _api.PostAsync<Contract>($"my/contracts/{contractID}/fulfill", p);

    public Task<Contract> NegotiateNewContractAsync(string shipSymbol, RequestPriority p = RequestPriority.Interactive)
        => _api.PostAsync<Contract>($"my/ships/{shipSymbol}/negotiate/contract", p);

    public Task<DeliverContractResponse> DeliverContractAsync(
            string contractID,
            string shipSymbol,
            string tradeSymbol,
            int units,
            RequestPriority p = RequestPriority.Interactive)
    {
        var body = new DeliverContractRequest(shipSymbol, tradeSymbol, units);

        // Single generic type T = DeliverContractResponse, passing body as third argument
        return _api.PostAsync<DeliverContractResponse>($"my/contracts/{contractID}/deliver", p, body);
    }
}
