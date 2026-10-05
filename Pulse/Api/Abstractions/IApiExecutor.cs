using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace Pulse.Api.Abstractions;

public interface IApiExecutor
{
    Task<T> GetAsync<T>(string path, RequestPriority priority);
    Task<List<T>> GetAllPagesAsync<T>(string path, RequestPriority priority);

    Task<T> PostAsync<T>(string path, RequestPriority priority, object? body = null);

}
