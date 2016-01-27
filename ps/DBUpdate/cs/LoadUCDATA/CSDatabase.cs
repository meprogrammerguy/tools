using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Data.OracleClient;
using Microsoft.Win32;

#pragma warning disable 0618 // Prevent Obsolete warnings for Oracle calls

namespace LoadUCDATA
{
    public class CSDatabase
    {
        public string dbUserName;
        public string dbType;
        private string dbPassword;
        private string dbServer;
        private string sqlDbName;
        public string sUserName = null;
        public string sPassword = null;
        public string sDBInstance = null;
        public string sFileLocation = null;
        public System.Data.OracleClient.OracleConnection oracleConnection;
        public System.Data.SqlClient.SqlConnection sqlConnection;

        public CSDatabase(string asnPath)
        {
            RegistryKey key = null;
            try
            {
                if (asnPath.Length <= 0) throw new Exception("ASN file not specified!");
                if (!File.Exists(asnPath)) throw new Exception("Cannot Find ASN file in " + asnPath);
                GetDatabaseInfo(asnPath);
                if (string.Compare(dbType, "ora", true) == 0)
                {
                    oracleConnection = new System.Data.OracleClient.OracleConnection("user id=" + dbUserName + ";data source=" + dbServer + ";password=" + dbPassword);
                }
                else
                {
                    key = Registry.LocalMachine.OpenSubKey("SOFTWARE\\ODBC\\ODBC.INI\\" + dbServer);
                    try
                    {
                        dbServer = key.GetValue("Server").ToString();
                    }
                    catch
                    {

                    }
                    sqlConnection = new System.Data.SqlClient.SqlConnection("data source=" + dbServer + ";Initial Catalog=" + sqlDbName + ";User ID=" + dbUserName + ";Password=" + dbPassword);
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message, ex.InnerException);
            }
        }

        public int UpdateUCfield(string FileLocation)
        {
            bool bFoundDB = false;

            sDBInstance = dbServer;
            sFileLocation = FileLocation;
            sPassword = dbPassword;
            sUserName = dbUserName;
            connectOracle(out bFoundDB);
            if (bFoundDB)
            {
                delFile(FileLocation);
                loadData(FileLocation);
                return 0;
            }
            return 0;

        }

        private void delFile(string FileLocation)
        {
            try
            {
                File.Delete(FileLocation);
            }
            catch { }
        }

        private void loadData(string FileLocation)
        {
            Int32 ucfieldCount = 0, uckeyCount = 0;
            if (!File.Exists(FileLocation))
            {
                // Create a file to write to.
                try
                {
                    using (StreamWriter sw = File.CreateText(FileLocation))
                    {
                        //Prepare connection to Oracle Database
                        System.Data.OracleClient.OracleConnection conn = new System.Data.OracleClient.OracleConnection();
                        conn.ConnectionString = "Data Source= " + sDBInstance.ToString() + ";User Id=" + sUserName.ToString() + ";Password= " + sPassword.ToString() + ";";

                        // Loop through data and copy line for ucfield insert.

                        try
                        {
                            conn.Open();
                        }
                        catch { }
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

                            System.Data.OracleClient.OracleCommand myucfieldCountCMD = new System.Data.OracleClient.OracleCommand(sqlucfieldCount, conn);
                            ucfieldCount = Convert.ToInt32(myucfieldCountCMD.ExecuteOracleScalar().ToString());

                            System.Data.OracleClient.OracleCommand myuckeyCountCMD = new System.Data.OracleClient.OracleCommand(sqluckeyCount, conn);
                            uckeyCount = Convert.ToInt32(myuckeyCountCMD.ExecuteOracleScalar().ToString());

                            // Initialize Progress Bar
                            // Loads the number of records to be processed to file
                            sw.WriteLine(ucfieldCount + uckeyCount);

                            string sqlData;
                            string sU_TLAB = "";
                            string sU_INTF;
                            string sU_FLAB;
                            string sU_VLAB;
                            string sU_FSEQ;
                            int iSeq = 0;
                            bool bFoundError = false;
                            OracleLob U_LobDescr;
                            string sUDescr;

                            // Execute UCFIELD Query 
                            System.Data.OracleClient.OracleCommand myucfieldQueryCMD = new System.Data.OracleClient.OracleCommand(sqlucfieldQuery, conn);
                            System.Data.OracleClient.OracleDataReader myucfieldReader = myucfieldQueryCMD.ExecuteReader();
                            // Load UCFIELD Data
                            do
                            {
                                while (myucfieldReader.Read())
                                {
                                    // To fix out of sequence issue, but hesitate to implement it.
                                    if (sU_TLAB != myucfieldReader.GetOracleString(4).ToString())
                                    { iSeq = 1; }
                                    else
                                    { iSeq++; }

                                    //Put in place to handle TSGR and TSHD change to fixed length fields
                                    sU_FLAB = myucfieldReader.GetOracleString(2).ToString();
                                    sU_TLAB = myucfieldReader.GetOracleString(4).ToString();
                                    sU_INTF = myucfieldReader.GetOracleString(12).ToString();
                                    sU_FSEQ = myucfieldReader.GetOracleNumber(5).ToString();
                                    sU_VLAB = myucfieldReader.GetOracleString(3).ToString();
                                    U_LobDescr = myucfieldReader.GetOracleLob(22);
                                    sUDescr = ExtractDataFromXML(U_LobDescr.Value.ToString(), "U_DESC", sU_TLAB, sU_FLAB);
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
                                            bFoundError = true;
                                        }
                                    }

                                    sqlData = "";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(2).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(3).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(4).ToString().Trim()) + ",";
                                    //sqlData = sqlData + iSeq.ToString() + ",";
                                    sqlData = sqlData + myucfieldReader.GetOracleNumber(5) + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(9).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(10).ToString()) + ",";
                                    //                              Commented out to handle TSGR and TSHD data massage
                                    //								sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(12).ToString())  + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(12).ToString().Trim()) + ",";
                                    //(sU_INTF)                                         + ",";		
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(14).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(myucfieldReader.GetOracleString(16).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(sUDescr);

                                    sw.WriteLine("INSERT INTO UCFIELD VALUES ({0})", sqlData);
                                    //							    ShowErrorMessage("INSERT INTO UCFIELD VALUES ({0})",sqlData);
                                }

                            } while (myucfieldReader.NextResult());

                            // Execute UCKEY Query
                            System.Data.OracleClient.OracleCommand myuckeyQueryCMD = new System.Data.OracleClient.OracleCommand(sqluckeyQuery, conn);
                            System.Data.OracleClient.OracleDataReader myuckeyReader = myuckeyQueryCMD.ExecuteReader();
                            // Loads UCKEY Data
                            do
                            {
                                while (myuckeyReader.Read())
                                {
                                    sqlData = "";
                                    sqlData = sqlData + singleQuote(myuckeyReader.GetOracleString(2).ToString().Trim()) + ",";
                                    sqlData = sqlData + singleQuote(myuckeyReader.GetOracleString(3).ToString().Trim()) + ",";
                                    sqlData = sqlData + myuckeyReader.GetOracleNumber(4) + ",";
                                    sqlData = sqlData + singleQuote(myuckeyReader.GetOracleString(5).ToString()) + ",";
                                    if ("CLOB" == myuckeyReader.GetDataTypeName(8).Trim())
                                    {
                                        //MessageBox.Show("u_doc is CLOB");
                                        sqlData = sqlData + singleQuote(ExtractDataFromXML(myuckeyReader.GetOracleLob(8).Value.ToString(), "U_FLABS", myuckeyReader.GetOracleString(3).ToString().Trim(), null));

                                    }
                                    else
                                    {
                                        sqlData = sqlData + singleQuote(ExtractDataFromXML(myuckeyReader.GetOracleString(8).ToString(), "U_FLABS", myuckeyReader.GetOracleString(3).ToString().Trim(), null));
                                    }
                                    sw.WriteLine("INSERT INTO UCKEY VALUES ({0})", sqlData);

                                    // Perform the increment on the ProgressBar.
                                }

                            } while (myuckeyReader.NextResult());

                            //sw.WriteLine("commit;");
                            sw.Flush();
                            conn.Close();
                        }


                    }
                }
                catch
                {
                    sFileLocation = "";
                    return;
                }
            }
        }

        private string ExtractDataFromXML(string input, string xmlTag, string tlab, string flab)
        {
            string output = String.Empty;
            string path = "/unimeta/" + xmlTag;
            string v_begin = "<" + xmlTag + ">";
            string v_end = "</" + xmlTag + ">";

            try
            {
                output = input.Substring(input.IndexOf(v_begin) + v_begin.Length, input.IndexOf(v_end) - input.IndexOf(v_begin) - v_begin.Length);
            }
            catch { }
            return output;

        }

        private string singleQuote(string quoteString)
        {

            if (quoteString != "Null")
            {
                quoteString = "'" + quoteString + "'";




            }
            return quoteString;
        }
        private int connectOracle(out bool bDidConnect)
        {
            System.Data.OracleClient.OracleConnection conn = new System.Data.OracleClient.OracleConnection();
            conn.ConnectionString = "Data Source= " + sDBInstance.ToString() + ";User Id=" + sUserName.ToString() + ";Password= " + sPassword.ToString() + ";";
            try
            {
                bDidConnect = true;
                conn.Open();
                return (0);
            }
            catch {
                bDidConnect = false;
                return (0);

            }
        }

        private void GetDatabaseInfo(string asnPath)
        {
            StreamReader streamReader = null;
            string line = null;
            string originalLine = null;
            string databaseIdentifier = null;
            string databaseUserName = null;
            string databaseType = null;
            string databasePassword = null;
            string databaseServer = null;
            string sqlDatabaseName = null;
            bool databaseIdentifierFound = false;
            try
            {
                streamReader = new StreamReader(asnPath);
                while ((line = streamReader.ReadLine()) != null)
                {
                    int i = line.ToLower().IndexOf("$idf");
                    if (i >= 0 && line.IndexOf(";") != 0) databaseIdentifier = line.Substring(i + 7);
                }
                if (databaseIdentifier == null) throw new Exception("$idf not found in ASN file " + asnPath);
                streamReader.Close();
                streamReader = new StreamReader(asnPath);
                while ((line = streamReader.ReadLine()) != null && !databaseIdentifierFound)
                {
                    int i = line.IndexOf(databaseIdentifier);
                    if (i == 0)
                    {
                        databaseIdentifierFound = true;
                        originalLine = line;
                        line = line.Substring(i);
                        i = line.IndexOf("=");
                        if (i < 0) throw new Exception("Cannot find equals sign in $def line of asn file\n" + originalLine + "\n" + asnPath);
                        line = line.Substring(i + 2);
                        i = line.IndexOf(":");
                        if (i < 0) throw new Exception("Cannot find colon in $def line of asn file\n" + originalLine + "\n" + asnPath);
                        databaseType = line.Substring(0, i);
                        if (databaseType.ToLower() == "ora")
                        {
                            line = line.Substring(i + 1);
                            i = line.IndexOf("|");
                            if (i < 0) throw new Exception("Cannot find first pipe character in $def line of asn file\n" + originalLine + "\n" + asnPath);
                            databaseServer = line.Substring(0, i);
                            line = line.Substring(i + 1);
                        }
                        else
                        {
                            line = line.Substring(i + 1);
                            i = line.IndexOf(":");
                            if (i < 0) throw new Exception("Cannot find second colon in $def line of asn file\n" + originalLine + "\n" + asnPath);
                            databaseServer = line.Substring(0, i);
                            line = line.Substring(i + 1);
                            i = line.IndexOf("|");
                            if (i < 0) throw new Exception("Cannot find first pipe character in $def line of asn file\n" + originalLine + "\n" + asnPath);
                            sqlDatabaseName = line.Substring(0, i);
                            line = line.Substring(i + 1);
                        }
                        i = line.IndexOf("|");
                        if (i < 0) throw new Exception("Cannot find second pipe character in $def line of asn file\n" + originalLine + "\n" + asnPath);
                        databaseUserName = line.Substring(0, i);
                        databasePassword = line.Substring(i + 1);
                    }
                }
                if (!databaseIdentifierFound) throw new Exception("Could not find database identifier in line");
                dbUserName = databaseUserName;
                dbPassword = databasePassword;
                dbServer = databaseServer;
                dbType = databaseType;
                sqlDbName = sqlDatabaseName;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message, ex.InnerException);
            }
            finally
            {
                if (streamReader != null) streamReader.Close();
            }
        }
    }
}

