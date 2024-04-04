using Hotel.Controllers;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Hotel.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "Admin")]
    public class DashboardController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            return View();
        }
    }
}
