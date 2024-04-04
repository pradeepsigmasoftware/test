using Hotel.Areas.Unit.DTO;
using Hotel.Areas.Unit.Models.Services.Home;
using Hotel.Models;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel;

namespace Hotel.ViewComponents
{
    public class CheckInRoomDetailsViewComponent : ViewComponent
    {
       // @await Component.InvokeAsync("Menu")
        private readonly IUnitHome _IUnitHome;
        public CheckInRoomDetailsViewComponent(IUnitHome IUnitHome)
        {
            _IUnitHome = IUnitHome;
        }

        public Task<IViewComponentResult> InvokeAsync(UnitHomeViewModel Request)
        {
            var user = new CustomPrincipal(HttpContext.User);

            if (user.IsAuthenticated)
            {

                Request.HotelId = user.HotelId;

                Request.Action = "checkIn";
                Request.Table1 = _IUnitHome.USP_UnitHome(Request);
            }

            return System.Threading.Tasks.Task.FromResult<IViewComponentResult>(View("~/Views/Shared/Components/CheckInRoomDetails/Default.cshtml", Request));
        }
    }

}
