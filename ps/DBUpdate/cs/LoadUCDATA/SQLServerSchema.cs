using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Threading;
using System.Xml;

namespace LoadUCDATA
{
    class SQLServerSchema
    {
        public string path;
        public string sUserName = null;
        public string sPassword = null;
        public string sDatabase = null;
        public string sDBInstance = null;
        public string sFileLocation = null;

        public int SilentGenerateSchema()
        {

            bool bFoundDB = false;
            int i = connectSql(out bFoundDB);
            if (i == -10)
            {
                return (-10);
            }
            if (bFoundDB)
            {
                loadPath();
                delFile();
                loadData();
            }
            return (0);
        }

        public void loadPath()
        {
            if (sFileLocation.ToString() != "")
            {
                path = @"" + sFileLocation.ToString();
            }
            else
            {
                path = @"C:\scripts\LOADUCDATA.SQL";
                sFileLocation = path;
            }

        }

        private string singleQuote(string quoteString)
        {

            if (quoteString != "Null")
            {
                quoteString = "'" + quoteString + "'";
            }
            return quoteString;
        }


        private string ExtractDataFromXML(string input, string xmlTag, string tlab, string flab)
        {
            string output = String.Empty;
            string v_begin = "<" + xmlTag + ">";
            string v_end = "</" + xmlTag + ">";

            try
            {   /*
                XmlTextReader xtr = new XmlTextReader(new StringReader(input));
                DataSet ds = new DataSet();
                DataTable dt = new DataTable();
                ds.ReadXml(xtr);
                dt = ds.Tables[0];
                output = dt.Rows[0][xmlTag].ToString(); 
                */
                output = input.Substring(input.IndexOf(v_begin) + v_begin.Length, input.IndexOf(v_end) - input.IndexOf(v_begin) - v_begin.Length);

            }
            catch (Exception ex)
            {
                //MessageBox.Show("Unable to Get U_Descr value on "+tlab+"."+flab+":" + ex.ToString());
                ShowErrorMessage("Unable to Get U_Descr value on " + tlab + "." + flab + ":" + ex.ToString());

            }
            return output;

        }

        private void ShowErrorMessage(string message)
        {
            ShowErrorMessage(message, string.Empty);
        }

        private void ShowErrorMessage(string message, string caption)
        {
            Console.WriteLine(caption + " " + message);
        }

        private void loadData()
        {
            StreamWriter sw;
            Int32 ucfieldCount = 0, uckeyCount = 0;
            if (!File.Exists(path))
            {
                // Create a file to write to.
                try
                {
                    sw = File.CreateText(path);
                }
                catch
                {
                    ShowErrorMessage("Failed to open file: " + path.ToString(), "ERROR!");
                    sFileLocation = "";
                    return;
                }

                ShowErrorMessage(string.Format("The file {0} was created!", path));

                //Prepare connection to Sql Database
                System.Data.SqlClient.SqlConnection conn = new System.Data.SqlClient.SqlConnection();
                conn.ConnectionString = "Data Source= " + sDBInstance.ToString() + ";User Id=" + sUserName.ToString() + ";Password= " + sPassword.ToString() + ";Database=" + sDatabase.ToString() + ";";


                // Loop through data and copy line for ucfield insert.

                try
                {
                    conn.Open();
                }
                catch (Exception ex)
                {
                    ShowErrorMessage(string.Format("The process failed: {0}", ex.ToString()));
                }
                finally
                {
                    //UCFIELD Queries




                    string model = "'CMDSERIES','PRINTER', 'CARTAGE_INVOICE'";
                    string sqlucfieldCount = "select count(f.u_flab) FROM ucfield f, uctable t WHERE f.u_vlab = t.u_vlab AND f.u_tlab = t.u_tlab and f.u_vlab in (" + model + ") and f.u_tlab not like 'X%' and f.u_indb = 'Y'";
                    string sqlucfieldQuery = "select            f.*  FROM ucfield f, uctable t WHERE f.u_vlab = t.u_vlab AND f.u_tlab = t.u_tlab and f.u_vlab in (" + model + ") and f.u_tlab not like 'X%' and f.u_indb = 'Y' order by f.u_vlab, f.u_tlab, f.u_fseq";

                    //UCKEY Queries
                    string sqluckeyCount = "select count(t.u_tlab) FROM uckey k, uctable t WHERE k.u_vlab = t.u_vlab AND k.u_tlab = t.u_tlab and k.u_vlab in (" + model + ") and k.u_tlab not like 'X%'";
                    string sqluckeyQuery = "select            k.*  FROM uckey k, uctable t WHERE k.u_vlab = t.u_vlab AND k.u_tlab = t.u_tlab and k.u_vlab in (" + model + ") and k.u_tlab not like 'X%' order by k.u_vlab, k.u_tlab, k.u_kseq";

                    string sTable = "";
                    int iSequence = 0;

                    System.Data.SqlClient.SqlCommand myucfieldCountCMD = new System.Data.SqlClient.SqlCommand(sqlucfieldCount, conn);
                    ucfieldCount = Convert.ToInt32(myucfieldCountCMD.ExecuteScalar().ToString());

                    System.Data.SqlClient.SqlCommand myuckeyCountCMD = new System.Data.SqlClient.SqlCommand(sqluckeyCount, conn);
                    uckeyCount = Convert.ToInt32(myuckeyCountCMD.ExecuteScalar().ToString());

                    // Loads the number of records to be processed to file
                    sw.WriteLine(ucfieldCount + uckeyCount);
                    ShowErrorMessage("number of records to be processed to file = " + (ucfieldCount + uckeyCount));

                    string sqlData;
                    string sU_TLAB = "";
                    string sU_INTF;
                    string sU_FLAB;
                    string sU_VLAB;
                    string sU_FSEQ;
                    int iSeq = 0;
                    bool bFoundError = false;
                    string U_LobDescr;
                    string sUDescr;

                    // Execute UCFIELD Query 
                    System.Data.SqlClient.SqlCommand myucfieldQueryCMD = new System.Data.SqlClient.SqlCommand(sqlucfieldQuery, conn);
                    System.Data.SqlClient.SqlDataReader myucfieldReader = myucfieldQueryCMD.ExecuteReader();
                    // Load UCFIELD Data
                    do
                    {
                        while (myucfieldReader.Read())
                        {
                            // To fix out of sequence issue, but hesitate to implement it.
                            if (sU_TLAB != myucfieldReader.GetSqlString(4).ToString())
                            { iSeq = 1; }
                            else
                            { iSeq++; }

                            //Put in place to handle TSGR and TSHD change to fixed length fields
                            sU_FLAB = myucfieldReader.GetSqlString(2).ToString();
                            sU_TLAB = myucfieldReader.GetSqlString(4).ToString();
                            sU_INTF = myucfieldReader.GetSqlString(12).ToString();
                            sU_FSEQ = myucfieldReader.GetSqlValue(5).ToString();
                            sU_VLAB = myucfieldReader.GetSqlString(3).ToString();
                            U_LobDescr = myucfieldReader.GetSqlString(22).ToString();
                            sUDescr = ExtractDataFromXML(U_LobDescr.ToString(), "U_DESC", sU_TLAB, sU_FLAB);
                            sUDescr = sUDescr.Replace("'", "''").Replace('\r', ' ').Replace("&", "and");


                            // Test for UCFIELD invalid sequence numbers
                            if (bFoundError == false)
                            {
                                iSequence++;
                                if (sTable != sU_TLAB)
                                {
                                    iSequence = 1;
                                    sTable = sU_TLAB;
                                }
                                if (iSequence > Int32.Parse(sU_FSEQ))
                                {
                                    ShowErrorMessage("ERROR! Table " + sTable + " is out of sequence!");
                                    bFoundError = true;
                                }
                            }

                            sqlData = "";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(2).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(3).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(4).ToString().Trim()) + ",";
                            //sqlData = sqlData + iSeq.ToString() + ",";
                            sqlData = sqlData + myucfieldReader.GetSqlValue(5) + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(9).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(10).ToString()) + ",";
                            //                              Commented out to handle TSGR and TSHD data massage
                            //								sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(12).ToString())  + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(12).ToString().Trim()) + ",";
                            //(sU_INTF)                                         + ",";		
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(14).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(myucfieldReader.GetSqlString(16).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(sUDescr);

                            sw.WriteLine("INSERT INTO UCFIELD VALUES ({0})", sqlData);
                            //							    ShowErrorMessage("INSERT INTO UCFIELD VALUES ({0})",sqlData);
                        }

                    } while (myucfieldReader.NextResult());
                    myucfieldReader.Close();
                    // Execute UCKEY Query
                    System.Data.SqlClient.SqlCommand myuckeyQueryCMD = new System.Data.SqlClient.SqlCommand(sqluckeyQuery, conn);
                    System.Data.SqlClient.SqlDataReader myuckeyReader = myuckeyQueryCMD.ExecuteReader();
                    // Loads UCKEY Data
                    do
                    {
                        while (myuckeyReader.Read())
                        {
                            sqlData = "";
                            sqlData = sqlData + singleQuote(myuckeyReader.GetSqlString(2).ToString().Trim()) + ",";
                            sqlData = sqlData + singleQuote(myuckeyReader.GetSqlString(3).ToString().Trim()) + ",";
                            sqlData = sqlData + myuckeyReader.GetSqlValue(4) + ",";
                            sqlData = sqlData + singleQuote(myuckeyReader.GetSqlString(5).ToString()) + ",";
                            if ("CLOB" == myuckeyReader.GetDataTypeName(8).Trim())
                            {
                                //MessageBox.Show("u_doc is CLOB");
                                sqlData = sqlData + singleQuote(ExtractDataFromXML(myuckeyReader.GetSqlBinary(8).Value.ToString(), "U_FLABS", myuckeyReader.GetSqlString(3).ToString().Trim(), null));

                            }
                            else
                            {
                                sqlData = sqlData + singleQuote(ExtractDataFromXML(myuckeyReader.GetSqlString(8).ToString(), "U_FLABS", myuckeyReader.GetSqlString(3).ToString().Trim(), null));
                            }
                            sw.WriteLine("INSERT INTO UCKEY VALUES ({0})", sqlData);

                        }

                    } while (myuckeyReader.NextResult());

                    //sw.WriteLine("commit;");
                    sw.Flush();
                    conn.Close();
                    if (bFoundError == true)
                    {
                        ShowErrorMessage("Conceptual Schema generated with ERRORS!");
                    }
                    else
                    {
                        ShowErrorMessage("Conceptual Schema successfully generated!");
                    }

                }


            }

        }

        private void delFile()
        {
            try
            {
                // Delete the newly created file.
                File.Delete(path);
                ShowErrorMessage(string.Format("{0} was successfully deleted.", path));
            }
            catch (Exception e)
            {
                ShowErrorMessage(string.Format("The process failed: {0}", e.ToString()));
            }


        }

        private int connectSql(out bool bDidConnect)
        {
            System.Data.SqlClient.SqlConnection conn = new System.Data.SqlClient.SqlConnection();
            conn.ConnectionString = "Data Source= " + sDBInstance.ToString() + ";User Id=" + sUserName.ToString() + ";Password= " + sPassword.ToString() + ";";
            try
            {
                bDidConnect = true;
                conn.Open();
                return (0);
            }
            catch (Exception ex)
            {
                ShowErrorMessage(string.Format("The process failed: {0}", ex.ToString()));
                ShowErrorMessage("Failed to connect to Data Source: " + sDBInstance.ToString(), "ERROR!");
                bDidConnect = false;
                return (-10);
            }

        }

        public string DateStringFormat(DateTime dt)
        {
            DateTimeFormatInfo dfi = new DateTimeFormatInfo();
            // Make up a new custom DateTime pattern, for demonstration.
            dfi.MonthDayPattern = "dd-MMM-yyyy";
            return dt.ToString("m", dfi);
        }

    }
}