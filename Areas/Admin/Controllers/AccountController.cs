using Hotel.Areas.Admin.DTO;
using Hotel.data;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Hotel.Models;
using NuGet.Protocol.Plugins;
using Hotel.Controllers;

namespace Hotel.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class AccountController : BaseController
    {
        private readonly IRepository<Login> _login;
        private readonly IRepository<TblHotelMaster> _tblHotelMaster;

        public AccountController(IRepository<Login> login, IRepository<TblHotelMaster> tblHotelMaster)
        {
            _login = login;
            _tblHotelMaster = tblHotelMaster;
        }

        public IActionResult Index()
        {
            return View();
        }


        [HttpPost]
        public async Task<IActionResult> Index(LoginViewDto model)
        {
            try
            {
                if (ModelState.IsValid == true && !string.IsNullOrEmpty(model.UserName) && !string.IsNullOrEmpty(model.Password))
                {
                    Login user = _login.Query().Filter(a => a.UserName == model.UserName && a.Password == model.Password).Get().FirstOrDefault();

                    if (user != null && !string.IsNullOrEmpty(user.UserName) && !string.IsNullOrEmpty(user.Password))
                    {

                        if ((user.MRoleId == 1 || user.MRoleId == 2))
                        {
                            var userDto = new UserSessionDto
                            {
                                UserId = user.UserId,
                                UserName = user.UserName,
                                Name = user.UserName,
                                Email = user.UserName,
                                RoleID = user.MRoleId,
                                HotelId = user.HotelId
                            };

                            if (user.MRoleId == 2)
                            {
                                userDto.Name = _tblHotelMaster.Query().Filter(a => a.HotelId == user.HotelId).Get().FirstOrDefault().HotelName;
                            }

                            await CreateAuthenticationTicket(userDto);
                            switch (user.MRoleId)
                            {
                                case (int)UserRoles.Admin:
                                    return RedirectToAction("Index", "Dashboard", new { area = "Admin" });
                                case (int)UserRoles.Hotel:
                                    return RedirectToAction("Home", "Dashboard", new { area = "Unit" });
                            }


                        }

                    }
                    return View(model);
                }
                else
                {
                    return View(model);
                }
            }
            catch (Exception ex)
            {
                return View(model);
            }
        }

        [HttpGet]
        public IActionResult Logout()
        {
            var abc = RemoveAuthentication();
            return RedirectToAction("Index", "Account", new { area = "Admin", name = "Admin" });
        }
        public async Task CreateAuthenticationTicket(UserSessionDto user)
        {
            if (user != null)
            {
                string userRole = ((UserRoles)user.RoleID).ToString();
                var claims = new List<Claim>{


                        new Claim(ClaimTypes.PrimarySid, Convert.ToString(user.UserId)),
                        new Claim(ClaimTypes.Email, !string.IsNullOrEmpty(user.Email)?user.Email : string.Empty),
                        new Claim(ClaimTypes.GivenName, user.Name==null?"":user.Name),
                        new Claim(ClaimTypes.Name, user.UserName),
                        new Claim(nameof(user.UserName), user.UserName),
                        new Claim(nameof(user.RoleID), Convert.ToString(user.RoleID)),
                        new Claim(nameof(user.HotelId), user.HotelId==null?"":user.HotelId),
                        new Claim(ClaimTypes.Role,userRole),

                };
                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

                var authProperties = new AuthenticationProperties
                {
                };

                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme,
                    new ClaimsPrincipal(claimsIdentity),
                    authProperties);
            }
        }
        public async Task RemoveAuthentication()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        }


    }
}
