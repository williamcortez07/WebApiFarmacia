using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class ProductBatches
    {
        public int BatchId { get; set; }
        public int BatchNumber { get; set; }
        public DateTime ManufacturingDate { get; set; }
        public DateTime ExpirationDate { get; set; }
        public int Quantity { get; set; }
        public Products oProduct { get; set; }
        public bool IsActive { get; set; }

    }
}
