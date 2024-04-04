using System.Data;

namespace Hotel.Areas.Admin.DTO
{
	public class RoomImages_Cls
	{
        public int Id { get; set; }
        public string Action { get; set; }
        public string HotelId { get; set; }
        public int Category { get; set; }
        public string ImagePath { get; set; }
        public IFormFile Image { get; set; }
        public string ImageExt { get; set; }
        public DateTime EnteryDate { get; set; }
        public DataTable dt { get; set; }
    }
}
