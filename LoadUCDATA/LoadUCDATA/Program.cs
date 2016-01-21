using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LoadUCDATA
{
    class Program
    {
        private static CSDatabase _idfDatabase;
        static void Main(string[] args)
        {
            System.Console.WriteLine("Create LoadUCData tool");
            if (args.Length != 3)
            {
                System.Console.WriteLine("Usage:");
                System.Console.WriteLine("Arg#1 = DBType (always ora)");
                System.Console.WriteLine("Arg#2 = ASN filename");
                System.Console.WriteLine("Arg#3 = output filename");
                System.Console.WriteLine("Error: exiting");
                return;
            }
            for (int i = 0; i < args.Length; i++)
            {
                System.Console.WriteLine("Arg[{0}] = [{1}]", i, args[i]);
            }
            if (args[0] != "ora")
            {
                System.Console.WriteLine("Error: Tool only supports ora DBtype");
                return;
            }
            OpenIDFDatabase(args[1]);
            if (string.Compare(_idfDatabase.dbType, "ora", true) == 0)
            {
                _idfDatabase.UpdateUCfield(args[2]);
            }
            System.Console.WriteLine("loaducdata.sql has been created");
        }

        private static void OpenIDFDatabase(string asnFile)
        {
            try
            {
                _idfDatabase = new CSDatabase(asnFile);

                if (string.Compare(_idfDatabase.dbType, "ora", true) == 0)
                {
                    _idfDatabase.oracleConnection.Open();
                }
                else
                {
                    _idfDatabase.sqlConnection.Open();
                }
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("Error: " + ex.ToString());
            }
        }
    }
}
