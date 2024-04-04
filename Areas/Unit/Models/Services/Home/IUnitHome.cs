using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Unit.DTO;
using System.Data;

namespace Hotel.Areas.Unit.Models.Services.Home
{
    public interface IUnitHome
    {
        DataTable USP_UnitHome(UnitHomeViewModel Requist);
        DataTable USP_InsertCheckIn(UnitHomeViewModel request);
        DataTable GetManageBookingData(UnitHomeViewModel request);
    }
}
