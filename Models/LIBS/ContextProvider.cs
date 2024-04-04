using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;


public class ContextProvider
{
    private static IHttpContextAccessor _httpContextAccessor;
    private static IWebHostEnvironment _hostingEnvironment;

    public static void Configure(
        IHttpContextAccessor httpContextAccessor,
        IWebHostEnvironment hostingEnvironment)
    {
        _httpContextAccessor = httpContextAccessor;
        _hostingEnvironment = hostingEnvironment;
    }

    public static HttpContext HttpContext
    {
        get
        {
            return _httpContextAccessor.HttpContext;
        }
    }

    public static HttpContext Current
    {
        get
        {
            return _httpContextAccessor.HttpContext;
        }
    }
    public static Uri AbsoluteUri
    {
        get
        {
            var request = _httpContextAccessor.HttpContext.Request;
            UriBuilder uriBuilder = new UriBuilder();
            if (request.Host.Port.HasValue) // Port no. is there in case of local host
            {

                uriBuilder.Scheme = request.Scheme;
                uriBuilder.Host = request.Host.Host;
                uriBuilder.Path = request.Path.ToString();
                uriBuilder.Port = (int)request.Host.Port;
                uriBuilder.Query = request.QueryString.ToString();

            }
            else // live
            {

                uriBuilder.Scheme = request.Scheme;
                uriBuilder.Host = request.Host.Host;
                uriBuilder.Path = string.Format("{0}{1}", request.PathBase, request.Path).Trim();
                uriBuilder.Query = request.QueryString.ToString();

            }

            return uriBuilder.Uri;
        }
    }

    public static IWebHostEnvironment HostEnvironment
    {
        get
        {
            return _hostingEnvironment;
        }
    }
}