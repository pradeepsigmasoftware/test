using System.Data;
using System.Drawing;
using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace Hotel.Areas.Admin.DTO
{
    public class HotelDTO_Cls
    {
        public string Action { get; set; }
        public int Id { get; set; }

        public string HotelId { get; set; }

        public string HotelName { get; set; }

        public int StateId { get; set; }

        public int CityId { get; set; }

        public bool isOffline { get; set; }

        public string Address { get; set; }

        public string ContactNo { get; set; }

        public string Description { get; set; }

        public decimal? Longitude { get; set; }

        public decimal? Latitude { get; set; }

        public DateTime EntryDate { get; set; }

        public bool IsActive { get; set; }

        public string EmailId { get; set; }

        public string ImageURL { get; set; }
        public IFormFile Image { get; set; }
        public string Landline { get; set; }

        public string GSTNo { get; set; }

        public string HotalCodenew { get; set; }

        public string HotelName_City { get; set; }

        public int Counter_BillNo { get; set; }

        public string MMT_HotelCode { get; set; }

        public string MMT_AccessToken { get; set; }

        public int PatternID { get; set; }

        public string IRCTC_HotelCode { get; set; }

        public string FSSAINo { get; set; }

        public DateTime ValidDate { get; set; }

        public string HOtel_UrlNew { get; set; }
        public string RedirectURL { get; set; }
        public string AccessToken { get; set; }
        public int Category { get; set; }
        public int NoOfRooms { get; set; }		
		public DataTable dt { get; set; }

		public int convertToInt(object Val)
        {
            int Res = 0;
            int.TryParse(Val.ToString(), out Res);
            return Res;
        }

    }
}
