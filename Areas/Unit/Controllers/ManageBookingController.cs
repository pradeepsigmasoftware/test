using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Admin.Models.Services.Booking;
using Hotel.Areas.Unit.DTO;
using Hotel.Areas.Unit.Models.Services.Home;
using Hotel.Controllers;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Data;

namespace Hotel.Areas.Unit.Controllers
{
    [Area("Unit")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "Hotel")]
    public class ManageBookingController : BaseController
    {
        private readonly IUnitHome _IUnitHome;
        public ManageBookingController(IUnitHome IUnitHome)
        {
            _IUnitHome = IUnitHome;
        }
        public IActionResult Index(UnitHomeViewModel Request)
        {
            Request.HotelId = CurrentUser.HotelId;
            Request.Action = "ManageBooking_1";
            Request.Table1 = _IUnitHome.USP_UnitHome(Request);


            return View(Request);
        }
        public JsonResult GetManageBookingData(UnitHomeViewModel Request)
        {
            Request.Action = "1";
            Request.HotelId = CurrentUser.HotelId;
            DataTable dataTable = _IUnitHome.GetManageBookingData(Request);

            string json = JsonConvert.SerializeObject(dataTable, Formatting.Indented);

            return Json(json);
        }
    }
}
