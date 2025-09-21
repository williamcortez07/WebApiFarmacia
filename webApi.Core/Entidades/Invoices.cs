using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Invoices
    {
        public int InvoiceId { get; set; }
        public string ClientName { get; set; }
        public Users  oUser { get; set; }
        public string RegisteredDate { get; set; } // este valor es string y no date parque luego se hace una conversion, y en la pantalla aparece este valor asi que se tiene que mapear
        public decimal SubTotal { get; set; }
        public decimal Discount { get; set; }
        public decimal Total { get; set; }
    }
}
