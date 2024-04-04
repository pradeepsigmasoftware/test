using Hotel.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace ERP.WebI.Code.Attributes
{
    public class CustomAuthorization : AuthorizeAttribute
    {
        private object[] roleTypes;
        public CustomAuthorization(params object[] roleTypes)
        {
            this.roleTypes = roleTypes;
        }

        protected virtual ClaimsPrincipal CurrentUser
        {
            get { return ContextProvider.Current.User; }
        }

       

        public class CustomActionAuthorization : ActionFilterAttribute
        {
            protected virtual CustomPrincipal CurrentUser
            {
                get { return new CustomPrincipal(ContextProvider.HttpContext.User); }
            }
            public override void OnActionExecuting(ActionExecutingContext filterContext)
            {
                if (filterContext != null)
                {
                    if (!CurrentUser.IsAuthenticated)
                    {
                        filterContext.Result = new RedirectResult("~/admin");
                    }
                }
            }
        }
    }
}