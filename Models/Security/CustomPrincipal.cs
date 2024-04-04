using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Security.Principal;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Text.Json.Serialization;
using Hotel.Models;


namespace Hotel.Models
{
    public class CustomPrincipal : IPrincipal
    {
        public bool IsAuthenticated { get; private set; }
        public int UserID { get; set; }
        public string UserName { get; private set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int RoleID { get; set; }
        public int? OrganisationID { get; set; }
        public int? CharityID { get; set; }
        public int? BranchID { get; set; }
        public int? PersonID { get; set; }
        public int? ParentRoleID { get; set; }
        public string ScreenImage { get; set; }
        public string MSApiUserId { get; set; }
        public bool IsTeamManager { get; set; }
        public int FoodbankId { get; set; }
        public string HotelId { get; set; }

        [JsonIgnore]
        public IIdentity Identity { get; private set; }


        private readonly ClaimsPrincipal claimsPrincipal;

        public CustomPrincipal(ClaimsPrincipal principal)
        {
            claimsPrincipal = principal;
            this.IsAuthenticated = claimsPrincipal.Identity.IsAuthenticated;
            if (this.IsAuthenticated)
            {
                this.Identity = new GenericIdentity(claimsPrincipal.Claims.FirstOrDefault(u => u.Type == nameof(this.UserName))?.Value);

                this.UserID = int.Parse(claimsPrincipal.Claims.FirstOrDefault(u => u.Type == ClaimTypes.PrimarySid)?.Value);

                this.FirstName = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == ClaimTypes.GivenName)?.Value;
                this.LastName = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == nameof(this.LastName))?.Value;
                this.UserName = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == nameof(this.UserName))?.Value;
                this.Email = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == ClaimTypes.Email)?.Value;
                this.RoleID = int.Parse(claimsPrincipal.Claims.FirstOrDefault(u => u.Type == nameof(this.RoleID))?.Value); 
                this.HotelId = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == nameof(this.HotelId))?.Value; 
            }
        }

        private void UpdateClaim(string key, string value)
        {
            var claims = claimsPrincipal.Claims.ToList();
            if (claims.Any())
            {
                var pmClaim = claimsPrincipal.Claims.FirstOrDefault(u => u.Type == key);
                if (pmClaim != null)
                {
                    claims.Remove(pmClaim);
                    claims.Add(new Claim(key, value));
                }
            }

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var authProperties = new AuthenticationProperties { IsPersistent = true };

            ContextProvider.HttpContext.SignInAsync(
                  CookieAuthenticationDefaults.AuthenticationScheme,
                   new ClaimsPrincipal(claimsIdentity),
                   authProperties
                 ).Wait();
        }
        public bool IsInRole(int roleID)
        {
            return RoleID == roleID || ParentRoleID == roleID;
        }


        public bool IsInRole(string roleID)
        {
            return RoleID == Convert.ToInt32(roleID) || ParentRoleID == Convert.ToInt32(roleID);
        }

        public bool IsSuperAdminUser()
        {
            return (RoleID == Convert.ToInt32((int)UserRoles.Admin) || ParentRoleID == Convert.ToInt32((int)UserRoles.Hotel) && OrganisationID <= 0);
        }

    

     

    }
}
