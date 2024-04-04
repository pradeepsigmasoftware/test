using Hotel.Models;
using Microsoft.AspNetCore.Mvc;

namespace Hotel.Controllers
{
    public class BaseController : Controller
    {
        public CustomPrincipal CurrentUser => new CustomPrincipal(HttpContext.User);
      














    }
}
