using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Hotel.Models
{
    public class SiteKeys
    {
        private static IConfigurationSection _configuration;
        
        public static void Configure(IConfigurationSection configuration)
        {
            _configuration = configuration;
            
        }
        public static string SmtpServer => _configuration["SmtpServer"];

        public static string SMTPUserName => _configuration["SMTPUserName"];

        public static string SMTPUserPassword => _configuration["SMTPUserPassword"];

        public static string SmtpPort => _configuration["SmtpPort"];

        public static string Domain => _configuration["Domain"];
        public static string DisplayDateFormat => _configuration["DisplayDateFormat"];

        public static string MailFromEmail => _configuration["MailFromEmail"];

        public static string MailBCC => _configuration["MailBCC"];

        public static string MailFromName => _configuration["MailFromName"];

        public static string Keys90APIURL => _configuration["Keys90APIURL"];
    }
}
