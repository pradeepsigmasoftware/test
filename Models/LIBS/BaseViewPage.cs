using Microsoft.AspNetCore.Mvc.Razor;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Hotel.Models
{   

    public abstract class BaseViewPage<TModel> : RazorPage<TModel>
    {
        public CustomPrincipal CurrentUser => new CustomPrincipal(ContextProvider.Current.User);
    }
    public abstract class BaseViewPage : RazorPage
    {
        public CustomPrincipal CurrentUser => new CustomPrincipal(ContextProvider.Current.User);
    }

}
