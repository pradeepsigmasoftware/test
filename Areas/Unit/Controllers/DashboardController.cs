using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Admin.Models.Services.Booking;
using Hotel.Areas.Unit.DTO;
using Hotel.Areas.Unit.Models.Services.Home;
using Hotel.Controllers;
using Hotel.data;
using Hotel.Models;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Data;

namespace Hotel.Areas.Unit.Controllers
{
    [Area("Unit")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "Hotel")]
    public class DashboardController : BaseController
    {
        private readonly IUnitHome _IUnitHome;
        public DashboardController(IUnitHome IUnitHome)
        {
            _IUnitHome = IUnitHome;
        }
        public async Task<IActionResult> Index()
        {
            return View();
        }
        public async Task<IActionResult> Home(UnitHomeViewModel Request)
        {

            Request.HotelId = CurrentUser.HotelId;

            Request.Action = "checkIn";
            Request.Table1 = _IUnitHome.USP_UnitHome(Request);

            Request.Action = "checkedIn";
            Request.Table2 = _IUnitHome.USP_UnitHome(Request);

            Request.Action = "checkOut";
            Request.Table3 = _IUnitHome.USP_UnitHome(Request);


            return View(Request);
        }


        public async Task<IActionResult> CheckInRoomDetails(UnitHomeViewModel Request)
        {

            Request.HotelId = CurrentUser.HotelId;
            Request.Action = "CheckIn_1";
            Request.Table1 = _IUnitHome.USP_UnitHome(Request);

            Request.Action = "CheckIn_2";
            Request.Table2 = _IUnitHome.USP_UnitHome(Request);


            return View(Request);
        }

        public JsonResult InsertCheckIn(UnitHomeViewModel Request)
        {
            Request.Action = "1";
            Request.HotelId = CurrentUser.HotelId;
            DataTable dataTable = _IUnitHome.USP_InsertCheckIn(Request);

            string json = JsonConvert.SerializeObject(dataTable, Formatting.Indented);
            return Json(json);
        }
    }
}
