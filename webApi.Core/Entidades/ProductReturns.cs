using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public  class ProductReturns
    {
        public int ReturnId { get; set; }
        public string ReturnType { get; set; }
        public string ReturnDescription { get; set; }
        public Invoices oInvoice { get; set; }
        public Products oProduct { get; set; }
        public string RegistteredDate { get; set; }
    }
}
