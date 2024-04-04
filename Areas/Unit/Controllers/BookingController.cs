using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Admin.Models.Services.Booking;
using Hotel.Controllers;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Data;

namespace Hotel.Areas.Unit.Controllers
{
    [Area("Unit")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "Hotel, Admin")]
    public class BookingController : BaseController
    {
        readonly IBookingService bookingService;
        public BookingController(IBookingService _bookingService)
        {
            bookingService = _bookingService;
        }
        public async Task<IActionResult> HotelBooking(HotelBookingDTO Request)
        {
            Request.Action = "1";
            Request.HotelId =  CurrentUser.HotelId; 
            Request.CheckInDate = DateTime.Now.ToString("yyyy-MM-dd");
            Request.CheckOutDate = DateTime.Now.AddDays(1).ToString("yyyy-MM-dd");

            Request.Table1 = bookingService.USP_CategoryWiseRoomDetails(Request);

            return View(Request);
        }
        public JsonResult GetRoomBooking(HotelBookingDTO Request)
        {
            Request.Action = "1";
            Request.HotelId = CurrentUser.HotelId;
            DataTable dataTable = bookingService.USP_CategoryWiseRoomDetails(Request);

            string json = JsonConvert.SerializeObject(dataTable, Formatting.Indented);
            
            return Json(json);
        }
        

        public JsonResult InsertBooking(BooingRoot Request)
        {
            Request.Action = "1";
            Request.HotelId = CurrentUser.HotelId;

            DataTable dataTable = bookingService.USP_InsertBooking(Request);

            string json = JsonConvert.SerializeObject(dataTable, Formatting.Indented);
            return Json(json);
        }






    }
}
