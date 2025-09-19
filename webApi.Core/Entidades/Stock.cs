using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Stock
    {
        public int StocId { get; set; }
        public ProductBatches oBatch { get; set; }
        public int AvailableQuantity { get; set; }
    }
}
