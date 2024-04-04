using System.Data;

namespace Hotel.Areas.Admin.DTO
{
	public class RateMaster_Cls
	{
        public int RateID { get; set; }
        public string HotelId { get; set; }
        public int CategoryId { get; set; }
        public decimal PricePerDay { get; set; }
        public decimal PriceDifference { get; set; }
        public decimal ExtraBedPercentage { get; set; }
        public string RateStartDate { get; set; }
        public string RateEndDate { get; set; }
        public bool IsActive { get; set; }
        public string EntryBy { get; set; }
        public string EntryDate { get; set; }
        public string Action { get; set; }
        public DataTable dt { get; set; }
    }
}
