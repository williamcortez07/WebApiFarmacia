using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Movements
    {
        public int MovementId { get; set; }
        public Products oProduct { get; set; }
        public string MovementType { get; set; }
        public int Quantity { get; set; }
        public Users oUser { get; set; }
        public ProductBatches oBatch { get; set; }
        public string Remarks { get; set; }
    }
}
