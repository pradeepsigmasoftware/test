using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace Hotel.Models
{
    public class DBHelper
    {
        private readonly IConfiguration _configuration;
        string consString = null;
        SqlConnection con = null;
        public DBHelper()
        {
            var configuation = GetConfiguration();
            con = new SqlConnection(configuation.GetSection("ConnectionStrings").GetSection("ConnectionStrings").Value);
            consString = configuation.GetSection("ConnectionStrings").GetSection("ConnectionStrings").Value;
        }
        public IConfigurationRoot GetConfiguration()
        {
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
            return builder.Build();
        }

        public int ExecuteNonQueryProc(string cmdText, SqlParameter[] prms)
        {
            int r = 0;
            try
            {
                using (SqlConnection conn = new SqlConnection(consString))
                {
                    using (SqlCommand cmd = new SqlCommand(cmdText, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Clear();
                        if (prms != null)
                        {
                            foreach (SqlParameter p in prms)
                            {
                                cmd.Parameters.Add(p);
                            }
                        }
                        conn.Open();
                        try
                        {
                            r = cmd.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            r = 0;
                        }
                        finally
                        {
                            conn.Close();
                        }
                    }
                }
            }
            catch (Exception ex)
            {

            }
            return r;
        }
        public DataTable ExecProcDataTable(string ProName, SqlParameter[] Param)
        {
            DataTable dt = new DataTable();
            try
            {
                SqlCommand cmd = new SqlCommand(ProName, con);
                cmd.CommandType = CommandType.StoredProcedure;
                if (Param != null)
                {
                    foreach (SqlParameter prm in Param)
                    {
                        cmd.Parameters.Add(prm);
                    }
                }
                SqlDataAdapter adp = new SqlDataAdapter(cmd);

                adp.Fill(dt);
            }
            catch (Exception ex)
            {
                throw ex;
            }
            return dt;
        }
        public DataSet ExecProcDataSet(string ProName, SqlParameter[] Param)
        {
            DataSet dt = new DataSet();
            try
            {
                con.Open();
                SqlCommand cmd = new SqlCommand(ProName, con);
                cmd.CommandType = CommandType.StoredProcedure;
                foreach (SqlParameter prm in Param)
                {
                    cmd.Parameters.Add(prm);
                }
                SqlDataAdapter adp = new SqlDataAdapter(cmd);
                adp.Fill(dt);
            }
            catch (Exception ex)
            {

            }
            finally
            {
                con.Close();
            }
            return dt;
        }
        public DataSet FetchDataSetProc(string qry, SqlParameter[] Para)
        {
            SqlConnection dbconn = new SqlConnection(consString);

            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmd = new SqlCommand(qry, dbconn);
                cmd.CommandTimeout = 0;
                cmd.CommandType = CommandType.StoredProcedure;
                for (int i = 0; i < Para.Length; i++)
                {
                    cmd.Parameters.Add(Para[i]);
                }
                SqlDataAdapter adap = new SqlDataAdapter(cmd);
                adap.Fill(ds);
            }
            catch (Exception ex)
            {
                string msg = "Some Fetching Error Occur";
                msg += ex.Message;
                throw new Exception(msg);
            }
            finally
            {
                dbconn.Close();
                dbconn.Dispose();
            }
            return ds;
        }

        public DataTable ExecAdaptorDataTable(string Query)
        {
            DataTable dt = new DataTable();
            try
            {
                SqlCommand cmd = new SqlCommand(Query, con);
                cmd.CommandType = CommandType.Text;
                SqlDataAdapter adp = new SqlDataAdapter(cmd);
                adp.Fill(dt);
            }
            catch (Exception ex)
            {

            }
            return dt;
        }


        public int ExecuteNonQuery(string Query)
        {
            int r = 0;
            try
            {
                using (SqlConnection conn = new SqlConnection(consString))
                {
                    using (SqlCommand cmd = new SqlCommand(Query, conn))
                    {
                        cmd.CommandType = CommandType.Text;
                        conn.Open();
                        try
                        {
                            r = cmd.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            r = 0;
                        }
                        finally
                        {
                            conn.Close();
                        }
                    }
                }
            }
            catch (Exception ex)
            {

            }
            return r;
        }




        public object ExecuteExecuteScalar(string Query)
        {
            object r = 0;
            try
            {
                using (SqlConnection conn = new SqlConnection(consString))
                {
                    using (SqlCommand cmd = new SqlCommand(Query, conn))
                    {
                        cmd.CommandType = CommandType.Text;
                        conn.Open();
                        try
                        {
                            r = cmd.ExecuteScalar();
                        }
                        catch (Exception ex)
                        {
                            r = 0;
                        }
                        finally
                        {
                            conn.Close();
                        }
                    }
                }
            }
            catch (Exception ex)
            {

            }
            return r;
        }


    }
}
