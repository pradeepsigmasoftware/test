using System.Data;

namespace Hotel.Areas.Admin.DTO
{
    public class HotelImageMaster_Cls
    {
        public int Id { get; set; }
        public string ImagePath { get; set; }
        public IFormFile Image { get; set; }
        public DateTime EntryDate { get; set; }
        public bool IsActive { get; set; }
        public string HotelId { get; set; }
        public string ImgExt { get; set; }
        public string Action { get; set; }
        public DataTable dt { get; set; }
    }
}
