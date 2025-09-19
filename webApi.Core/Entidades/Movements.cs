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
        public Products oProductId { get; set; }
        public string MovementType { get; set; }
        public int Quantity { get; set; }
        public users oUserId { get; set; }
        public ProductBatches oBatchId { get; set; }
        public string Remarks { get; set; }
    }
}
