using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Admin.Models.Services.Booking;
using Hotel.Areas.Admin.Models.Services.Hotel;
using Hotel.Areas.Unit.DTO;
using Hotel.Controllers;
using Hotel.data;
using Hotel.Models.Common;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using System.Data;
using System.Security.Cryptography;
namespace Hotel.Areas.Admin.Controllers
{
	[Area("Admin")]
	[Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "Admin")]
	public class MasterController : BaseController
	{
		private readonly IWebHostEnvironment _webHostEnvironment;

        private readonly IHotelDTOService _hotelDTOService;

		public MasterController(IHotelDTOService hotelDTOService, IWebHostEnvironment webHostEnvironment)
		{
			_hotelDTOService = hotelDTOService;
			_webHostEnvironment = webHostEnvironment;

		}

		#region  Bind DropDown List
		public JsonResult BindStateData()
		{
			StateMaster_Cls obj = new StateMaster_Cls();
			obj.Action = "1";
			obj.dt = _hotelDTOService.StateMaster(obj);
			obj.StateMasterDDLLst = CommonFun.BindDDL(obj.dt);
			var ddl = obj.StateMasterDDLLst;
			return Json(ddl);
		}

		public JsonResult BindCityData(int stateId)
		{
			CityMaster_Cls obj = new CityMaster_Cls();
			obj.Action = "2";
			obj.StateId = stateId;
			obj.dt = _hotelDTOService.CityMasterData(obj);

			obj.CityMasterDDLLst = CommonFun.BindDDL(obj.dt);
			var ddl = obj.CityMasterDDLLst;
			return Json(ddl);

		}
		public JsonResult BindCityWithoutId()
		{
			CityMaster_Cls obj = new CityMaster_Cls();
			obj.Action = "3";
			obj.dt = _hotelDTOService.CityMasterData(obj);
			obj.CityMasterDDLLst = CommonFun.BindDDL(obj.dt);
			var ddl = obj.CityMasterDDLLst;
			return Json(ddl);
		}

		public JsonResult BindHotelMaster(int id)
		{
			BindHotelDDLDto_cls obj = new BindHotelDDLDto_cls();
			obj.Action = "4";
			obj.CityId = id;
			obj.dt = _hotelDTOService.HotelMasterData(obj);
			obj.HotelDDLLst = CommonFun.BindDDL(obj.dt);
			var ddl = obj.HotelDDLLst;
			return Json(ddl);
		}

		public JsonResult BindHotelWithoutId()
		{
			BindHotelDDLDto_cls obj = new BindHotelDDLDto_cls();
			obj.Action = "6";
			obj.dt = _hotelDTOService.HotelMasterData(obj);
			obj.HotelDDLLst = CommonFun.BindDDL(obj.dt);
			var ddl = obj.HotelDDLLst;
			return Json(ddl);
		}
		public JsonResult BindCategoryMaster(string id)
		{
			CategoryMaster_Cls obj = new CategoryMaster_Cls();
			obj.Action = "5";
			obj.HotelId = id;
			obj.dt = _hotelDTOService.CategoryMasterData(obj);
			obj.CategoryDDLList = CommonFun.BindDDL(obj.dt);
			var ddl = obj.CategoryDDLList;
			return Json(ddl);
		}

		#endregion


		#region  Hotel Master   ---1-list, 2-insert, 3-GetByIdList, 4-Update
		public async Task<IActionResult> AddHotel(string? HID)
		{
			HotelDTO_Cls obj = new HotelDTO_Cls();
			if (HID == null)
			{
				obj.Action = "1"; //list hotel                
				obj.dt = _hotelDTOService.HotelMasterDTO(obj);
			}
			else
			{
				obj.Action = "3";
				obj.HotelId = HID;
				obj.dt = _hotelDTOService.HotelMasterDTO(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					obj.HotelId = obj.dt.Rows[0]["HotelId"].ToString();
					obj.HotelName = obj.dt.Rows[0]["HotelName"].ToString();
					obj.HotalCodenew = obj.dt.Rows[0]["HotalCodenew"].ToString();
					obj.ContactNo = obj.dt.Rows[0]["ContactNo"].ToString();
					obj.Address = obj.dt.Rows[0]["Address"].ToString();
					obj.StateId = Convert.ToInt32(obj.dt.Rows[0]["StateId"]);
					obj.CityId = Convert.ToInt32(obj.dt.Rows[0]["CityId"]);
					obj.EmailId = obj.dt.Rows[0]["EmailId"].ToString();
					obj.Landline = obj.dt.Rows[0]["Landline"].ToString();
					obj.ImageURL = obj.dt.Rows[0]["ImageURL"].ToString();
					obj.Description = obj.dt.Rows[0]["Description"].ToString();
				}

			}

			return View(obj);
		}

		[HttpPost]
		public async Task<IActionResult> AddHotel(HotelDTO_Cls obj, string? HotelId)
		{
			string msg = "";
			try
			{
				string uniqueFileName = ImageUploadedFile(obj);
				if (HotelId == null)
				{
					obj.Action = "2"; // insert hotel
					obj.ImageURL = "/Upload/IconImages/" + uniqueFileName;
					obj.dt = _hotelDTOService.HotelMasterDTO(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not saved !!!";
					}
				}
				else
				{
					obj.Action = "4";
					obj.HotelId = HotelId;
					obj.ImageURL = "/Upload/IconImages/" + uniqueFileName;
					obj.dt = _hotelDTOService.HotelMasterDTO(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not Updated !!!";
					}
				}

			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}

			TempData["flag"] = msg;
			return RedirectToAction("AddHotel");
		}

		#endregion


		#region CategoryMaster ---1-list, 2-insert, 3-GetByIdList, 4-Update
		public async Task<IActionResult> CategoryMaster(int? CID)
		{
			CategoryMaster_Cls obj = new CategoryMaster_Cls();
			if (CID == null)
			{
				obj.Action = "1"; //list  CategoryMaster
				obj.dt = _hotelDTOService.CategoryMasterService(obj);
			}
			else
			{
				obj.Action = "3"; //GetById CategoryMaster
				obj.Id = CID ?? 0;
				obj.dt = _hotelDTOService.CategoryMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					obj.Id = Convert.ToInt32(obj.dt.Rows[0]["ID"]);
					obj.CityName = obj.dt.Rows[0]["CityName"].ToString();
					obj.CityId = Convert.ToInt32(obj.dt.Rows[0]["CityId"]);
					obj.Category = obj.dt.Rows[0]["Category"].ToString();
					obj.HotelId = obj.dt.Rows[0]["HotelId"].ToString();
					obj.Category = obj.dt.Rows[0]["Category"].ToString();
				}
			}
			return View(obj);
		}

		[HttpPost]
		public async Task<IActionResult> CategoryMaster(CategoryMaster_Cls obj, int? Id)
		{
			string msg = "";
			try
			{
				if (Id == null)
				{
					obj.Action = "2"; //insert CategoryMaster
					obj.dt = _hotelDTOService.CategoryMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not saved !!!";
					}
				}
				else
				{
					obj.Action = "4"; //update CategoryMaster
					obj.Id = Id ?? 0;
					obj.dt = _hotelDTOService.CategoryMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not Updated !!!";
					}

				}
			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}

			TempData["flag"] = msg;




			return RedirectToAction("CategoryMaster");
		}

		#endregion CategoryMaster


		#region Room Deatils Insert Edit And Isactive 
		public async Task<IActionResult> InsertRoomMaster()
		{
			BookingRoomDetails_Cls obj = new BookingRoomDetails_Cls();
			if (obj.RoomId == 0)
			{
				obj.Action = "1";
				obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
			}

			return View(obj);
		}

		public JsonResult InsertRoomMasterjson(BookingRoomDetails_Cls obj)
		{

			string msg = "";

			try
			{
				DataTable dt1 = new DataTable();
				if (obj.RoomId == 0)
				{
					for (int i = 0; i < obj.RoomNo.Length; i++)
					{
						obj.Action = "2";
						obj.strRoomNo = obj.RoomNo[i];
						obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
					}
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = "1";
					}
					else
					{
						msg = "0";
					}
				}

				else
				{
					obj.RoomId = obj.RoomId;
					for (int i = 0; i < obj.RoomNo.Length; i++)
					{
						obj.Action = "4"; //update InsertRoomMaster
						obj.strRoomNo = obj.RoomNo[i];
						obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
					}
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = "1";
					}
					else
					{
						msg = "0";
					}
				}
			}
			catch (Exception ex)
			{
				msg = "0";
			}

			TempData["flag"] = msg;

			return Json(msg);
		}

		public async Task<IActionResult> EditRoomMaster(string RID, int CID)
		{
			BookingRoomDetails_Cls obj = new BookingRoomDetails_Cls();
			if (RID != null && CID != 0)
			{
				obj.Action = "3";
				obj.HotelId = RID;
				obj.CategoryId = CID;
				obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
			}

			return View(obj);
		}

		[HttpPost]
		public JsonResult IsActiveAndOffline(int roomId, string mode, bool status)
		{
			BookingRoomDetails_Cls obj = new BookingRoomDetails_Cls();
			string msg = "";
			try
			{
				if (mode == "1")
				{
					obj.Action = "4";
					obj.RoomId = roomId;
					obj.IsActive = status;
					obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = "1";
					}
					else
					{
						msg = "0";
					}
				}
				else
				{
					obj.Action = "5";
					obj.RoomId = roomId;
					obj.IsOffLine = status;
					obj.dt = _hotelDTOService.BookingRoomDetailsService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = "1";
					}
					else
					{
						msg = "0";
					}
				}

			}
			catch (Exception ex)
			{
				msg = "0";
			}

			TempData["flag"] = msg;


			return Json(obj);
		}

		#endregion


		#region GstMaster ---1-list, 2-insert, 3-GetByIdList, 4-Update
		public async Task<IActionResult> GSTMaster(int? id)
		{
			GstMaster_Cls obj = new GstMaster_Cls();
			if (id == null)
			{
				obj.Action = "1";
				obj.dt = _hotelDTOService.GstMasterService(obj);
			}
			else
			{
				obj.Action = "3";
				obj.GSTID = id ?? 0;
				obj.dt = _hotelDTOService.GstMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					obj.GSTID = Convert.ToInt32(obj.dt.Rows[0]["GSTID"]);
					obj.StartAmt = Convert.ToDecimal(obj.dt.Rows[0]["StartAmt"]);
					obj.EndAmt = Convert.ToDecimal(obj.dt.Rows[0]["EndAmt"]);
					obj.GSTPer = Convert.ToDecimal(obj.dt.Rows[0]["GSTPer"]);
				}
			}
			return View(obj);
		}

		[HttpPost]
		public async Task<IActionResult> GSTMaster(GstMaster_Cls obj, int? GstId)
		{
			string msg = "";
			try
			{
				if (GstId == 0)
				{
					obj.Action = "2"; //insert CategoryMaster
					obj.dt = _hotelDTOService.GstMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not saved !!!";
					}
				}
				else
				{
					obj.Action = "4";
					obj.GSTID = GstId ?? 0;
					obj.dt = _hotelDTOService.GstMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data not Updated !!!";
					}

				}

			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}

			TempData["flag"] = msg;

			return RedirectToAction("GSTMaster");
		}

		#endregion


		#region HotelLoginDetails  ---1-list
		public async Task<IActionResult> HotelLoginDetails()
		{
			Login_Cls obj = new Login_Cls();
			obj.Action = "1";
			obj.dt = _hotelDTOService.HotelLoginDetailsService(obj);
			return View(obj);
		}
		#endregion


		#region UploadHotelImages ---1-list, 2-insert
		public async Task<IActionResult> UploadHotelImages(string? id)
		{
			HotelImageMaster_Cls obj = new HotelImageMaster_Cls();

			if (id != null)
			{
				obj.HotelId = id;
				obj.Action = "1";
				obj.dt = _hotelDTOService.HotelImageMasterService(obj);

				return View(obj);
			}
			else
			{
				return View(obj);
			}

		}

		[HttpPost]
		public async Task<IActionResult> UploadHotelImages(HotelImageMaster_Cls obj)
		{
			string msg = "";
			try
			{
				string uniqueFileName = UploadedHotelImages(obj);

				obj.Action = "2"; //insert HotelImageMaster
				obj.ImagePath = "/Upload/HotelImages/" + uniqueFileName;
				obj.dt = _hotelDTOService.HotelImageMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
				}
				else
				{
					msg = "Data not saved !!!";
				}

			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}

			TempData["flag"] = msg;

			return RedirectToAction("UploadHotelImages");

		}

		#endregion


		#region UploadRoomImages ---1-list, 2-insert
		public async Task<IActionResult> UploadRoomImages(string id)
		{

			RoomImages_Cls obj = new RoomImages_Cls();

			if (id != null)
			{
				obj.HotelId = id;
				obj.Action = "1";
				obj.dt = _hotelDTOService.HotelRoomMasterService(obj);

				return View(obj);
			}
			else
			{
				return View(obj);
			}
		}

		[HttpPost]
		public async Task<IActionResult> UploadRoomImages(RoomImages_Cls obj)
		{
			string msg = "";
			try
			{
				string uniqueFileName = UploadedRoomImages(obj);
				obj.Action = "2"; //insert HotelImageMaster
				obj.ImagePath = "/Upload/RoomImages/" + uniqueFileName;
				obj.dt = _hotelDTOService.HotelRoomMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
				}
				else
				{
					msg = "Data not saved !!!";
				}

			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}

			TempData["flag"] = msg;

			return RedirectToAction("UploadHotelImages");

		}

		[HttpPost]
		public async Task<IActionResult> DeleteRoomImages(RoomImages_Cls obj)
		{
			string msg = "";
			try
			{
				obj.Action = "3";
				obj.dt = _hotelDTOService.HotelRoomMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					msg = "1";
				}
				else
				{
					msg = "0";
				}
			}
			catch (Exception ex)
			{

			}
			return Json(msg);
		}

		#endregion


		#region  CityMaster ---1-list, 2-insert, 3-GetByIdList, 4-Update
		public async Task<IActionResult> CityMaster(int? id)
		{
			CityMaster_Cls obj = new CityMaster_Cls();
			if (id == null)
			{
				obj.Action = "1";
				obj.dt = _hotelDTOService.CityMasterService(obj);
			}
			else
			{
				obj.Action = "3";
				obj.Id = id ?? 0;
				obj.dt = _hotelDTOService.CityMasterService(obj);
				if (obj.dt != null && obj.dt.Rows.Count > 0)
				{
					obj.Id = Convert.ToInt32(obj.dt.Rows[0]["Id"]);
					obj.CityName = obj.dt.Rows[0]["CityName"].ToString();
					obj.StateId = Convert.ToInt32(obj.dt.Rows[0]["StateId"]);
					obj.UnitAbbr = obj.dt.Rows[0]["UnitAbbr"].ToString();
				}
			}
			return View(obj);
		}

		[HttpPost]
		public async Task<IActionResult> CityMaster(CityMaster_Cls obj, int? Id)
		{
			string msg = "";
			try
			{
				if (Id == 0)
				{
					obj.Action = "2";
					obj.dt = _hotelDTOService.CityMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data Not Saved !!!";
					}
				}
				else
				{
					obj.Action = "4";
					obj.Id = Id ?? 0;
					obj.dt = _hotelDTOService.CityMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data Not Updated !!!";
					}
				}
			}
			catch (Exception ex)
			{
				//msg = ex.Message;
				msg = "Server Error !";
			}

			TempData["flag"] = msg;

			return RedirectToAction("CityMaster");
		}
		#endregion


		#region  RateMaster ---1-list, 2-insert, 3-GetByIdList, 4-Update

		public async Task<IActionResult> RateMaster(int? Id)
		{
			RateMaster_Cls obj = new RateMaster_Cls();
			string msg = "";
			try
			{
				
				if (Id == null)
				{
					obj.Action = "1";
					obj.dt = _hotelDTOService.RateMasterService(obj);
					
				}
				else
				{
					obj.Action = "3";
					obj.RateID = Id ?? 0;					
					obj.dt = _hotelDTOService.RateMasterService(obj);
					if(obj.dt !=null && obj.dt.Rows.Count > 0)
					{
						obj.HotelId = obj.dt.Rows[0]["HotelId"].ToString();
						obj.CategoryId = Convert.ToInt32(obj.dt.Rows[0]["CategoryId"]);
						obj.PricePerDay = Convert.ToDecimal(obj.dt.Rows[0]["PricePerDay"]);
						obj.PriceDifference = Convert.ToDecimal(obj.dt.Rows[0]["PriceDifference"]);
						obj.ExtraBedPercentage = Convert.ToDecimal(obj.dt.Rows[0]["ExtraBedPercentage"]);
						obj.RateStartDate =obj.dt.Rows[0]["RateStartDate"].ToString();
						obj.RateEndDate = obj.dt.Rows[0]["RateEndDate"].ToString();
						//obj.IsActive = obj.dt.Rows[0]["IsActive"].ToString();
						obj.EntryBy = obj.dt.Rows[0]["EntryBy"].ToString();
						obj.EntryDate = obj.dt.Rows[0]["EntryDate"].ToString();
					}


				}
			}
			catch (Exception ex)
			{
				msg = "Server Error !!!";
			}
			return View(obj);
		}

		[HttpPost]
		public async Task<IActionResult> RateMaster(RateMaster_Cls obj, int RateID)
		{
			string msg = "";
			try
			{
				if (RateID == 0)
				{
					obj.Action = "2";
					obj.EntryBy = CurrentUser.UserID.ToString();
					obj.dt = _hotelDTOService.RateMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data Not Saved !!!";
					}
				}
				else
				{
					obj.Action = "4";
					obj.RateID = RateID;
					obj.EntryBy = CurrentUser.UserID.ToString();
					obj.dt = _hotelDTOService.RateMasterService(obj);
					if (obj.dt != null && obj.dt.Rows.Count > 0)
					{
						msg = Convert.ToString(obj.dt.Rows[0]["msg"]);
					}
					else
					{
						msg = "Data Not Saved !!!";
					}
				}
			}
			catch(Exception ex)
			{
				msg = "Server Error !!!";
			}


			return RedirectToAction("RateMaster");
		}


		#endregion

		#region  ----Image Upload Function-----

		private string UploadedRoomImages(RoomImages_Cls model)
		{
			string uniqueFileName = null;

			if (model.Image != null)
			{
				string uploadsFolder = Path.Combine(_webHostEnvironment.WebRootPath, "Upload/RoomImages");
				uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetExtension(model.Image.FileName);
				string filePath = Path.Combine(uploadsFolder, uniqueFileName);
				using (var fileStream = new FileStream(filePath, FileMode.Create))
				{
					model.Image.CopyTo(fileStream);
				}
			}

			return uniqueFileName;
		}


		private string UploadedHotelImages(HotelImageMaster_Cls model)
		{
			string uniqueFileName = null;

			if (model.Image != null)
			{
				string uploadsFolder = Path.Combine(_webHostEnvironment.WebRootPath, "Upload/HotelImages");
				uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetExtension(model.Image.FileName);
				string filePath = Path.Combine(uploadsFolder, uniqueFileName);
				using (var fileStream = new FileStream(filePath, FileMode.Create))
				{
					model.Image.CopyTo(fileStream);
				}
			}

			return uniqueFileName;
		}


		private string ImageUploadedFile(HotelDTO_Cls model)
		{
			string uniqueFileName = null;

			if (model.Image != null)
			{
				string uploadsFolder = Path.Combine(_webHostEnvironment.WebRootPath, "Upload/IconImages");
				uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetExtension(model.Image.FileName);
				string filePath = Path.Combine(uploadsFolder, uniqueFileName);
				using (var fileStream = new FileStream(filePath, FileMode.Create))
				{
					model.Image.CopyTo(fileStream);
				}
			}

			return uniqueFileName;
		}

		#endregion
	}
}
