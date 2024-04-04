using System.Data;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace Hotel.Areas.Admin.DTO
{
    public class StateMaster_Cls
    {
        public int StateId { get; set; }
        public string StateName { get; set; }
        public string StateCode { get; set; }
        public DateTime EntryDate { get; set; }
        public int DeleteStatus { get; set; }
        public DataTable dt { get; set; }
        public string Action { get; set; }

        public List<SelectListItem> StateMasterDDLLst = new List<SelectListItem>();

    }
}
