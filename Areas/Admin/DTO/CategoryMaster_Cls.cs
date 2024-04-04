using System.Data;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace Hotel.Areas.Admin.DTO
{
    public class CategoryMaster_Cls
    {
        public int Id { get; set; }
        public string Category { get; set; }
        public bool IsActive { get; set; }
        public DateTime EntryDate { get; set; }
        public string HotelId { get; set; }
        public string HotelName { get; set; }
        public string CityName { get; set; }
        public int CityId { get; set; }
        public string Address { get; set; }
        public string MMTCategoryCode { get; set; }
        public string MMTHotelCode { get; set; }
        public string IRCTcHotelCode { get; set; }
        public string IRCTCCategoryCode { get; set; }
        public bool IsOffline { get; set; }
        public int bed_id { get; set; }

        public string Action { get; set; }
        public DataTable dt {  get; set; }
        public DataTable dt2 { get; set; }

		public List<SelectListItem> CategoryDDLList = new List<SelectListItem>();

	}
}
