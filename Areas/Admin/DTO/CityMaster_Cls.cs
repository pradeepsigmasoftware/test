using System.Data;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace Hotel.Areas.Admin.DTO
{
    public class CityMaster_Cls
    {
        public int Id { get; set; }
        public string Action { get; set; }
        public int StateId { get; set; }
        public string CityName { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime EntryDate { get; set; }
        public string UnitAbbr { get; set; }
        public DataTable dt { get; set; }

        public List<SelectListItem> CityMasterDDLLst = new List<SelectListItem>();
    }
}
