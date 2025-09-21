using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class InvoicesDetails
    {
        public int InvoiceDetailId { get; set; }
        public int Quantity { get; set; }
        public Products oProduct { get; set; }
        public decimal TotalPrice   { get; set; }
        public Invoices oInvoice { get; set; }

    }
}
