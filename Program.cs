using Hotel.Areas.Admin.Models.Services.Booking;
using Hotel.Areas.Admin.Models.Services.Hotel;
using Hotel.Areas.Unit.Models.Services.Home;
using Hotel.data;
using Hotel.Models;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);



// Add services to the container.
builder.Services.AddControllersWithViews();




//////////////////////////////////////

builder.Services.Configure<CookieTempDataProviderOptions>(options =>
{
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;

});
builder.Services.Configure<CookiePolicyOptions>(options =>
{
    options.CheckConsentNeeded = context => true;
    options.MinimumSameSitePolicy = SameSiteMode.None;
    options.ConsentCookie.SecurePolicy = CookieSecurePolicy.Always;
});
builder.Services.AddSession(options =>
{
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});
builder.Services.Configure<FormOptions>(x => x.ValueCountLimit = 1048576);
builder.Services.AddSession();
//SiteKeys.Configure(builder.Configuration.GetSection("AppSetting"));
// Set connection string

builder.Services.AddDbContext<UPSTDCHoteldbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ConnectionStrings")));


builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(opt =>
{
    opt.LoginPath = "/AdminLogin";
});

///////////////////////


builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<IUnitHome, UnitHome>();
builder.Services.AddScoped<Login>();
builder.Services.AddScoped<TblHotelMaster>();

builder.Services.AddScoped<IHotelDTOService,HotelDTOService>();

var app = builder.Build();



// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
   
}


app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
           name: "Admin",
           pattern: "{area:exists}/{controller=Account}/{action=Index}/{id?}"
         );
app.MapControllerRoute(
           name: "Unit",
           pattern: "{area:exists}/{controller=Dashboard}/{action=Home}/{id?}"
         );

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");



app.Run();
