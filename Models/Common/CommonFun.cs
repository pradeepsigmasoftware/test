using Microsoft.AspNetCore.Mvc.Rendering;
using Newtonsoft.Json;
using System.Collections;
using System.Data;

namespace Hotel.Models.Common
{
    public class CommonFun
    {
        public static List<SelectListItem> BindDDL(DataTable dt)
        {
            List<SelectListItem> lst = new List<SelectListItem>();
            if (dt != null && dt.Rows.Count > 0)
            {
                lst.Add(new SelectListItem()
                {
                    Text = "--- Select ---",
                    Value = ""
                });
                foreach (DataRow item in dt.Rows)
                {
                    lst.Add(new SelectListItem()
                    {
                        Text = Convert.ToString(item[1]),
                        Value = Convert.ToString(item[0])
                    });
                }
            }
            else
            {
                lst.Add(new SelectListItem() { Text = "-- select --", Value = "" });
            }
            return lst;
        }
        //public static string ConvertTableToList(DataTable dt)
        //{
        //    if (dt != null && dt.Rows.Count > 0)
        //    {
        //        Hashtable[] pr = new Hashtable[dt.Rows.Count];

        //        for (int i = 0; i < dt.Rows.Count; i++)
        //        {
        //            Hashtable ch = new Hashtable();
        //            for (int j = 0; j < dt.Columns.Count; j++)
        //            {
        //                string columnName = Convert.ToString(dt.Columns[j]);
        //                string columnValue = Convert.ToString(dt.Rows[i][columnName]);
        //                ch.Add(columnName, columnValue);
        //            }
        //            pr[i] = ch;
        //        }
        //        return  JsonConverter.Serialize(pr);
        //    }
        //    return "False";
        //}


        public static async Task<FileUploaderRes> Upload(FileUploadReq fileUploadReq)
        {
            var response = new FileUploaderRes
            {
                StatusCode = -1,
                Msg = "An error has occurred. Please try again later."
            };

            if (string.IsNullOrEmpty(fileUploadReq.FilePath))
            {
                fileUploadReq.FilePath = "/uploadedbill/";
            }

            string fullFilePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", fileUploadReq.FilePath, fileUploadReq.FileName);

            try
            {
                string fileExt = Path.GetExtension(fileUploadReq.FileName);
                string[] validExt = { ".png", ".jpg", ".jpeg", ".pdf" };

                if (!validExt.Any(x => x.Equals(fileExt, StringComparison.OrdinalIgnoreCase)))
                {
                    response.Msg = "You can only upload .png, .jpg, .jpeg, .pdf files.";
                    return response;
                }

                using (var stream = new FileStream(fullFilePath, FileMode.Create))
                {
                    await fileUploadReq.File.CopyToAsync(stream);
                }

                response.StatusCode = 1;
                response.Msg = "File Uploaded Successfully.";
            }
            catch (Exception ex)
            {
                response.Msg = "An exception has occurred. Please try again later.";
            }

            return response;
        }
        public class FileUploaderRes
        {
            public int StatusCode { get; set; }
            public string Msg { get; set; }
        }

        public class FileUploadReq
        {
            public string FilePath { get; set; }
            public string FileName { get; set; }
            public IFormFile File { get; set; }
        }

    }
}
