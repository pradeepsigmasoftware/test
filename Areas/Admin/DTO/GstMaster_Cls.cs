using System.Data;

namespace Hotel.Areas.Admin.DTO
{
    public class GstMaster_Cls
    {
        public string Action { get; set; }
        public int GSTID { get; set; }
        public decimal? StartAmt { get; set; }
        public decimal? EndAmt { get; set; }
        public decimal? GSTPer { get; set; }
        public DataTable dt { get; set; }
    }
}
