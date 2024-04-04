using Azure.Core;
using Hotel.Areas.Admin.DTO;
using Hotel.Models;
using Microsoft.AspNetCore.Hosting;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;

namespace Hotel.Areas.Admin.Models.Services.Hotel
{
	public class HotelDTOService : IHotelDTOService
	{
		DBHelper db = new DBHelper();

		public DataTable StateMaster(StateMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
               // new SqlParameter ("@StateId",request.StateId)               
            };
			dt = db.ExecProcDataTable("USP_DynamicDropDownList", param);
			return dt;

		}
		public DataTable CityMasterData(CityMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@StateId",request.StateId)
			};
			dt = db.ExecProcDataTable("USP_DynamicDropDownList", param);
			return dt;

		}


		public DataTable HotelMasterData(BindHotelDDLDto_cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@CityId",request.CityId)
			};
			dt = db.ExecProcDataTable("USP_DynamicDropDownList", param);
			return dt;

		}

		public DataTable CategoryMasterData(CategoryMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@HotelId",request.HotelId)
			};
			dt = db.ExecProcDataTable("USP_DynamicDropDownList", param);
			return dt;

		}


		public DataTable HotelMasterDTO(HotelDTO_Cls request)
		{

			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[] {
				  new SqlParameter("@Action" ,request.Action),
				  new SqlParameter("@HotelId" ,request.HotelId),
				  new SqlParameter("@HotelName" ,request.HotelName),
				  new SqlParameter("@HotalCodenew" ,request.HotalCodenew),
				  new SqlParameter("@ContactNo" ,request.ContactNo),
				  new SqlParameter("@Address" ,request.Address),
               // new SqlParameter("@Latitude" ,request.Latitude),
               // new SqlParameter("@Longitude" ,request.Longitude),
                  new SqlParameter("@StateId" ,request.StateId),
				  new SqlParameter("@CityId" ,request.CityId),
				  new SqlParameter("@EmailId" ,request.EmailId),
				  new SqlParameter("@Landline" ,request.Landline),
				  new SqlParameter("@ImageURL" ,request.ImageURL),
				  new SqlParameter("@Description" ,request.Description),
			};
			dt = db.ExecProcDataTable("USP_InsertHotelDTO", param);
			return dt;
		}

		public DataTable CategoryMasterService(CategoryMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[] {
				  new SqlParameter("@Action" ,request.Action),
				  new SqlParameter("@ID",request.Id),
				  new SqlParameter("@CityId",request.CityId),
				  new SqlParameter("@HotelId",request.HotelId),
				  new SqlParameter("@Category" ,request.Category),
               // new SqlParameter("@EntryDate" ,request.EntryDate),
                  new SqlParameter("@IsActive" ,request.IsActive),
				  new SqlParameter("@bed_id" ,request.bed_id),
			};
			dt = db.ExecProcDataTable("USP_CategoryMaster", param);
			return dt;
		}

		public DataTable GstMasterService(GstMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@GSTID",request.GSTID),
				new SqlParameter ("@StartAmt",request.StartAmt),
				new SqlParameter ("@EndAmt",request.EndAmt),
				new SqlParameter ("@GSTPer",request.GSTPer),
			};
			dt = db.ExecProcDataTable("USP_GstMaster", param);
			return dt;
		}

		public DataTable HotelImageMasterService(HotelImageMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@Id",request.Id),
				new SqlParameter ("@ImagePath",request.ImagePath),
				new SqlParameter ("@IsActive",request.IsActive),
				new SqlParameter ("@ImgExt",request.ImgExt),
				new SqlParameter ("@HotelId",request.HotelId),
			};
			dt = db.ExecProcDataTable("USP_HotelImagesMaster", param);
			return dt;
		}

		public DataTable HotelRoomMasterService(RoomImages_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@Id",request.Id),
				new SqlParameter ("@ImagePath",request.ImagePath),
				new SqlParameter ("@CategoryId",request.Category),
				new SqlParameter ("@ImageExt",request.ImageExt),
				new SqlParameter ("@HotelId",request.HotelId),
			};
			dt = db.ExecProcDataTable("USP_RoomImagesMaster", param);
			return dt;
		}

		public DataTable BookingRoomDetailsService(BookingRoomDetails_Cls request)
		{
			DataTable dt = new DataTable();

			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@RoomId",request.RoomId),
				new SqlParameter ("@RoomNo",request.strRoomNo),
				new SqlParameter ("@HotelId",request.HotelId),
				new SqlParameter ("@CategoryId",request.CategoryId),
				new SqlParameter ("@IsActive",request.IsActive),
				new SqlParameter ("@IsOffLine",request.IsOffLine),
				new SqlParameter ("@OffLineDate",request.OffLineDate),
				new SqlParameter ("@OLDatefrom",request.OLDatefrom),
				new SqlParameter ("@OLDateTo",request.OLDateTo),
			};
			dt = db.ExecProcDataTable("USP_BookingRoomDetails", param);

			return dt;

		}



		public DataTable CityMasterService(CityMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
				new SqlParameter ("@Id",request.Id),
				new SqlParameter ("@CityName",request.CityName),
				new SqlParameter ("@StateId",request.StateId),
              //  new SqlParameter ("@EntryDate",request.EntryDate),
                new SqlParameter ("@UnitAbbr",request.UnitAbbr),
			};
			dt = db.ExecProcDataTable("USP_CityMaster", param);
			return dt;
		}
		public DataTable HotelLoginDetailsService(Login_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter ("@Action",request.Action),
			};
			dt = db.ExecProcDataTable("USP_HotelDetails", param);
			return dt;
		}

		public DataTable RateMasterService(RateMaster_Cls request)
		{
			DataTable dt = new DataTable();
			SqlParameter[] param = new SqlParameter[]
			{
				new SqlParameter("@Action", request.Action),
				new SqlParameter("@RateID", request.RateID),
				new SqlParameter("@HotelId", request.HotelId),
				new SqlParameter("@CategoryId", request.CategoryId),
				new SqlParameter("@PricePerDay", request.PricePerDay),
				new SqlParameter("@PriceDifference", request.PriceDifference),
				new SqlParameter("@ExtraBedPercentage", request.ExtraBedPercentage),
				new SqlParameter("@RateStartDate", request.RateStartDate),
				new SqlParameter("@RateEndDate", request.RateEndDate),
				new SqlParameter("@IsActive", request.IsActive),
				new SqlParameter("@EntryBy", request.EntryBy),
				new SqlParameter("@EntryDate", request.EntryDate),
			};

			dt = db.ExecProcDataTable("USP_RateMaster", param);
			return dt;
		}
	}
}
