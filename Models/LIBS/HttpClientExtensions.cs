
using Newtonsoft.Json;
using System;
using System.Net.Http;
using System.Threading.Tasks;


namespace Hotel.Models
{


    public static class HttpClientExtensions
    {
        public static async Task<HttpResponseMessage> GetAsyncJson(this HttpClient httpClient, string requestUri)
        {
            string completeUrl = SiteKeys.Keys90APIURL + requestUri;

            try
            {
                HttpResponseMessage response = await httpClient.GetAsync(completeUrl);
                return response;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Exception: {ex.Message}");
                throw;
            }
        }

        public static async Task<HttpResponseMessage> PostAsyncJson<T>(this HttpClient httpClient, string requestUri, T data)
        {
            HttpResponseMessage response = new HttpResponseMessage();

            string json = JsonConvert.SerializeObject(data);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
            string completeUrl = SiteKeys.Keys90APIURL + requestUri;
            response = await httpClient.PostAsync(completeUrl, content);

            // Add any additional logic as needed

            return response;
        }

    }


}
