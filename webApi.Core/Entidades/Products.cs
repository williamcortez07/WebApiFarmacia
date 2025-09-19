using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Products
    {
        public int ProductId { get; set; }
        public string ProductTradeName { get; set; }
        public string ProductGenericName { get; set; }
        public Categories oCategoryId { get; set; }
        public decimal SalePrice { get; set; }
        public decimal PurchasePrice { get; set; } 
        public Presentations oPresentationId { get; set; }
        public Concentration oConcentrationId { get; set; }
        public Suppliers oSupplierId { get; set; }
        public Brands oBrandId { get; set; }
        public int CriticalStock { get; set; }
        public bool IsActive {  get; set; }  

    }
}
